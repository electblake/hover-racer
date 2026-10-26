# Render actual track and storm approach for visual verification.
extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	var controller = scene.get_node("TestTrack")
	controller.select_map(3)
	controller.sandbox.enabled = false
	controller.start_new_race()
	var ship = scene.get_node("SHIP")
	ship.player_controlled = false
	for i in range(20): await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/jupiter-racing.png")
	var angle := -1.25
	ship.respawn(Transform3D(Basis(Vector3.UP, -angle), Vector3(cos(angle) * 360, 0.8, sin(angle) * 360)))
	for i in range(60): await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/jupiter-red-spot.png")
	scene.queue_free()
	await process_frame
	await process_frame
	quit()
