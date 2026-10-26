extends GutTest

const Envelope = preload("res://thrust_envelope.gd")
var envelope: RefCounted
const DT := 0.01

func before_each() -> void:
	envelope = Envelope.new()

func test_bounds_and_timing_at_multiple_rates() -> void:
	# Fresh instances exercise the public envelope at several simulation rates.
	for rate in [30, 60, 120]:
		var fresh = load("res://thrust_envelope.gd").new()
		var step: float = 1.0 / rate
		assert_true(fresh.advance(0, step, 0.12, 0.18, 0.92, 0.28) == 0, "Idle stays at zero at %d Hz" % rate)
		for frame in range(rate):
			var level: float = fresh.advance(1, step, 0.12, 0.18, 0.92, 0.28)
			assert_true(level >= 0 and level <= 1, "Envelope remains bounded at %d Hz" % rate)
		assert_true(is_equal_approx(fresh.level, 0.92), "Sustain is independent of step size")
		for frame in range(ceili(0.28 / step)):
			fresh.advance(0, step, 0.12, 0.18, 0.92, 0.28)
		assert_true(is_zero_approx(fresh.level), "Release completes at each simulation rate")
		fresh.advance(1, step, 0.12, 0.18, 0.92, 0.28)
		fresh.reset()
		assert_true(fresh.level == 0, "Reset clears active thrust")
		assert_true(fresh.advance(0, step, 0.12, 0.18, 0.92, 0.28) == 0, "Reset stays idle")

func test_attack_decay_release_and_retrigger() -> void:
	for i in range(12): envelope.advance(1.0, DT, 0.12, 0.18, 0.92, 0.28)
	assert_true(is_equal_approx(envelope.level, 1.0), "Attack reaches peak in 0.12s")
	for i in range(25): envelope.advance(1.0, DT, 0.12, 0.18, 0.92, 0.28)
	assert_true(is_equal_approx(envelope.level, 0.92), "Held gas settles to sustain")
	for i in range(14): envelope.advance(0.0, DT, 0.12, 0.18, 0.92, 0.28)
	assert_true(is_equal_approx(envelope.level, 0.46), "Release eases through half thrust")
	var before: float = envelope.level
	envelope.advance(1.0, DT, 0.12, 0.18, 0.92, 0.28)
	assert_true(envelope.level > before and envelope.level < 1, "Retrigger rises from current level")
	for i in range(30): envelope.advance(0.0, DT, 0.12, 0.18, 0.92, 0.28)
	assert_true(envelope.level == 0, "Release reaches exact zero")
	for i in range(100): envelope.advance(0.5, DT, 0.12, 0.18, 0.92, 0.28)
	assert_true(is_equal_approx(envelope.level, 0.46), "Analog gas scales sustain")

func test_sustain_endpoints_and_analog_changes() -> void:
	for sustain in [0.0, 1.0]:
		envelope.reset()
		for i in range(100): envelope.advance(1.0, DT, 0.12, 0.18, sustain, 0.28)
		assert_true(is_equal_approx(envelope.level, sustain), "Sustain endpoints")
		for i in range(100): envelope.advance(0.5, DT, 0.12, 0.18, sustain, 0.28)
		assert_true(is_equal_approx(envelope.level, sustain * 0.5), "Analog changes at endpoints")
