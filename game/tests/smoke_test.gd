extends Node
## Headless smoke test. Two scripted "players" drop in, brawl with a simple bot,
## pick boons, pause/unpause, and P2 drops out and back in mid-fight.
##
## Run: godot --headless --path game --fixed-fps 60 res://tests/smoke_test.tscn
## Prints "SMOKE OK" and exits 0 on success, exits 1 on failure.

const P1 := "script:p1"
const P2 := "script:p2"
const MAX_FRAMES := 5400

var stage: BrawlStage = null
var frame: int = 0
var failures: Array[String] = []
var pause_testable: bool = false


func _ready() -> void:
	Game.mode = GameState.Mode.STORY
	Game.difficulty = "normal"
	Game.boons_enabled = true
	Game.reset_run()
	Players.reset_all()
	Players.inject(P1, Vector2.ZERO, 0)
	Players.inject(P2, Vector2.ZERO, 0)
	var scene: PackedScene = load("res://stage/stage.tscn")
	stage = scene.instantiate() as BrawlStage
	add_child(stage)
	print("[smoke] started")


func _physics_process(_delta: float) -> void:
	frame += 1
	_drive_p1()
	_drive_p2()
	_checkpoints()
	if frame >= MAX_FRAMES:
		_finish()


func _drive_p1() -> void:
	if frame < 5:
		Players.inject(P1, Vector2.ZERO, 0)
	elif frame < 8:
		Players.inject(P1, Vector2.ZERO, InputFrame.START)
	elif frame < 20:
		Players.inject(P1, Vector2.ZERO, 0)
	elif frame < 23:
		Players.inject(P1, Vector2.ZERO, InputFrame.ATTACK)
	elif frame >= 2500 and frame < 2503:
		Players.inject(P1, Vector2.ZERO, InputFrame.START)
	elif frame >= 2530 and frame < 2533:
		Players.inject(P1, Vector2.ZERO, InputFrame.START)
	elif frame >= 2500 and frame < 2540:
		Players.inject(P1, Vector2.ZERO, 0)
	else:
		_bot(P1, 0)


func _drive_p2() -> void:
	if frame < 60:
		Players.inject(P2, Vector2.ZERO, 0)
	elif frame < 63:
		Players.inject(P2, Vector2.ZERO, InputFrame.START)
	elif frame < 75:
		Players.inject(P2, Vector2.ZERO, 0)
	elif frame < 77:
		Players.inject(P2, Vector2(1, 0), 0)
	elif frame < 90:
		Players.inject(P2, Vector2.ZERO, 0)
	elif frame < 93:
		Players.inject(P2, Vector2.ZERO, InputFrame.ATTACK)
	elif frame >= 2000 and frame < 2060:
		Players.inject(P2, Vector2.ZERO, InputFrame.BACK)
	elif frame >= 2060 and frame < 2100:
		Players.inject(P2, Vector2.ZERO, 0)
	elif frame >= 2100 and frame < 2103:
		Players.inject(P2, Vector2.ZERO, InputFrame.START)
	elif frame >= 2103 and frame < 2120:
		Players.inject(P2, Vector2.ZERO, 0)
	elif frame >= 2120 and frame < 2123:
		Players.inject(P2, Vector2.ZERO, InputFrame.ATTACK)
	elif frame >= 2123 and frame < 2130:
		Players.inject(P2, Vector2.ZERO, 0)
	else:
		_bot(P2, 1)


## Tiny brawler bot: walk to the nearest enemy, line up, mash. Specials and
## stars on a timer so every move path gets exercised.
func _bot(device: String, index: int) -> void:
	var pf := stage.player_for_slot(index)
	if pf == null:
		Players.inject(device, Vector2.ZERO, 0)
		return
	var held := 0
	var move := Vector2(1, 0)
	var target: Fighter = null
	var best := INF
	for f in stage.fighters:
		if f.team == 0 or not f.is_alive():
			continue
		var d := f.position.distance_to(pf.position)
		if d < best:
			best = d
			target = f
	if target != null:
		var dx := target.position.x - pf.position.x
		var dy := target.position.y - pf.position.y
		move = Vector2(signf(dx) if absf(dx) > 24.0 else signf(dx) * 0.2, clampf(dy / 10.0, -1, 1))
		if absf(dx) <= 34.0 and absf(dy) <= 10.0 and (frame + index * 3) % 6 < 2:
			held |= InputFrame.ATTACK
	elif (frame + index * 3) % 6 < 2:
		held |= InputFrame.ATTACK
	if frame % 240 == 120 + index * 7:
		held |= InputFrame.SPECIAL
	if frame % 300 == 200:
		held |= InputFrame.JUMP
	if frame == 1500 + index * 4:
		held |= InputFrame.STAR
	Players.inject(device, move, held)


func _checkpoints() -> void:
	match frame:
		30:
			_expect(Players.slots[0].state == PlayerSlot.State.PLAYING, "P1 should be playing")
			_expect(stage.player_for_slot(0) != null, "P1 fighter should exist")
		100:
			_expect(Players.slots[1].state == PlayerSlot.State.PLAYING, "P2 should be playing")
			_expect(Players.slots[1].character_index != Players.slots[0].character_index,
				"P2 should not share P1's fighter")
		2070:
			_expect(Players.slots[1].state == PlayerSlot.State.EMPTY, "P2 should have dropped out")
			_expect(stage.player_for_slot(1) == null, "P2 fighter should be gone")
		2140:
			_expect(Players.slots[1].state == PlayerSlot.State.PLAYING, "P2 should be back in")
			_expect(stage.player_for_slot(1) != null, "P2 fighter should be back")
			_expect(Players.slots[1].boons.size() >= Players.slots[0].boons.size(),
				"P2 should get catch-up boons")
		2499:
			# Pause is ignored while a boon pick or the clear card is up.
			pause_testable = not stage.picking and not stage.cleared
		2510:
			if pause_testable:
				_expect(stage.paused, "game should be paused")
		2545:
			if pause_testable:
				_expect(not stage.paused, "game should be unpaused")


func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures.append("frame %d: %s" % [frame, message])
		push_error("[smoke] FAIL " + message)


func _finish() -> void:
	_expect(stage.enemies_defeated > 0, "bots should defeat at least one enemy")
	_expect(stage.seg_index >= 1, "bots should clear at least one segment")
	var summary := "frames=%d defeated=%d segment=%d best_combo=%d watts=%d p1_boons=%s" % [
		frame, stage.enemies_defeated, stage.seg_index, stage.best_combo, Game.watts,
		str(Players.slots[0].boons)]
	if failures.is_empty():
		print("SMOKE OK ", summary)
		get_tree().quit(0)
	else:
		print("SMOKE FAIL ", summary)
		for f in failures:
			print("  ", f)
		get_tree().quit(1)
	set_physics_process(false)
