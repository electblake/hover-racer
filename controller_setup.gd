extends VBoxContainer

signal back_requested

const SETTINGS_PATH := "user://vehicle_controls_v2.cfg"
const ACTIONS := [
	["throttle", "Throttle"], ["brake", "Brake"],
	["steer_left", "Steer left"], ["steer_right", "Steer right"],
	["afterburner", "Afterburner"], ["ramjet", "Ramjet"],
	["maneuver", "Airbrake"], ["ability_primary", "Ability"],
	["reset_ship", "Respawn"], ["toggle_menu", "Game menu"],
]
const PRESETS := ["Xbox Wireless Controller", "SN30 Pro"]
const STANDARD_BINDINGS := {
	"throttle": {"axis": JOY_AXIS_TRIGGER_RIGHT, "direction": 1.0},
	"brake": {"axis": JOY_AXIS_TRIGGER_LEFT, "direction": 1.0},
	"steer_left": {"axis": JOY_AXIS_LEFT_X, "direction": -1.0},
	"steer_right": {"axis": JOY_AXIS_LEFT_X, "direction": 1.0},
	"afterburner": {"button": JOY_BUTTON_RIGHT_SHOULDER},
	"ramjet": {"button": JOY_BUTTON_LEFT_SHOULDER},
	"maneuver": {"button": JOY_BUTTON_A},
	"ability_primary": {"button": JOY_BUTTON_B},
	"reset_ship": {"button": JOY_BUTTON_Y},
	"toggle_menu": {"button": JOY_BUTTON_START},
}
var profile_picker: OptionButton
var load_button: Button
var save_button: Button
var save_dialog: ConfirmationDialog
var profile_name: LineEdit
var profile_hint: Label
var controller_diagram: Control
var active_profile := "Custom"
var controller_layout := "Xbox Wireless Controller"
var profiles := {}
var raw_readout: Label
var instruction: Label
var back_button: Button
var meters := {}
var bindings := {}
var pending_action := ""
var detected := {}
var axis_ready := {}
var config := ConfigFile.new()

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
		if config.has_section("bindings"):
			for action in config.get_section_keys("bindings"):
				apply_binding(action, config.get_value("bindings", action))
		if config.has_section("keyboard"):
			for action in config.get_section_keys("keyboard"):
				apply_binding(action, config.get_value("keyboard", action))
		if config.has_section("profiles"):
			for profile in config.get_section_keys("profiles"):
				profiles[profile] = config.get_value("profiles", profile)
		if config.has_section("active_profile"):
			active_profile = config.get_value("active_profile", "name")
			controller_layout = config.get_value("active_profile", "layout")
	var title := Label.new()
	title.text = "CONTROLLER SETUP"
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)
	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 8)
	add_child(profile_row)
	profile_picker = OptionButton.new()
	profile_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_picker.fit_to_longest_item = false
	profile_row.add_child(profile_picker)
	load_button = Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(func(): load_profile(profile_picker.get_item_text(profile_picker.selected)))
	profile_row.add_child(load_button)
	save_button = Button.new()
	save_button.text = "Save profile..."
	save_button.pressed.connect(prompt_save_profile)
	profile_row.add_child(save_button)
	profile_hint = Label.new()
	profile_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(profile_hint)
	save_dialog = ConfirmationDialog.new()
	save_dialog.title = "Save controller profile"
	save_dialog.min_size = Vector2i(360, 150)
	add_child(save_dialog)
	var save_layout := VBoxContainer.new()
	save_layout.add_theme_constant_override("separation", 12)
	save_dialog.add_child(save_layout)
	var name_hint := Label.new()
	name_hint.text = "Name this control set.\nExisting names replace that saved profile."
	save_layout.add_child(name_hint)
	profile_name = LineEdit.new()
	profile_name.placeholder_text = "Profile name"
	profile_name.max_length = 48
	save_layout.add_child(profile_name)
	profile_name.text_changed.connect(update_save_name)
	save_dialog.confirmed.connect(func(): save_profile(profile_name.text.strip_edges()))
	refresh_profiles()
	var raw_scroll := ScrollContainer.new()
	raw_scroll.custom_minimum_size.y = 60
	raw_scroll.visible = false
	raw_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var show_inputs := CheckButton.new()
	show_inputs.text = "Show raw controller inputs"
	show_inputs.toggled.connect(raw_scroll.set_visible)
	add_child(show_inputs)
	add_child(raw_scroll)
	raw_readout = Label.new()
	raw_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raw_readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raw_scroll.add_child(raw_readout)
	instruction = Label.new()
	instruction.text = "Select a control to remap; changes use Custom. Save a named profile to keep a copy.\nUse D-pad / mouse / keyboard here. B or Menu returns; Esc cancels a binding."
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(instruction)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 60
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	controller_diagram = preload("res://controller_diagram.gd").new()
	controller_diagram.setup = self
	rows.add_child(controller_diagram)
	for entry in ACTIONS:
		var action: String = entry[0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		rows.add_child(row)
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 34
		button.text = entry[1] + "  ·  " + binding_text(action)
		button.pressed.connect(func(): begin_binding(action))
		row.add_child(button)
		bindings[action] = button
		var meter := ProgressBar.new()
		meter.max_value = 1.0
		meter.custom_minimum_size = Vector2(90, 18)
		meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(meter)
		meters[action] = meter
	back_button = Button.new()
	back_button.text = "Back to game menu"
	back_button.custom_minimum_size.y = 40
	back_button.pressed.connect(func():
		pending_action = ""
		back_requested.emit()
	)
	add_child(back_button)

func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	var lines := PackedStringArray()
	for device in Input.get_connected_joypads():
		lines.append("Device %d: %s • mapped: %s" % [device, Input.get_joy_name(device), Input.is_joy_known(device)])
		var values := PackedStringArray()
		for axis in range(JOY_AXIS_MAX):
			values.append("Axis %d: %+.2f" % [axis, Input.get_joy_axis(device, axis)])
		for button in range(JOY_BUTTON_MAX):
			values.append("B%d: %d" % [button, int(Input.is_joy_button_pressed(device, button))])
		lines.append("  ".join(values))
	if lines.is_empty(): lines.append("No controller connected. Connect a controller to inspect its inputs.")
	for input_name in detected:
		lines.append("%s: %+.2f" % [input_name, detected[input_name]])
	raw_readout.text = "DETECTED INPUTS (axes −1…+1; buttons 0/1)\n" + "\n".join(lines)
	for action in meters:
		meters[action].value = Input.get_action_strength(action)

func begin_binding(action: String) -> void:
	pending_action = action
	axis_ready.clear()
	for device in Input.get_connected_joypads():
		for axis in range(JOY_AXIS_MAX):
			axis_ready["%d:%d" % [device, axis]] = absf(Input.get_joy_axis(device, axis)) < 0.25
	instruction.text = "Binding %s: release controls, then press a key, controller button or move an axis in the desired direction. Esc cancels." % action

func handle_input(event: InputEvent) -> void:
	if save_dialog.visible: return
	if pending_action.is_empty() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_menu")):
		back_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		if pending_action.is_empty(): back_requested.emit()
		else:
			pending_action = ""
			instruction.text = "Binding cancelled. Select any control to remap."
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion or (event is InputEventKey and not pending_action.is_empty())): return
	var binding := {}
	var capturing := not pending_action.is_empty()
	if event is InputEventKey:
		if event.pressed and not event.echo: binding = {"key": event.physical_keycode}
	elif event is InputEventJoypadButton:
		detected["Device %d · Button %d" % [event.device, event.button_index]] = float(event.pressed)
		if event.pressed: binding = {"button": event.button_index}
	else:
		detected["Device %d · Axis %d" % [event.device, event.axis]] = event.axis_value
		var axis_key := "%d:%d" % [event.device, event.axis]
		if absf(event.axis_value) < 0.25: axis_ready[axis_key] = true
		if axis_ready.has(axis_key) and axis_ready[axis_key] and absf(event.axis_value) > 0.65:
			binding = {"axis": event.axis, "direction": signf(event.axis_value)}
	if not pending_action.is_empty() and not binding.is_empty():
		apply_binding(pending_action, binding)
		config.set_value("keyboard" if binding.has("key") else "bindings", pending_action, binding)
		if not binding.has("key"):
			active_profile = "Custom"
		persist_active_profile()
		refresh_profiles()
		refresh_bindings()
		instruction.text = "Applied %s → %s. Save a profile to keep this control set." % [pending_action, binding_text(pending_action)]
		pending_action = ""
	if not capturing: return
	get_viewport().set_input_as_handled()

