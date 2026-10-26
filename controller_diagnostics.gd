extends VBoxContainer

signal back_requested

const SETTINGS_PATH := "user://controller_bindings.cfg"
const ACTIONS := [
	["thrust", "Thrust"], ["brake", "Brake"],
	["left_steer_left", "Left stick ←"], ["left_steer_right", "Left stick →"],
	["left_push_up", "Left stick ↑"], ["left_pull_down", "Left stick ↓ / sharp turn"],
	["right_steer_left", "Right stick ←"], ["right_steer_right", "Right stick →"],
	["right_push_up", "Right stick ↑"], ["right_pull_down", "Right stick ↓ / sharp turn"],
	["reset_ship", "Reset vehicle"], ["toggle_menu", "Game menu"],
]
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
		for action in config.get_section_keys("bindings"):
			apply_binding(action, config.get_value("bindings", action))
	var title := Label.new()
	title.text = "CONTROLLER DIAGNOSTICS"
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)
	var raw_scroll := ScrollContainer.new()
	raw_scroll.custom_minimum_size.y = 90
	raw_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(raw_scroll)
	raw_readout = Label.new()
	raw_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raw_readout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raw_scroll.add_child(raw_readout)
	instruction = Label.new()
	instruction.text = "Live vehicle controls • Select a binding to remap.\nController inputs stay in this overlay. Use mouse / keyboard to navigate; Esc to go back."
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
	for entry in ACTIONS:
		var action: String = entry[0]
		var row := VBoxContainer.new()
		rows.add_child(row)
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 34
		button.text = entry[1] + "  ·  " + binding_text(action)
		button.pressed.connect(func(): begin_binding(action))
		row.add_child(button)
		bindings[action] = button
		var meter := ProgressBar.new()
		meter.max_value = 1.0
		meter.custom_minimum_size.y = 18
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
	instruction.text = "Binding %s: release controls, then press a button or move an axis in the desired direction. Esc cancels." % action

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		if pending_action.is_empty(): back_requested.emit()
		else:
			pending_action = ""
			instruction.text = "Binding cancelled. Select any control to remap."
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion): return
	var binding := {}
	if event is InputEventJoypadButton:
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
		config.set_value("bindings", pending_action, binding)
		config.save(SETTINGS_PATH)
		for entry in ACTIONS:
			bindings[entry[0]].text = entry[1] + "  ·  " + binding_text(entry[0])
		instruction.text = "Saved %s → %s. Shared bindings are allowed; test the live meters below." % [pending_action, binding_text(pending_action)]
		pending_action = ""
	get_viewport().set_input_as_handled()

func apply_binding(action: String, binding: Dictionary) -> void:
	for old in InputMap.action_get_events(action):
		if old is InputEventJoypadButton or old is InputEventJoypadMotion:
			InputMap.action_erase_event(action, old)
	var event: InputEvent
	if binding.has("button"):
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
		if event is InputEventJoypadButton: descriptions.append("Button %d" % event.button_index)
		elif event is InputEventJoypadMotion: descriptions.append("Axis %d %s" % [event.axis, "+" if event.axis_value > 0 else "−"])
	return ", ".join(descriptions)
