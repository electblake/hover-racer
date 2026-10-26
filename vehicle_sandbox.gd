extends Window

signal enabled_changed(enabled: bool)

const FIELDS := [
	["speed", "Speed", 0.0, 100.0, 1.0, ""],
	["afterburner", "Afterburner", 0.0, 100.0, 1.0, ""],
	["cornering", "Cornering", 0.0, 100.0, 1.0, ""],
	["maneuvering", "Airbraking", 0.0, 100.0, 1.0, ""],
	["ramjet", "Ramjet", 0.0, 100.0, 1.0, ""],
	["resilience", "Resilience", 0.0, 100.0, 1.0, ""],
	["battery", "Battery", 0.0, 100.0, 1.0, ""],
]
var vehicle: VehicleController
var enabled := true
var saved_rect: Rect2i
var sliders := {}
var spinboxes := {}

func _ready() -> void:
	title = "Vehicle ratings - live / unsaved"
	visible = false
	min_size = Vector2i(360, 180)
	size = Vector2i(400, 260)
	position = Vector2i(int(get_parent().get_viewport().get_visible_rect().size.x) - 408, 32)
	fit_to_game()
	saved_rect = Rect2i(position, size)
	get_parent().get_viewport().size_changed.connect(fit_to_game)
	close_requested.connect(func(): set_enabled(false))
	var compact_theme := Theme.new()
	compact_theme.default_font_size = 12
	compact_theme.set_font_size("title_font_size", "Window", 12)
	theme = compact_theme
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101820")
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var form := GridContainer.new()
	form.columns = 3
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("h_separation", 4)
	form.add_theme_constant_override("v_separation", 2)
	scroll.add_child(form)
	for field in FIELDS:
		var property: String = field[0]
		var label := Label.new()
		label.text = field[1]
		label.tooltip_text = property
		form.add_child(label)
		var slider := HSlider.new()
		slider.min_value = field[2]
		slider.max_value = field[3]
		slider.step = field[4]
		slider.allow_greater = false
		slider.value = vehicle.stats.get(property)
		slider.custom_minimum_size.x = 80
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.focus_mode = Control.FOCUS_NONE
		form.add_child(slider)
		var spin := SpinBox.new()
		spin.min_value = slider.min_value
		spin.max_value = slider.max_value
		spin.step = slider.step
		spin.allow_greater = slider.allow_greater
		spin.value = slider.value
		spin.suffix = field[5]
		spin.custom_minimum_size.x = 100
		form.add_child(spin)
		sliders[property] = slider
		spinboxes[property] = spin
		slider.value_changed.connect(func(value: float):
			spin.set_value_no_signal(value)
			vehicle.stats = vehicle.stats.duplicate()
			vehicle.stats.set(property, value)
		)
		spin.value_changed.connect(func(value: float):
			slider.set_value_no_signal(value)
			vehicle.stats = vehicle.stats.duplicate()
			vehicle.stats.set(property, value)
		)
		spin.get_line_edit().text_submitted.connect(func(_text: String): spin.get_line_edit().release_focus())

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled: hide()
	enabled_changed.emit(enabled)

func fit_to_game() -> void:
	var bounds := Vector2i(get_parent().get_viewport().get_visible_rect().size)
	size = size.min(bounds - Vector2i(16, 40))
	position = position.clamp(Vector2i(8,32), bounds - size - Vector2i(8,8))
