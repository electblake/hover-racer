extends VBoxContainer

signal back_requested

const PodVisual = preload("res://pod_visual.gd")
const KIT_LABELS := ["Terra · Earth", "Magellan · Venus", "Juno · Jupiter"]
var ship: VehicleController
var selectors: Array[OptionButton] = []
var kit_buttons: Array[Button] = []
var back_button: Button
var preview: Node3D
var preview_container: SubViewportContainer
var preview_viewport: SubViewport
var build_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var heading := Label.new()
	heading.text = "VEHICLE GARAGE"
	heading.add_theme_font_size_override("font_size", 24)
	add_child(heading)
	var note := Label.new()
	note.text = "3 parts · 27 combinations · Cosmetic only"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	add_child(body)
	preview_container = SubViewportContainer.new()
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.custom_minimum_size = Vector2(120, 120)
	preview_container.stretch = true
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(preview_container)
	preview_viewport = SubViewport.new()
	preview_viewport.own_world_3d = true
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	preview_container.add_child(preview_viewport)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("101e2c")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("b7d7ef")
	world.environment.ambient_light_energy = 0.65
	preview_viewport.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.8
	preview_viewport.add_child(light)
	preview = PodVisual.new()
	preview_viewport.add_child(preview)
	var camera := Camera3D.new()
	camera.position = Vector3(5, 5, -7)
	preview_viewport.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.0
	camera.current = true
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 230
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 8)
	scroll.add_child(form)
	for slot in range(3):
		var label := Label.new()
		label.text = ["Nose", "Core", "Engine assembly (both engines)"][slot]
		form.add_child(label)
		var selector := OptionButton.new()
		selector.custom_minimum_size.y = 34
		for kit in KIT_LABELS: selector.add_item(kit)
		selector.item_selected.connect(select_part.bind(slot))
		form.add_child(selector)
		selectors.append(selector)
	var kits_label := Label.new()
	kits_label.text = "Complete kits"
	form.add_child(kits_label)
	for kit in range(3):
		var button := Button.new()
		button.text = KIT_LABELS[kit]
		button.custom_minimum_size.y = 32
		button.tooltip_text = ["Sleek wedge, compact canopy, slim turbines", "Armored prow, broad cabin, large engine pods", "Split fork, open frame, exposed cooling fins"][kit]
		button.pressed.connect(select_kit.bind(kit))
		form.add_child(button)
		kit_buttons.append(button)
	build_label = Label.new()
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(build_label)
	back_button = Button.new()
	back_button.text = "Back · changes applied"
	back_button.custom_minimum_size.y = 36
	back_button.pressed.connect(func(): back_requested.emit())
	add_child(back_button)
	hide()

func open() -> void:
	var parts: Array = ship.pod_visual.selections
	for slot in range(3): selectors[slot].select(parts[slot])
	update_preview()
	show()
	selectors[0].grab_focus()

func select_part(kit: int, slot: int) -> void:
	selectors[slot].select(kit)
	apply_parts()

func select_kit(kit: int) -> void:
	for selector in selectors: selector.select(kit)
	apply_parts()

func apply_parts() -> void:
	ship.pod_visual.set_parts(selectors[0].selected, selectors[1].selected, selectors[2].selected)
	update_preview()

func update_preview() -> void:
	preview.set_parts(selectors[0].selected, selectors[1].selected, selectors[2].selected)
	build_label.text = "%s nose / %s core / %s engines" % [PodVisual.KITS[selectors[0].selected], PodVisual.KITS[selectors[1].selected], PodVisual.KITS[selectors[2].selected]]

func _process(delta: float) -> void:
	if is_visible_in_tree():
		preview.rotate_y(delta * 0.22)
		preview.animate(0.0, 0.0, delta)
