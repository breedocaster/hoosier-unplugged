class_name Hud
extends Control
## Four player panels, join prompts, boon cards, combo, banners, clear card.
## Drawn immediately (no theme/scene files) so it stays easy to restyle later.

const PANEL_W := 152.0
const PANEL_H := 34.0
const MARGIN := 6.0

var stage: BrawlStage = null
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if stage == null:
		return
	var blink := (Engine.get_physics_frames() / 20) % 2 == 0
	for s in Players.slots:
		_draw_slot(s, Vector2(MARGIN + s.index * (PANEL_W + 6.0), MARGIN), blink)
	if stage.picking:
		_draw_boon_cards()
	if stage.combo >= 2:
		_text(Vector2(560, 120), "%d HITS" % stage.combo, 20, Color(1.0, 0.9, 0.35))
	if stage.go_frames > 0 and blink:
		_text(Vector2(560, 180), "GO >", 26, Color(1.0, 0.95, 0.5))
	if stage.banner_frames > 0:
		_text_centered(150, stage.banner_text, 20, Color.WHITE)
	if stage.paused:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.55))
		_text_centered(160, "PAUSED", 30, Color.WHITE)
		_text_centered(190, "START: resume    hold BACK: drop out", 12, Color(0.85, 0.85, 0.85))
	if stage.cleared:
		_draw_clear_card()
	_text(Vector2(MARGIN, 354), "%s  %s   WATTS %d" % [Game.mode_label(),
		str(GameState.DIFFICULTIES[Game.difficulty]["label"]).to_upper(), Game.watts], 10,
		Color(0.8, 0.8, 0.8, 0.8))


func _draw_slot(s: PlayerSlot, pos: Vector2, blink: bool) -> void:
	var rect := Rect2(pos, Vector2(PANEL_W, PANEL_H))
	draw_rect(rect, Color(0, 0, 0, 0.45))
	draw_rect(Rect2(pos, Vector2(4, PANEL_H)), s.color())
	var tx := pos.x + 8.0
	match s.state:
		PlayerSlot.State.EMPTY:
			if blink:
				var prompt := "TAP TO JOIN" if Players.touch_enabled and s.index == 0 \
					else "PRESS START"
				_text(Vector2(tx, pos.y + 21), "%s  %s" % [s.label(), prompt], 12, s.color())
		PlayerSlot.State.SELECTING:
			var c := Roster.character(s.character_index)
			_text(Vector2(tx, pos.y + 13), "< %s >" % str(c["name"]), 12, Color.WHITE)
			_text(Vector2(tx, pos.y + 27), "%s  ATTACK: drop in" % str(c["title"]), 9,
				Color(0.8, 0.8, 0.8))
		PlayerSlot.State.PLAYING:
			_draw_playing(s, pos, tx)


func _draw_playing(s: PlayerSlot, pos: Vector2, tx: float) -> void:
	var pf := stage.player_for_slot(s.index)
	var c := Roster.character(s.character_index)
	var lives := "" if s.lives < 0 else "  x%d" % s.lives
	_text(Vector2(tx, pos.y + 11), "%s %s%s" % [s.label(), str(c["name"]), lives], 10, Color.WHITE)
	_text(Vector2(pos.x + PANEL_W - 52.0, pos.y + 11), "%07d" % s.score, 9, Color(0.9, 0.9, 0.6))
	if pf == null:
		return
	# Health bar: red = health, green = recoverable (spent on specials).
	var bar := Rect2(tx, pos.y + 15, PANEL_W - 14.0, 7)
	draw_rect(bar, Color(0.15, 0.05, 0.05))
	var hp_w := bar.size.x * clampf(pf.hp / pf.max_hp, 0.0, 1.0)
	var green_w := bar.size.x * clampf(pf.green_hp / pf.max_hp, 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(hp_w, bar.size.y)), Color(0.95, 0.3, 0.25))
	draw_rect(Rect2(bar.position + Vector2(hp_w, 0), Vector2(green_w, bar.size.y)),
		Color(0.35, 0.85, 0.4))
	# Sparks (star moves) and boons.
	for i in pf.sparks:
		_diamond(Vector2(tx + 4.0 + i * 9.0, pos.y + 28.0), Color(1.0, 0.9, 0.3))
	for i in s.boons.size():
		var boon: Dictionary = Roster.BOONS[s.boons[i]]
		var col: Color = Roster.ELEMENT_COLORS[str(boon["element"])]
		draw_circle(Vector2(pos.x + PANEL_W - 10.0 - i * 8.0, pos.y + 28.0), 3.0, col)
	if s.drop_hold > 0:
		var p: float = float(s.drop_hold) / Players.DROP_HOLD_FRAMES
		draw_rect(Rect2(pos.x, pos.y + PANEL_H, PANEL_W * p, 3), Color(1, 1, 1, 0.8))
	if pf.removed:
		_text(Vector2(tx + 40.0, pos.y + 29), "RESPAWNING", 9, Color(1, 1, 1, 0.7))