func apply_binding(action: String, binding: Dictionary) -> void:
	for old in InputMap.action_get_events(action):
		if (old is InputEventKey) if binding.has("key") else (old is InputEventJoypadButton or old is InputEventJoypadMotion):
			InputMap.action_erase_event(action, old)
	var event: InputEvent
	if binding.has("key"):
		event = InputEventKey.new()
		event.physical_keycode = binding.key
	elif binding.has("button"):
		event = InputEventJoypadButton.new()
		event.button_index = binding["button"]
	else:
		event = InputEventJoypadMotion.new()
		event.axis = binding["axis"]
		event.axis_value = binding["direction"]
	event.device = -1
	Input.action_release(action)
	InputMap.action_add_event(action, event)

func binding_text(action: String) -> String:
	var descriptions := PackedStringArray()
	for event in InputMap.action_get_events(action):
		if event is InputEventKey: descriptions.append(OS.get_keycode_string(event.physical_keycode))
		elif event is InputEventJoypadButton: descriptions.append(controller_button_text(event.button_index))
		elif event is InputEventJoypadMotion: descriptions.append(controller_axis_text(event.axis, event.axis_value))
	return ", ".join(descriptions)

func refresh_bindings() -> void:
	for entry in ACTIONS:
		bindings[entry[0]].text = entry[1] + "  ·  " + binding_text(entry[0])

