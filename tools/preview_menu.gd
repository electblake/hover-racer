extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 720)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	var controller = scene.get_node("TestTrack")
	for index in [0, 2, 3]:
		controller.select_map(index - controller.selected_map)
		for i in range(90): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://previews/menu-map-%d.png" % (index + 1))
	scene.queue_free()
	await process_frame
	await process_frame
	quit()
