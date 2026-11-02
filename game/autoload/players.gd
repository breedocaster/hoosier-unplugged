extends Node
## Player seats + device polling. Autoloaded as `Players`.
##
## Drop-in / drop-out lives here, not in the stage:
##   * Any free device that presses START opens a seat (SELECTING).
##   * Left/right picks a fighter, ATTACK drops you in (PLAYING).
##   * Hold BACK to drop out. An unplugged pad drops out after a grace period.
## The stage just reconciles fighters against seat states every tick, so the
## same path will serve online peers later (their device ids are "net:...").

signal slot_changed(slot_index: int)

const MAX_SLOTS := 4
const DROP_HOLD_FRAMES := 45
const DISCONNECT_GRACE_FRAMES := 600
const STICK_DEADZONE := 0.25

var slots: Array[PlayerSlot] = []
## device id -> InputFrame for the current tick.
var frames: Dictionary = {}
## Stages turn this on; menus turn it off.
var accepting_joins: bool = false
var touch_enabled: bool = false
## Written by ui/touch_controls.gd.
var touch_move := Vector2.ZERO
var touch_held: int = 0

var _prev_held: Dictionary = {}
var _injected: Dictionary = {}
var _blank := InputFrame.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -100
	for i in MAX_SLOTS:
		var s := PlayerSlot.new()
		s.index = i
		slots.append(s)
	touch_enabled = DisplayServer.is_touchscreen_available()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _physics_process(_delta: float) -> void:
	poll()


## Reads every device once. Called automatically each physics tick.
func poll() -> void:
	var devices: Array[String] = ["kb0", "kb1"]
	for id in Input.get_connected_joypads():
		devices.append("joy%d" % id)
	if touch_enabled:
		devices.append("touch")
	for key in _injected.keys():
		devices.append(str(key))
	var next := {}
	for d in devices:
		var f := _read_device(d)
		var prev: int = _prev_held.get(d, 0)
		f.pressed = f.held & ~prev
		_prev_held[d] = f.held
		next[d] = f
	frames = next
	_update_slots()


func frame_for_device(device: String) -> InputFrame:
	if frames.has(device):
		return frames[device]
	return _blank


func frame_for_slot(slot: PlayerSlot) -> InputFrame:
	if slot == null or slot.device == "":
		return _blank
	return frame_for_device(slot.device)


func slot_for_device(device: String) -> PlayerSlot:
	for s in slots:
		if s.state != PlayerSlot.State.EMPTY and s.device == device:
			return s
	return null


func active_count() -> int:
	var n := 0
	for s in slots:
		if s.state == PlayerSlot.State.PLAYING:
			n += 1
	return n


func open_slot(device: String) -> PlayerSlot:
	if slot_for_device(device) != null:
		return slot_for_device(device)
	for s in slots:
		if s.state == PlayerSlot.State.EMPTY:
			s.clear()
			s.state = PlayerSlot.State.SELECTING
			s.device = device
			s.character_index = _first_free_character(s.index, s.index)
			s.menu_cooldown = 10
			slot_changed.emit(s.index)
			return s
	return null


func confirm_slot(s: PlayerSlot) -> void:
	s.state = PlayerSlot.State.PLAYING
	s.lives = Game.lives_per_player()
	s.drop_hold = 0
	slot_changed.emit(s.index)


func drop_slot(s: PlayerSlot) -> void:
	s.clear()
	slot_changed.emit(s.index)


func reset_all() -> void:
	for s in slots:
		s.clear()
	_injected.clear()
	_prev_held.clear()
	frames = {}


## Feeds a scripted device (tests today, network peers tomorrow).
func inject(device: String, move: Vector2, held: int) -> void:
	_injected[device] = InputFrame.from_values(move, held)


func remove_injected(device: String) -> void:
	_injected.erase(device)


func characters_in_use(except_index: int) -> Array[int]:
	var used: Array[int] = []
	for s in slots:
		if s.index != except_index and s.state != PlayerSlot.State.EMPTY:
			used.append(s.character_index)
	return used


func _first_free_character(start: int, slot_index: int) -> int:
	var used := characters_in_use(slot_index)
	for i in Roster.character_count():
		var c := posmod(start + i, Roster.character_count())
		if not used.has(c):
			return c
	return posmod(start, Roster.character_count())


func _cycle_character(s: PlayerSlot, direction: int) -> void:
	var used := characters_in_use(s.index)
	var c := s.character_index
	for _i in Roster.character_count():
		c = posmod(c + direction, Roster.character_count())
		if not used.has(c):
			s.character_index = c
			return


func _update_slots() -> void:
	# Joining: a free device pressing START (or tapping ATTACK on touch).
	if accepting_joins:
		for key in frames.keys():
			var device: String = key
			if slot_for_device(device) != null:
				continue
			var f: InputFrame = frames[key]
			var wants_in := f.just_pressed(InputFrame.START)
			if device == "touch" and f.just_pressed(InputFrame.ATTACK):
				wants_in = true
			if wants_in:
				open_slot(device)

	for s in slots:
		if s.menu_cooldown > 0:
			s.menu_cooldown -= 1
		match s.state:
			PlayerSlot.State.SELECTING:
				_update_selecting(s)
			PlayerSlot.State.PLAYING:
				_update_playing(s)


