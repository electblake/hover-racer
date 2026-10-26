extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	ProjectSettings.set_setting("application/config/name", "Hover Racer Tests/GaragePreview_%s" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(1280, 720)
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	var track = scene.get_node("TestTrack")
	track.show_garage()
	track.garage.set_process(false)
	for kit in range(3):
		track.garage.select_kit(kit)
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_webp("res://previews/garage-%s.webp" % track.garage.PodVisual.KITS[kit].to_lower())
	track.garage.select_part(0, 0)
	track.garage.select_part(2, 1)
	track.garage.select_part(1, 2)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_webp("res://previews/garage-mixed.webp")
	root.size = Vector2i(640, 480)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_webp("res://previews/garage-small.webp")
	scene.queue_free()
	await process_frame
	await process_frame
	quit()
