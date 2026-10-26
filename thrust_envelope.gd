extends RefCounted

enum Stage { IDLE, ATTACK, DECAY, SUSTAIN, RELEASE }
var stage := Stage.IDLE
var level := 0.0
var release_start := 0.0
var release_time := 0.0

func reset() -> void:
	stage = Stage.IDLE
	level = 0.0
	release_time = 0.0

func advance(demand: float, delta: float, attack: float, decay: float, sustain: float, release: float) -> float:
	if demand > 0.0 and stage in [Stage.IDLE, Stage.RELEASE]:
		stage = Stage.ATTACK
	elif demand == 0.0 and stage in [Stage.ATTACK, Stage.DECAY, Stage.SUSTAIN]:
		stage = Stage.RELEASE
		release_start = level
		release_time = 0.0
	match stage:
		Stage.ATTACK:
			level = move_toward(level, demand, delta * demand / attack)
			if level == demand: stage = Stage.DECAY
		Stage.DECAY:
			if sustain == 1.0: stage = Stage.SUSTAIN
			level = move_toward(level, demand * sustain, delta * demand / decay * (1.0 - sustain))
			if level == demand * sustain: stage = Stage.SUSTAIN
		Stage.SUSTAIN:
			var target := demand * sustain
			level = move_toward(level, target, delta / (attack if target > level else release))
		Stage.RELEASE:
			release_time += delta
			level = release_start * (1.0 - smoothstep(0.0, release, release_time))
			if release_time >= release: stage = Stage.IDLE
	return level
