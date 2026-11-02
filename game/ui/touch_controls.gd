class_name TouchControls
extends Control
## Phone/tablet overlay: floating stick on the left half, four buttons on the
## right, START at top center. Feeds Players.touch_move / touch_held, which the
## Players autoload turns into the "touch" device's InputFrame.
## Bluetooth gamepads on a phone/tablet show up as normal joypads, so couch
## co-op on one tablet works without anything special here.

const STICK_RADIUS := 40.0
const BUTTONS := [
	{"bit": InputFrame.ATTACK, "label": "HIT", "pos": Vector2(560, 300), "r": 30.0},
	{"bit": InputFrame.JUMP, "label": "JUMP", "pos": Vector2(500, 330), "r": 24.0},
	{"bit": InputFrame.SPECIAL, "label": "SPEC", "pos": Vector2(610, 245), "r": 22.0},
	{"bit": InputFrame.STAR, "label": "STAR", "pos": Vector2(540, 235), "r": 20.0},
	{"bit": InputFrame.START, "label": "II", "pos": Vector2(320, 20), "r": 14.0},
]

var font: Font = ThemeDB.fallback_font

var _stick_index: int = -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
## touch index -> button bit
var _button_touches: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_down(t.index, t.position)
		else:
			_touch_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _stick_index:
			_stick_pos = d.position
			_update_stick()


func _touch_down(index: int, pos: Vector2) -> void:
	for b in BUTTONS:
		var center: Vector2 = b["pos"]
		if pos.distance_to(center) <= float(b["r"]) + 8.0:
			_button_touches[index] = int(b["bit"])
			_refresh_buttons()
			return
	if pos.x < 320.0 and _stick_index == -1:
		_stick_index = index
		_stick_origin = pos
		_stick_pos = pos
		_update_stick()


func _touch_up(index: int) -> void:
	if index == _stick_index:
		_stick_index = -1
		Players.touch_move = Vector2.ZERO
	_button_touches.erase(index)
	_refresh_buttons()
	queue_redraw()


func _update_stick() -> void:
	var v := (_stick_pos - _stick_origin) / STICK_RADIUS
	Players.touch_move = v.limit_length(1.0)
	queue_redraw()


func _refresh_buttons() -> void:
	var held := 0
	for key in _button_touches.keys():
		held |= int(_button_touches[key])
	Players.touch_held = held
	queue_redraw()


func _draw() -> void:
	if _stick_index != -1:
		draw_circle(_stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.12))
		var move: Vector2 = Players.touch_move
		var knob := _stick_origin + move * STICK_RADIUS
		draw_circle(knob, 16.0, Color(1, 1, 1, 0.35))
	for b in BUTTONS:
		var bit := int(b["bit"])
		var down: bool = (Players.touch_held & bit) != 0
		var center: Vector2 = b["pos"]
		draw_circle(center, float(b["r"]), Color(1, 1, 1, 0.35 if down else 0.15))
		draw_string(font, center + Vector2(-float(b["r"]), 4), str(b["label"]),
			HORIZONTAL_ALIGNMENT_CENTER, float(b["r"]) * 2.0, 10, Color(1, 1, 1, 0.8))
