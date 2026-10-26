extends Control
## Vector front views; positions refer to the physical controls, not face-button names.
var setup: VBoxContainer

const OUTLINE := Color("839bad")
const INK := Color("dce9f2")
const ACCENT := Color("4cdbdb")

func _ready() -> void:
	custom_minimum_size.y = 230
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if is_visible_in_tree(): queue_redraw()

func _draw() -> void:
	var scale_factor := minf(size.x / 600.0, size.y / 230.0)
	draw_set_transform(Vector2((size.x - 600.0 * scale_factor) / 2.0, 0), 0, Vector2.ONE * scale_factor)
	var sn30: bool = setup.controller_layout == "SN30 Pro"
	var body: PackedVector2Array
	if sn30:
		# Rounded SNES body, with two lower, symmetric analog sticks.
		body = PackedVector2Array([Vector2(180,58), Vector2(420,58), Vector2(449,68), Vector2(467,90), Vector2(474,117), Vector2(467,146), Vector2(447,180), Vector2(420,190), Vector2(180,190), Vector2(153,180), Vector2(133,146), Vector2(126,117), Vector2(133,90), Vector2(151,68), Vector2(180,58)])
	else:
		# Xbox shoulders and tapered hand grips; left stick sits above the D-pad.
		body = PackedVector2Array([Vector2(181,58), Vector2(419,58), Vector2(445,75), Vector2(465,113), Vector2(485,180), Vector2(480,202), Vector2(461,211), Vector2(443,204), Vector2(404,180), Vector2(370,181), Vector2(230,181), Vector2(196,180), Vector2(157,204), Vector2(139,211), Vector2(120,202), Vector2(115,180), Vector2(135,113), Vector2(155,75), Vector2(181,58)])
	draw_colored_polygon(body, Color("101c28"))
	draw_polyline(body, OUTLINE, 2.0, true)
	text_at(Vector2(222,20), "SN30 PRO" if sn30 else "XBOX WIRELESS", 17)
	# Shoulders and triggers are drawn above the front shell.
	control_box(Rect2(156,29,57,23), "L2" if sn30 else "LT", JOY_AXIS_TRIGGER_LEFT, true)
	control_box(Rect2(387,29,57,23), "R2" if sn30 else "RT", JOY_AXIS_TRIGGER_RIGHT, true)
	control_box(Rect2(156,57,57,20), "L" if sn30 else "LB", JOY_BUTTON_LEFT_SHOULDER, false)
	control_box(Rect2(387,57,57,20), "R" if sn30 else "RB", JOY_BUTTON_RIGHT_SHOULDER, false)
	stick(Vector2(247,160) if sn30 else Vector2(185,105), "LS", JOY_AXIS_LEFT_X)
	stick(Vector2(353,160) if sn30 else Vector2(350,152), "RS", JOY_AXIS_RIGHT_X)
	var pad := Vector2(182,118) if sn30 else Vector2(245,149)
	var cross := PackedVector2Array([Vector2(-7,-20),Vector2(7,-20),Vector2(7,-7),Vector2(20,-7),Vector2(20,7),Vector2(7,7),Vector2(7,20),Vector2(-7,20),Vector2(-7,7),Vector2(-20,7),Vector2(-20,-7),Vector2(-7,-7),Vector2(-7,-20)])
	for i in range(cross.size()): cross[i] += pad
	draw_polyline(cross, OUTLINE, 1.5, true)
	text_at(pad + Vector2(-19,35), "D-pad", 12)
	control_box(Rect2(267,92,27,16), "−", JOY_BUTTON_BACK, false)
	control_box(Rect2(307,92,27,16), "+", JOY_BUTTON_START, false)
	text_at(Vector2(263,123), "Select" if sn30 else "View", 10)
	text_at(Vector2(305,123), "Start" if sn30 else "Menu", 10)
	for entry in [[JOY_BUTTON_Y, Vector2(413,91), "X" if sn30 else "Y"], [JOY_BUTTON_X, Vector2(389,115), "Y" if sn30 else "X"], [JOY_BUTTON_B, Vector2(437,115), "A" if sn30 else "B"], [JOY_BUTTON_A, Vector2(413,139), "B" if sn30 else "A"]]:
		var color := ACCENT if selected_control(entry[0], false) else OUTLINE
		draw_circle(entry[1], 12, color, false, 1.5, true)
		text_at(entry[1] + Vector2(-5,5), entry[2], 14)
	text_at(Vector2(190,228), "Highlighted control = binding being edited", 12)

func selected_control(index: int, axis: bool) -> bool:
	if setup.pending_action.is_empty(): return false
	for event in InputMap.action_get_events(setup.pending_action):
		if axis and event is InputEventJoypadMotion and event.axis == index: return true
		if not axis and event is InputEventJoypadButton and event.button_index == index: return true
	return false

func control_box(rect: Rect2, label: String, index: int, axis: bool) -> void:
	draw_rect(rect, ACCENT if selected_control(index, axis) else OUTLINE, false, 1.5)
	text_at(rect.position + Vector2((rect.size.x - get_theme_default_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x) / 2.0, rect.size.y / 2.0 + 4), label, 12)

func stick(center: Vector2, label: String, axis: int) -> void:
	var color := ACCENT if selected_control(axis, true) else OUTLINE
	draw_circle(center, 22, color, false, 1.5, true)
	draw_circle(center, 16, color, false, 1.0, true)
	text_at(center + Vector2(-8,4), label, 12)

func text_at(position: Vector2, value: String, font_size: int) -> void:
	draw_string(get_theme_default_font(), position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)
