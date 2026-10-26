extends Node3D

const MAPS = [preload("res://maps/map_1.tres"), preload("res://maps/map_2.tres"), preload("res://maps/map_3.tres"), preload("res://maps/map_4.tres"), preload("res://maps/physics_lab.tres")]
var selected_map := 0
var active_map := 0
var map_instance: Node3D
var environment: WorldEnvironment
var map_label: Label
var previous_map_button: Button
var next_map_button: Button
var map_preview: SubViewportContainer

var ship: VehicleController
var readout: Label
var menu: PanelContainer
var game_layout: CenterContainer
var controls_layout: VBoxContainer
var new_race_button: Button
var resume_button: Button
var controls_button: Button
var setup_button: Button
var garage_button: Button
var garage: VBoxContainer
var controller_setup: VBoxContainer
var exit_button: Button
var back_button: Button
var race_started := false
var sandbox: Window
var sandbox_toggle: CheckButton
var thrust_hud: PanelContainer
var speed_label: Label
var ability_status: Label
var warning_label: Label
var menu_hint: Label
var resource_bars := {}
var resource_values := {}
var vehicle_status: Label
var pulse_count := 0
var controller_status := "Controller: not connected (keyboard ready)"

func _ready() -> void:
	map_instance = load(MAPS[active_map].scene_path).instantiate()
	add_child(map_instance)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_controller_status()
	ship = get_parent().get_node("SHIP") as VehicleController
	ship.ability_activated.connect(func(): pulse_count += 1)
	get_viewport().gui_embed_subwindows = true
	sandbox = preload("res://vehicle_sandbox.gd").new()
	sandbox.vehicle = ship
	add_child(sandbox)
	sandbox.window_input.connect(_on_sandbox_input)
	environment = WorldEnvironment.new()
	environment.environment = MAPS[active_map].environment
	add_child(environment)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	map_preview = preload("res://menu_map_preview.gd").new()
	overlay.add_child(map_preview)
	build_vehicle_overlay(overlay)
	menu = PanelContainer.new()
	overlay.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.offset_left = 24
	menu.offset_top = 24
	menu.offset_right = -24
	menu.offset_bottom = -24
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.025, 0.045, 0.075, 0.96)
	background.set_content_margin_all(24)
	background.set_corner_radius_all(12)
	menu.add_theme_stylebox_override("panel", background)
	var layout := VBoxContainer.new()
	controls_layout = layout
	layout.add_theme_constant_override("separation", 16)
	menu.add_child(layout)
	var heading := Label.new()
	heading.text = "CONTROLS"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 24)
	layout.add_child(heading)
	var hint := Label.new()
	hint.text = "Esc / Controller B or Menu: back to game menu"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)
	sandbox_toggle = CheckButton.new()
	sandbox_toggle.text = "Show vehicle sandbox"
	sandbox_toggle.button_pressed = sandbox.enabled
	sandbox_toggle.toggled.connect(sandbox.set_enabled)
	sandbox.enabled_changed.connect(sandbox_toggle.set_pressed_no_signal)
	layout.add_child(sandbox_toggle)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 80)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	readout = Label.new()
	readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.add_theme_font_size_override("font_size", 18)
	scroll.add_child(readout)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size.y = 48
	back_button.pressed.connect(show_game_menu)
	layout.add_child(back_button)
	controller_setup = preload("res://controller_setup.gd").new()
	menu.add_child(controller_setup)
	controller_setup.back_requested.connect(show_game_menu)
	garage = preload("res://vehicle_garage.gd").new()
	garage.ship = ship
	menu.add_child(garage)
	garage.back_requested.connect(show_game_menu)
	build_game_menu()
	set_menu_open(true)

func set_menu_open(open: bool) -> void:
	ship.gate_input(not open)
	menu.visible = open
	sandbox.visible = sandbox.enabled and not open
	thrust_hud.visible = not open
	get_tree().paused = open
	if open:
		show_game_menu()
	else:
		map_preview.stop()
		race_started = true
		get_viewport().gui_release_focus()