func refresh_profiles() -> void:
	profile_picker.clear()
	for profile in PRESETS + ["Custom"] + profiles.keys():
		profile_picker.add_item(profile)
		if profile == active_profile: profile_picker.select(profile_picker.item_count - 1)
	profile_hint.text = "Active: %s" % active_profile
	if controller_layout == "SN30 Pro":
		profile_hint.text += " · Windows X-input (X + Start). Labels match the SN30 Pro face buttons."

func persist_active_profile() -> void:
	config.set_value("active_profile", "name", active_profile)
	config.set_value("active_profile", "layout", controller_layout)
	config.save(SETTINGS_PATH)

func load_profile(profile: String) -> void:
	pending_action = ""
	active_profile = profile
	if profile != "Custom":
		var controls: Dictionary
		if profile in PRESETS:
			controls = STANDARD_BINDINGS
			controller_layout = profile
		else:
			controls = profiles[profile].bindings
			controller_layout = profiles[profile].layout
		for action in controls:
			apply_binding(action, controls[action])
			config.set_value("bindings", action, controls[action])
	persist_active_profile()
	refresh_bindings()
	refresh_profiles()
	instruction.text = "Loaded %s. Select a control to customize; use the meters to test." % profile

func prompt_save_profile() -> void:
	pending_action = ""
	profile_name.text = active_profile if active_profile in profiles else ""
	update_save_name(profile_name.text)
	save_dialog.popup_centered()
	profile_name.grab_focus()

func update_save_name(value: String) -> void:
	var profile := value.strip_edges()
	save_dialog.get_ok_button().disabled = profile.is_empty() or profile in PRESETS or profile == "Custom"
	save_dialog.get_ok_button().text = "Replace profile" if profile in profiles else "Save profile"

func save_profile(profile: String) -> void:
	var controls := {}
	for entry in ACTIONS:
		for event in InputMap.action_get_events(entry[0]):
			if event is InputEventJoypadButton: controls[entry[0]] = {"button": event.button_index}
			elif event is InputEventJoypadMotion: controls[entry[0]] = {"axis": event.axis, "direction": event.axis_value}
	profiles[profile] = {"bindings": controls, "layout": controller_layout}
	config.set_value("profiles", profile, profiles[profile])
	active_profile = profile
	persist_active_profile()
	refresh_profiles()
	instruction.text = "Saved %s. Load it by name at any time." % profile

func controller_button_text(button: int) -> String:
	var names := {JOY_BUTTON_A: "A (south)", JOY_BUTTON_B: "B (east)", JOY_BUTTON_X: "X (west)", JOY_BUTTON_Y: "Y (north)", JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_START: "Start / Menu"}
	if controller_layout == "SN30 Pro":
		names.merge({JOY_BUTTON_A: "B (south)", JOY_BUTTON_B: "A (east)", JOY_BUTTON_X: "Y (west)", JOY_BUTTON_Y: "X (north)", JOY_BUTTON_LEFT_SHOULDER: "L", JOY_BUTTON_RIGHT_SHOULDER: "R"}, true)
	if names.has(button): return names[button]
	return "Button %d" % button

func controller_axis_text(axis: int, direction: float) -> String:
	if axis == JOY_AXIS_TRIGGER_RIGHT: return ("R2" if controller_layout == "SN30 Pro" else "RT") + (" (negative)" if direction < 0.0 else "")
	if axis == JOY_AXIS_TRIGGER_LEFT: return ("L2" if controller_layout == "SN30 Pro" else "LT") + (" (negative)" if direction < 0.0 else "")
	if axis == JOY_AXIS_LEFT_X: return "Left stick right" if direction > 0.0 else "Left stick left"
	return "Axis %d %s" % [axis, "+" if direction > 0 else "−"]
