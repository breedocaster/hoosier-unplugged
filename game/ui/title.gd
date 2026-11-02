extends Control
## Title + mode select. Whoever confirms becomes P1; everyone else drops in
## from inside the stage by pressing START.

const STAGE_SCENE := "res://stage/stage.tscn"
const OPTIONS := [
	{"label": "STORY  -  CHILL", "hint": "Drop in any time. You can't lose. Boons on.",
		"mode": "story", "difficulty": "chill", "boons": true},
	{"label": "STORY  -  NORMAL", "hint": "Respawns are slower, enemies hit harder. Boons on.",
		"mode": "story", "difficulty": "normal", "boons": true},
	{"label": "ARCADE  -  HOOSIER HARD", "hint": "Lives + continues, score chase, no boons.",
		"mode": "arcade", "difficulty": "hard", "boons": false},
	{"label": "ROLLBACK RUN", "hint": "Roguelite mode - coming soon (see docs/GDD.md).",
		"mode": "", "difficulty": "", "boons": true},
]

var cursor: int = 0
var cooldown: int = 0
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Players.accepting_joins = false
	Players.reset_all()


func _physics_process(_delta: float) -> void:
	if cooldown > 0:
		cooldown -= 1
	for key in Players.frames.keys():
		var device: String = key
		var f: InputFrame = Players.frames[key]
		if cooldown == 0 and absf(f.move.y) > 0.6:
			cursor = posmod(cursor + (1 if f.move.y > 0.0 else -1), OPTIONS.size())
			cooldown = 12
		if f.just_pressed(InputFrame.START) or f.just_pressed(InputFrame.ATTACK) \
				or f.just_pressed(InputFrame.JUMP):
			_choose(device)
			return
	queue_redraw()


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	for i in OPTIONS.size():
		if absf(touch.position.y - _option_y(i)) < 14.0:
			cursor = i
			_choose("touch")
			return


func _choose(device: String) -> void:
	var opt: Dictionary = OPTIONS[cursor]
	var mode := str(opt["mode"])
	if mode == "":
		return
	Game.mode = GameState.Mode.ARCADE if mode == "arcade" else GameState.Mode.STORY
	Game.difficulty = str(opt["difficulty"])
	Game.boons_enabled = bool(opt["boons"])
	Game.reset_run()
	Players.reset_all()
	Players.open_slot(device)
	get_tree().change_scene_to_file(STAGE_SCENE)


func _option_y(i: int) -> float:
	return 190.0 + i * 28.0


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.06, 0.06, 0.12))
	for i in 12:
		draw_rect(Rect2(0, 300 + i * 5, 640, 2), Color(0.25, 0.85, 1.0, 0.05 + i * 0.01))
	_centered(70, "HOOSIER UNPLUGGED", 40, Color(1.0, 0.85, 0.3))
	_centered(98, "pull the plug on StratoStack - drop-in co-op for 1-4", 13, Color(0.8, 0.9, 1.0))
	_centered(118, "working title  /  prototype build", 10, Color(0.6, 0.6, 0.7))
	for i in OPTIONS.size():
		var opt: Dictionary = OPTIONS[i]
		var selected := i == cursor
		var col := Color(1, 1, 1) if selected else Color(0.6, 0.6, 0.7)
		if str(opt["mode"]) == "":
			col = col.darkened(0.4)
		_centered(_option_y(i), ("> %s <" if selected else "%s") % str(opt["label"]), 16, col)
	var current: Dictionary = OPTIONS[cursor]
	_centered(310, str(current["hint"]), 11, Color(0.85, 0.85, 0.85))
	_centered(334, "P1 keys: WASD move  J hit  K jump  L special  I star  "
		+ "Enter start  Tab(hold) leave", 9, Color(0.6, 0.6, 0.7))
	_centered(348, "P2 keys: arrows  , hit  . jump  / special  ; star  "
		+ "Backspace start  Del(hold) leave", 9, Color(0.6, 0.6, 0.7))


func _centered(y: float, text: String, size: int, col: Color) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 640, size, col)