func _draw_boon_cards() -> void:
	for key in stage.pick_options.keys():
		var idx: int = key
		var options: Array = stage.pick_options[idx]
		var x := MARGIN + idx * (PANEL_W + 6.0)
		var done := bool(stage.pick_done[idx])
		for i in options.size():
			var boon: Dictionary = Roster.BOONS[options[i]]
			var y := 48.0 + i * 40.0
			var selected := int(stage.pick_cursor[idx]) == i
			var col: Color = Roster.ELEMENT_COLORS[str(boon["element"])]
			draw_rect(Rect2(x, y, PANEL_W, 36), Color(0.05, 0.05, 0.08, 0.85))
			draw_rect(Rect2(x, y, PANEL_W, 36), col if selected and not done else col.darkened(0.6),
				false, 2.0 if selected else 1.0)
			_text(Vector2(x + 6, y + 14), str(boon["name"]).to_upper(), 11, col)
			_text(Vector2(x + 6, y + 29), str(boon["desc"]), 8, Color(0.85, 0.85, 0.85))
		if done:
			_text(Vector2(x + 6, 48.0 + options.size() * 40.0 + 10.0), "LOCKED IN", 10, Color.WHITE)
	_text_centered(200, "UP/DOWN choose   ATTACK take   (%ds)" % ceili(stage.pick_timer / 60.0),
		11, Color(1, 1, 1, 0.9))


func _draw_clear_card() -> void:
	draw_rect(Rect2(70, 190, 500, 140), Color(0.03, 0.08, 0.04, 0.92))
	draw_rect(Rect2(70, 190, 500, 140), Color(0.4, 0.85, 0.35), false, 2.0)
	var fact: Dictionary = BrawlStage.ECO_FACT
	_text(Vector2(84, 212), str(fact["title"]), 14, Color(0.6, 1.0, 0.5))
	_text_wrapped(Vector2(84, 232), str(fact["body"]), 472.0, 11, Color.WHITE)
	_text(Vector2(84, 300), str(fact["tip"]), 11, Color(0.8, 1.0, 0.7))
	_text(Vector2(84, 320), "Enemies %d   Best combo %d   Watts %d" % [stage.enemies_defeated,
		stage.best_combo, Game.watts], 10, Color(0.85, 0.85, 0.85))
	if stage.clear_frames >= 120 and (Engine.get_physics_frames() / 20) % 2 == 0:
		_text(Vector2(440, 320), "PRESS START", 10, Color.WHITE)


func _text(pos: Vector2, text: String, size: int, col: Color) -> void:
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3,
		Color(0, 0, 0, 0.8))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _text_centered(y: float, text: String, size: int, col: Color) -> void:
	draw_string_outline(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 640, size, 4,
		Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 640, size, col)


func _text_wrapped(pos: Vector2, text: String, width: float, size: int, col: Color) -> void:
	draw_multiline_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, col)


func _diamond(c: Vector2, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -4), c + Vector2(3, 0), c + Vector2(0, 4),
		c + Vector2(-3, 0)])
	draw_colored_polygon(pts, col)