func build_game_menu() -> void:
	game_layout = CenterContainer.new()
	game_layout.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	menu.add_child(game_layout)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 320
	actions.add_theme_constant_override("separation", 8)
	game_layout.add_child(actions)
	var title := Label.new()
	title.text = "HOVER RACER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	actions.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "MAP PREVIEW · AUTO CRUISE"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("4cdbdb"))
	actions.add_child(subtitle)
	var selector := HBoxContainer.new()
	selector.add_theme_constant_override("separation", 8)
	actions.add_child(selector)
	previous_map_button = Button.new()
	previous_map_button.text = "<"
	previous_map_button.custom_minimum_size = Vector2(38, 38)
	previous_map_button.pressed.connect(func(): select_map(-1))
	selector.add_child(previous_map_button)
	map_label = Label.new()
	map_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selector.add_child(map_label)
	next_map_button = Button.new()
	next_map_button.text = ">"
	next_map_button.custom_minimum_size = Vector2(38, 38)
	next_map_button.pressed.connect(func(): select_map(1))
	selector.add_child(next_map_button)
	select_map(0)
	resume_button = Button.new()
	resume_button.text = "Resume Race"
	resume_button.custom_minimum_size.y = 38
	resume_button.pressed.connect(func(): set_menu_open(false))
	actions.add_child(resume_button)
	new_race_button = Button.new()
	new_race_button.text = "New Race"
	new_race_button.custom_minimum_size.y = 38
	new_race_button.pressed.connect(start_new_race)
	actions.add_child(new_race_button)
	controls_button = Button.new()
	controls_button.text = "Controls"
	controls_button.custom_minimum_size.y = 38
	controls_button.pressed.connect(show_controls)
	actions.add_child(controls_button)
	setup_button = Button.new()
	setup_button.text = "Controller Setup"
	setup_button.custom_minimum_size.y = 44
	setup_button.pressed.connect(show_controller_setup)
	var customization := HBoxContainer.new()
	actions.add_child(customization)
	setup_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	customization.add_child(setup_button)
	garage_button = Button.new()
	garage_button.text = "Vehicle Garage"
	garage_button.custom_minimum_size.y = 38
	garage_button.pressed.connect(show_garage)
	garage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	customization.add_child(garage_button)
	exit_button = Button.new()
	exit_button.text = "Exit Game"
	exit_button.custom_minimum_size.y = 38
	exit_button.pressed.connect(func(): get_tree().quit())
	actions.add_child(exit_button)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.12, 0.5, 0.55, 0.25)
	focus_style.border_color = Color("4cdbdb")
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(6)
	for button in [previous_map_button, next_map_button, resume_button, new_race_button, controls_button, setup_button, garage_button, exit_button, back_button]:
		button.add_theme_stylebox_override("focus", focus_style)
	var navigation := Label.new()
	navigation.text = "↑ / ↓: select · ← / →: map · Enter / A: confirm"
	navigation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	navigation.add_theme_font_size_override("font_size", 14)
	actions.add_child(navigation)

func show_game_menu() -> void:
	garage.hide()
	controller_setup.save_dialog.hide()
	controller_setup.hide()
	controller_setup.pending_action = ""
	controls_layout.hide()
	game_layout.show()
	menu.get_theme_stylebox("panel").bg_color.a = 0.22
	refresh_map_preview.call_deferred()
	resume_button.visible = race_started
	if race_started: resume_button.grab_focus()
	else: new_race_button.grab_focus()

func show_controller_setup() -> void:
	map_preview.stop()
	menu.get_theme_stylebox("panel").bg_color.a = 0.96
	game_layout.hide()
	controls_layout.hide()
	controller_setup.show()
	controller_setup.back_button.grab_focus()

func show_controls() -> void:
	map_preview.stop()
	menu.get_theme_stylebox("panel").bg_color.a = 0.96
	game_layout.hide()
	controls_layout.show()
	back_button.grab_focus()

