extends GutTest
## Project fixture policy; test discovery, assertions and failures belong to GUT.

var viewport_size: Vector2i

func before_each() -> void:
	ProjectSettings.set_setting("application/config/name", "Hover Racer Tests/%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	Engine.physics_ticks_per_second = 60
	viewport_size = get_tree().root.size
	get_tree().paused = false

func after_each() -> void:
	get_tree().paused = false
	for action in InputMap.get_actions():
		Input.action_release(action)
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = axis
		event.axis_value = 0.0
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	get_tree().root.size = viewport_size
