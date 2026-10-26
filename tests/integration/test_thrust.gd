extends "res://tests/support/game_test.gd"
var scene: Node3D
var track
var ship

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	track = scene.get_node("TestTrack")
	ship = scene.get_node("SHIP")

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func test_sandbox_seven_ratings_preserves_preset_and_resources() -> void:
	var preset: VehicleStats = ship.stats
	ship.energy = 130.0
	ship.fuel = 45.0
	ship.health = 70.0
	assert_eq(track.sandbox.sliders.size(), 7)
	track.sandbox.sliders.speed.value = 80.0
	track.sandbox.spinboxes.battery.value = 100.0
	assert_eq(ship.stats.speed, 80.0)
	assert_eq(preset.speed, 50.0)
	assert_eq(track.sandbox.spinboxes.speed.value, 80.0)
	track.start_new_race()
	ship.energy = 130.0
	ship.fuel = 45.0
	ship.health = 70.0
	for frame in range(2): await get_tree().physics_frame
	assert_eq(ship.energy, 130.0)
	assert_eq(ship.fuel, 45.0)
	assert_eq(ship.health, 70.0)
	assert_eq(ship.derived.energy_capacity, 300.0)

func test_hud_and_sandbox_fit_viewports() -> void:
	track.set_menu_open(false)
	for viewport in [Vector2i(640,480), Vector2i(1280,720), Vector2i(1920,1080)]:
		get_tree().root.size = viewport
		await get_tree().process_frame
		await get_tree().process_frame
		assert_true(get_tree().root.get_visible_rect().encloses(track.thrust_hud.get_global_rect()))
		assert_eq(track.resource_bars.size(), 4)
		assert_true(track.thrust_hud.get_global_rect().encloses(track.ability_status.get_global_rect()))
		assert_true(track.speed_label.text.ends_with("km/h"))
		assert_lte(track.sandbox.size.x, viewport.x)
		assert_lte(track.sandbox.size.y, viewport.y)
	track.sandbox.close_requested.emit()
	assert_false(track.sandbox.visible or track.sandbox_toggle.button_pressed)

func test_hud_resources_warnings_and_respawn() -> void:
	ship.actual_speed = 50.0
	ship.fuel = 25.0
	ship.energy = 100.0
	ship.heat = 0.85
	ship.tuning = ship.tuning.duplicate()
	ship.tuning.heat_warning = 0.9
	track.update_vehicle_overlay()
	assert_eq(track.speed_label.text, "180 km/h")
	assert_eq(track.resource_values.fuel.text, "25%")
	assert_eq(track.resource_values.energy.text, "50%")
	assert_false(track.warning_label.visible, "Warning follows configured heat threshold")
	ship.heat = 0.95
	track.update_vehicle_overlay()
	assert_true(track.warning_label.text.contains("Release Ramjet"))
	ship.ability_cooldown = 1.5
	track.update_vehicle_overlay()
	assert_eq(track.ability_status.text, "PULSE  /  1.5s")
	ship.crash("overheat")
	track.update_vehicle_overlay()
	assert_true(track.warning_label.text.contains("Y (north)"))
	assert_true(track.warning_label.text.contains("R"))
	assert_true(track.warning_label.text.contains("to respawn"))
	assert_eq(track.ability_status.text, "PULSE  /  DISABLED")
	track.start_new_race()
	track.update_vehicle_overlay()
	assert_false(track.warning_label.visible)
	assert_eq(track.resource_values.health.text, "100%")
	assert_eq(track.ability_status.text, "PULSE / READY [E, B (east)]")
	track.set_menu_open(true)
	assert_false(track.thrust_hud.visible)