func _update_selecting(s: PlayerSlot) -> void:
	var f := frame_for_slot(s)
	if s.menu_cooldown == 0 and absf(f.move.x) > 0.6:
		_cycle_character(s, 1 if f.move.x > 0.0 else -1)
		s.menu_cooldown = 12
		slot_changed.emit(s.index)
	elif s.menu_cooldown == 0 and f.just_pressed(InputFrame.ATTACK):
		confirm_slot(s)
	elif f.just_pressed(InputFrame.BACK):
		drop_slot(s)


func _update_playing(s: PlayerSlot) -> void:
	var f := frame_for_slot(s)
	if f.is_held(InputFrame.BACK):
		s.drop_hold += 1
		if s.drop_hold >= DROP_HOLD_FRAMES:
			drop_slot(s)
			return
	else:
		s.drop_hold = 0
	if s.disconnect_timer > 0:
		s.disconnect_timer -= 1
		if s.disconnect_timer == 0:
			drop_slot(s)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	var s := slot_for_device("joy%d" % device_id)
	if s == null:
		return
	if connected:
		s.disconnect_timer = 0
	elif s.state == PlayerSlot.State.PLAYING:
		s.disconnect_timer = DISCONNECT_GRACE_FRAMES
	else:
		drop_slot(s)


func _read_device(device: String) -> InputFrame:
	if _injected.has(device):
		var src: InputFrame = _injected[device]
		return InputFrame.from_values(src.move, src.held)
	var f := InputFrame.new()
	if device == "kb0":
		f.move = _key_axes(KEY_A, KEY_D, KEY_W, KEY_S)
		_key_bit(f, KEY_J, InputFrame.ATTACK)
		_key_bit(f, KEY_K, InputFrame.JUMP)
		_key_bit(f, KEY_L, InputFrame.SPECIAL)
		_key_bit(f, KEY_I, InputFrame.STAR)
		_key_bit(f, KEY_ENTER, InputFrame.START)
		_key_bit(f, KEY_ESCAPE, InputFrame.START)
		_key_bit(f, KEY_TAB, InputFrame.BACK)
	elif device == "kb1":
		f.move = _key_axes(KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN)
		_key_bit(f, KEY_KP_1, InputFrame.ATTACK)
		_key_bit(f, KEY_COMMA, InputFrame.ATTACK)
		_key_bit(f, KEY_KP_2, InputFrame.JUMP)
		_key_bit(f, KEY_PERIOD, InputFrame.JUMP)
		_key_bit(f, KEY_KP_3, InputFrame.SPECIAL)
		_key_bit(f, KEY_SLASH, InputFrame.SPECIAL)
		_key_bit(f, KEY_KP_5, InputFrame.STAR)
		_key_bit(f, KEY_SEMICOLON, InputFrame.STAR)
		_key_bit(f, KEY_KP_ENTER, InputFrame.START)
		_key_bit(f, KEY_BACKSPACE, InputFrame.START)
		_key_bit(f, KEY_KP_0, InputFrame.BACK)
		_key_bit(f, KEY_DELETE, InputFrame.BACK)
	elif device.begins_with("joy"):
		_read_joypad(f, device.substr(3).to_int())
	elif device == "touch":
		f.move = touch_move.limit_length(1.0)
		f.held = touch_held
	return f


func _read_joypad(f: InputFrame, id: int) -> void:
	var m := Vector2(Input.get_joy_axis(id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(id, JOY_AXIS_LEFT_Y))
	if m.length() < STICK_DEADZONE:
		m = Vector2.ZERO
	if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_LEFT):
		m.x = -1.0
	if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_RIGHT):
		m.x = 1.0
	if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_UP):
		m.y = -1.0
	if Input.is_joy_button_pressed(id, JOY_BUTTON_DPAD_DOWN):
		m.y = 1.0
	f.move = m.limit_length(1.0)
	# Xbox layout names: X attack, A jump, Y special, B star (SoR-style).
	_joy_bit(f, id, JOY_BUTTON_X, InputFrame.ATTACK)
	_joy_bit(f, id, JOY_BUTTON_A, InputFrame.JUMP)
	_joy_bit(f, id, JOY_BUTTON_Y, InputFrame.SPECIAL)
	_joy_bit(f, id, JOY_BUTTON_B, InputFrame.STAR)
	_joy_bit(f, id, JOY_BUTTON_RIGHT_SHOULDER, InputFrame.STAR)
	_joy_bit(f, id, JOY_BUTTON_START, InputFrame.START)
	_joy_bit(f, id, JOY_BUTTON_BACK, InputFrame.BACK)


func _key_axes(left: Key, right: Key, up: Key, down: Key) -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(left):
		v.x -= 1.0
	if Input.is_physical_key_pressed(right):
		v.x += 1.0
	if Input.is_physical_key_pressed(up):
		v.y -= 1.0
	if Input.is_physical_key_pressed(down):
		v.y += 1.0
	return v.limit_length(1.0)


func _key_bit(f: InputFrame, key: Key, bit: int) -> void:
	if Input.is_physical_key_pressed(key):
		f.held |= bit


func _joy_bit(f: InputFrame, id: int, button: JoyButton, bit: int) -> void:
	if Input.is_joy_button_pressed(id, button):
		f.held |= bit
