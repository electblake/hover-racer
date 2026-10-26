# Render the actual Venus scene and menu for visual verification.
extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	var controller = scene.get_node("TestTrack")
	controller.select_map(2)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/venus-menu.png")
	controller.sandbox.enabled = false
	controller.start_new_race()
	var ship = scene.get_node("SHIP")
	ship.player_controlled = false
	ship.command.throttle = 1.0
	for i in range(90): await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/venus-racing.png")
	scene.queue_free()
	await process_frame
	await process_frame
	quit()
