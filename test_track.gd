extends Node3D

var ship: CharacterBody3D
var readout: Label
var menu: PanelContainer
var game_layout: CenterContainer
var controls_layout: VBoxContainer
var new_race_button: Button
var resume_button: Button
var controls_button: Button
var diagnostics_button: Button
var diagnostics: VBoxContainer
var exit_button: Button
var back_button: Button
var race_started := false
var sandbox: Window
var sandbox_toggle: CheckButton
var thrust_hud: PanelContainer
var thrust_meter: Control
var thrust_label: Label
var controller_status := "Controller: not connected (keyboard ready)"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_controller_status()
	ship = get_parent().get_node("SHIP") as CharacterBody3D
	get_viewport().gui_embed_subwindows = true
	sandbox = preload("res://vehicle_sandbox.gd").new()
	sandbox.vehicle = ship
	add_child(sandbox)
	sandbox.window_input.connect(_on_sandbox_input)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.055, 0.09, 0.15)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.65, 0.78, 1.0)
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	add_child(environment)
	var overlay := CanvasLayer.new()
	add_child(overlay)
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
	diagnostics = preload("res://controller_diagnostics.gd").new()
	menu.add_child(diagnostics)
	diagnostics.back_requested.connect(show_game_menu)
	build_game_menu()
	set_menu_open(true)

func set_menu_open(open: bool) -> void:
	menu.visible = open
	sandbox.visible = sandbox.enabled and not open
	thrust_hud.visible = not open
	get_tree().paused = open
	if open:
		show_game_menu()
	else:
		race_started = true
		get_viewport().gui_release_focus()

func build_game_menu() -> void:
	game_layout = CenterContainer.new()
	menu.add_child(game_layout)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size.x = 320
	actions.add_theme_constant_override("separation", 14)
	game_layout.add_child(actions)
	var title := Label.new()
	title.text = "HOVER RACER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	actions.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "CANYON RUN"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("4cdbdb"))
	actions.add_child(subtitle)
	resume_button = Button.new()
	resume_button.text = "Resume Race"
	resume_button.custom_minimum_size.y = 52
	resume_button.pressed.connect(func(): set_menu_open(false))
	actions.add_child(resume_button)
	new_race_button = Button.new()
	new_race_button.text = "New Race"
	new_race_button.custom_minimum_size.y = 52
	new_race_button.pressed.connect(start_new_race)
	actions.add_child(new_race_button)
	controls_button = Button.new()
	controls_button.text = "Controls"
	controls_button.custom_minimum_size.y = 52
	controls_button.pressed.connect(show_controls)
	actions.add_child(controls_button)
	diagnostics_button = Button.new()
	diagnostics_button.text = "Controller Diagnostics"
	diagnostics_button.custom_minimum_size.y = 44
	diagnostics_button.pressed.connect(show_diagnostics)
	actions.add_child(diagnostics_button)
	exit_button = Button.new()
	exit_button.text = "Exit Game"
	exit_button.custom_minimum_size.y = 52
	exit_button.pressed.connect(func(): get_tree().quit())
	actions.add_child(exit_button)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.12, 0.5, 0.55, 0.25)
	focus_style.border_color = Color("4cdbdb")
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(6)
	for button in [resume_button, new_race_button, controls_button, diagnostics_button, exit_button, back_button]:
		button.add_theme_stylebox_override("focus", focus_style)
	var navigation := Label.new()
	navigation.text = "↑ / ↓ or D-pad: select · Enter / A: confirm"
	navigation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	navigation.add_theme_font_size_override("font_size", 14)
	actions.add_child(navigation)

func show_game_menu() -> void:
	diagnostics.hide()
	diagnostics.pending_action = ""
	controls_layout.hide()
	game_layout.show()
	resume_button.visible = race_started
	if race_started: resume_button.grab_focus()
	else: new_race_button.grab_focus()

func show_diagnostics() -> void:
	game_layout.hide()
	controls_layout.hide()
	diagnostics.show()
	diagnostics.back_button.grab_focus()

func show_controls() -> void:
	game_layout.hide()
	controls_layout.show()
	back_button.grab_focus()

func start_new_race() -> void:
	ship.position = Vector3(55, 2, 30)
	ship.rotation = Vector3.ZERO
	ship.velocity = Vector3.ZERO
	ship.reset_visuals()
	set_menu_open(false)

func _process(_delta: float) -> void:
	thrust_meter.level = ship.applied_thrust
	thrust_meter.queue_redraw()
	thrust_label.text = "THRUST                         %3d%%" % roundi(ship.applied_thrust * 100)
	readout.text = "KEYBOARD\nSpace: thrust · Shift: brake\nLeft/Right arrows: steer · Down: sharp turn · R: reset\nUp/W: push both sticks · S: sharp turn · A/D: left/right pull\nIndependent sticks: I/J/K/L (left), T/F/G/H (right) · Q/E: left/right pull\n\nCONTROLLER\nRT: gas · LT: brake · Both sticks: steer\nInside stick down: sharp turn · Y: reset\n\nHANDLING\nOff gas: glide and slow to a stop. Gas again: pull toward the nose.\n\nRACE STATUS\n%s\nGas: %03d%%  Brake: %03d%%  Speed: %02d m/s" % [controller_status, roundi(ship.throttle_input*100), roundi(ship.brake_input*100), roundi(Vector2(ship.velocity.x, ship.velocity.z).length())]

func _input(event: InputEvent) -> void:
	if diagnostics.is_visible_in_tree():
		diagnostics.handle_input(event)
		return
	if event.is_action_pressed("toggle_menu"):
		if menu.visible and controls_layout.visible:
			show_game_menu()
		elif not menu.visible:
			set_menu_open(true)
		elif race_started:
			set_menu_open(false)
		get_viewport().set_input_as_handled()
	elif menu.visible and event.is_action_pressed("ui_cancel"):
		if controls_layout.visible: show_game_menu()
		elif race_started: set_menu_open(false)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if menu.visible:
		return
	if event.is_action_pressed("reset_ship"):
		ship.position = Vector3(55, 2, 30)
		ship.rotation = Vector3.ZERO
		ship.velocity = Vector3.ZERO
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

func build_vehicle_overlay(overlay: CanvasLayer) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.075, 0.90)
	panel_style.set_content_margin_all(16)
	panel_style.set_corner_radius_all(8)
	thrust_hud = PanelContainer.new()
	thrust_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(thrust_hud)
	thrust_hud.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	thrust_hud.offset_left = -296
	thrust_hud.offset_top = -116
	thrust_hud.offset_right = -24
	thrust_hud.offset_bottom = -24
	thrust_hud.add_theme_stylebox_override("panel", panel_style)
	var meter_layout := VBoxContainer.new()
	meter_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_layout.add_theme_constant_override("separation", 8)
	thrust_hud.add_child(meter_layout)
	thrust_label = Label.new()
	thrust_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_layout.add_child(thrust_label)
	thrust_meter = preload("res://thrust_meter.gd").new()
	meter_layout.add_child(thrust_meter)