func show_garage() -> void:
	map_preview.stop()
	menu.get_theme_stylebox("panel").bg_color.a = 0.96
	game_layout.hide()
	controls_layout.hide()
	controller_setup.hide()
	garage.open()

func select_map(direction: int) -> void:
	selected_map = wrapi(selected_map + direction, 0, MAPS.size())
	map_label.text = "Map %d — %s" % [selected_map + 1, MAPS[selected_map].title]
	refresh_map_preview.call_deferred()

func refresh_map_preview() -> void:
	if menu.visible and game_layout.visible:
		map_preview.show_map(selected_map, MAPS[selected_map], ship.pod_visual.selections)

func start_new_race() -> void:
	if active_map != selected_map:
		remove_child(map_instance)
		map_instance.queue_free()
		active_map = selected_map
		environment.environment = MAPS[active_map].environment
		map_instance = load(MAPS[active_map].scene_path).instantiate()
		add_child(map_instance)
	ship.respawn(MAPS[active_map].spawn)
	ship.reset_visuals()
	pulse_count = 0
	set_menu_open(false)

func _process(_delta: float) -> void:
	if ship.position.y < -30.0 and not ship.is_crashed: ship.crash("fell off course")
	var editing := sandbox.visible and (sandbox.gui_get_focus_owner() is LineEdit or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	var enabled := not menu.visible and not editing
	if enabled != ship.gameplay_enabled: ship.gate_input(enabled)
	update_vehicle_overlay()
	var control_lines := PackedStringArray()
	for entry in controller_setup.ACTIONS:
		control_lines.append("%s: %s" % [entry[1], controller_setup.binding_text(entry[0])])
	readout.text = "CURRENT BINDINGS\n" + "\n".join(control_lines) + "\n\nBraking cancels propulsion and special movement. Ramjet takes priority over Afterburner. Airbrake tightens turns and costs speed; recovery blocks boosts. Release special buttons after menus or focus changes.\n\nChange controls and save named profiles in Controller Setup.\n\n" + controller_status

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(menu):
		set_menu_open(true)

func _input(event: InputEvent) -> void:
	if controller_setup.is_visible_in_tree():
		controller_setup.handle_input(event)
		return
	if menu.visible and game_layout.visible and not (setup_button.has_focus() or garage_button.has_focus()) and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")):
		select_map(-1 if event.is_action_pressed("ui_left") else 1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_menu"):
		if menu.visible and (controls_layout.visible or garage.visible):
			show_game_menu()
		elif not menu.visible:
			set_menu_open(true)
		elif race_started:
			set_menu_open(false)
		get_viewport().set_input_as_handled()
	elif menu.visible and event.is_action_pressed("ui_cancel"):
		if controls_layout.visible or garage.visible: show_game_menu()
		elif race_started: set_menu_open(false)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if menu.visible:
		return
	if event.is_action_pressed("reset_ship"):
		ship.respawn(MAPS[active_map].spawn)
		ship.reset_visuals()
		get_viewport().set_input_as_handled()

func _on_sandbox_input(event: InputEvent) -> void:
	_input(event)
	if not sandbox.gui_get_focus_owner() is LineEdit:
		_unhandled_input(event)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_controller_status()

func _update_controller_status() -> void:
	var devices := Input.get_connected_joypads()
	if devices.is_empty():
		controller_status = "Controller: not connected (keyboard ready)"
	else:
		controller_status = "Controller: %s" % Input.get_joy_name(devices[0])

func update_vehicle_overlay() -> void:
	var data := ship.telemetry()
	speed_label.text = "%03d km/h" % roundi(data.speed * 3.6)
	vehicle_status.text = "CRUISE" if data.grounded else "AIRBORNE"
	if data.boost != "none": vehicle_status.text = data.boost.to_upper()
	if data.maneuver_active:
		vehicle_status.text = "AIRBRAKE" if ship.maneuver_module.engaged else "AIRBRAKE RECOVERY"
	if ship.brake_input > 0.0: vehicle_status.text = "BRAKING"
	if data.crashed: vehicle_status.text = "STOPPED"
	resource_bars.fuel.max_value = ship.tuning.fuel_capacity
	resource_bars.energy.max_value = data.capacity
	for resource in ["fuel", "heat", "energy", "health"]:
		var value: float = data[resource] * 100.0 if resource == "heat" else data[resource]
		resource_bars[resource].value = value
		resource_values[resource].text = "%d%%" % roundi(value / resource_bars[resource].max_value * 100.0)
	resource_values.heat.modulate = Color("ff7766") if data.heat >= ship.tuning.heat_warning else Color.WHITE
	ability_status.text = "PULSE / READY [%s]" % controller_setup.binding_text("ability_primary")
	if data.cooldown > 0.0: ability_status.text = "PULSE  /  %.1fs" % data.cooldown
	elif data.energy < ship.ability.energy_cost: ability_status.text = "PULSE  /  LOW BATTERY"
	if data.impairment_time > 0.0 or data.crashed: ability_status.text = "PULSE  /  DISABLED"
	warning_label.text = ""
	if ship.depletion_latch: warning_label.text = "Release Afterburner to rearm"
	elif data.fuel < ship.tuning.fuel_reserve: warning_label.text = "Afterburner refueling"
	if data.health <= 25.0: warning_label.text = "LOW HULL"
	if data.impairment_time > 0.0: warning_label.text = "IMPAIRED  /  %.1fs" % data.impairment_time
	if data.heat >= ship.tuning.heat_warning: warning_label.text = "OVERHEATING / Release Ramjet"
	if data.crashed: warning_label.text = "CRASH: %s\n%s to respawn" % [data.crash_reason.to_upper(), controller_setup.binding_text("reset_ship")]
	warning_label.visible = not warning_label.text.is_empty()
	menu_hint.text = "%s / Pause" % controller_setup.binding_text("toggle_menu")

func build_vehicle_overlay(overlay: CanvasLayer) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.075, 0.90)
	panel_style.set_content_margin_all(16)
	panel_style.set_corner_radius_all(8)
	thrust_hud = PanelContainer.new()
	thrust_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(thrust_hud)
	thrust_hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	thrust_hud.offset_left = -344
	thrust_hud.offset_top = -320
	thrust_hud.offset_right = -24
	thrust_hud.offset_bottom = -24
	thrust_hud.add_theme_stylebox_override("panel", panel_style)
	var layout := VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 8)
	thrust_hud.add_child(layout)
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 40)
	layout.add_child(speed_label)
	vehicle_status = Label.new()
	vehicle_status.add_theme_color_override("font_color", Color("4cdbdb"))
	layout.add_child(vehicle_status)
	var names := {"fuel": "FUEL", "heat": "HEAT", "energy": "BATTERY", "health": "HULL"}
	var colors := {"fuel": Color("4cdbdb"), "heat": Color("ff9860"), "energy": Color("9eacff"), "health": Color("70dda0")}
	for resource in names:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 10)
		layout.add_child(row)
		var label := Label.new()
		label.text = names[resource]
		label.custom_minimum_size.x = 70
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.custom_minimum_size.y = 8
		var background := StyleBoxFlat.new()
		background.bg_color = Color("293744")
		background.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", background)
		var fill := StyleBoxFlat.new()
		fill.bg_color = colors[resource]
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)
		resource_bars[resource] = bar
		var value := Label.new()
		value.custom_minimum_size.x = 44
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_font_size_override("font_size", 13)
		row.add_child(value)
		resource_values[resource] = value
	ability_status = Label.new()
	ability_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_status.add_theme_font_size_override("font_size", 14)
	layout.add_child(ability_status)
	warning_label = Label.new()
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.add_theme_font_size_override("font_size", 14)
	warning_label.add_theme_color_override("font_color", Color("ff7766"))
	layout.add_child(warning_label)
	menu_hint = Label.new()
	menu_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_hint.add_theme_font_size_override("font_size", 12)
	menu_hint.modulate = Color("a5b7c9")
	layout.add_child(menu_hint)
