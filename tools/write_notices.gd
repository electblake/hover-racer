extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	file.store_line("Hover Racer — third-party engine notices\n")
	file.store_line(Engine.get_license_text())
	for component in Engine.get_copyright_info():
		file.store_line("\n" + component.name)
		for part in component.parts:
			file.store_line("Files: " + ", ".join(part.files))
			file.store_line("\n".join(part.copyright))
			file.store_line("License: " + part.license)
	var licenses := Engine.get_license_info()
	for license_name in licenses:
		file.store_line("\n" + license_name + "\n" + licenses[license_name])
	file.close()
	quit()
