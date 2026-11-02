class_name BrawlStage
extends Node2D
## One belt-scroll stage: camera locks, enemy waves, drop-in/out, boons, clear.
##
## This prototype stage is a graybox of "Main Street Mayhem" (Stage 1 in
## docs/STORY.md). Layout, waves and pickups are data at the top of the file.

const VIEW := Vector2(640, 360)
const DEPTH_MIN := 236.0
const DEPTH_MAX := 344.0
const LENGTH := 2600.0
const MAX_ATTACKERS_PER_HERO := 2
const COMBO_TIMEOUT := 90
const TEAM_STAR_WINDOW := 20

## "at" = camera x where the screen locks. Waves spawn one after another.
const SEGMENTS := [
	{"at": 420.0, "boon": true, "waves": [["rackbot", 2], ["rackbot", 2, "fanboy", 1]]},
	{"at": 980.0, "boon": false, "waves": [["rackbot", 3], ["rackbot_red", 2, "fanboy", 1]]},
	{"at": 1560.0, "boon": true,
		"waves": [["rackbot_red", 2, "rackbot", 2], ["fanboy", 3, "rackbot", 1]]},
	{"at": 2290.0, "boon": false, "waves": [["server_brute", 1, "rackbot", 2]]},
]

const BREAKABLES := [
	[620.0, 252.0, "corn"], [900.0, 330.0, "tenderloin"], [1340.0, 262.0, "spark"],
	[1700.0, 322.0, "corn"], [2080.0, 300.0, "pie"],
]

const ECO_FACT := {
	"title": "ECO FACT: THE GAS BOOM",
	"body": "In the 1880s Indiana towns burned natural gas in street flambeaux day and "
		+ "night to show off. Experts estimate up to 90% of the gas was wasted, and "
		+ "the boom went bust by the early 1900s.",
	"tip": "Restore point: waste less, keep more.",
}

var actors: Node2D
var camera: Camera2D
var fx: Node2D
var hud: Hud
var touch: TouchControls

var fighters: Array[Fighter] = []
var pickups: Array[Pickup] = []
var cam_x: float = VIEW.x * 0.5
var frame: int = 0
var seg_index: int = 0
var seg_active: bool = false
var wave_queue: Array = []
var wave_delay: int = 0
var go_frames: int = 0
var combo: int = 0
var combo_timer: int = 0
var best_combo: int = 0
var enemies_defeated: int = 0
var banner_text: String = ""
var banner_frames: int = 0
var star_flash: int = 0
var paused: bool = false
var cleared: bool = false
var clear_frames: int = 0
var picking: bool = false
var pick_timer: int = 0
var pick_options: Dictionary = {}
var pick_cursor: Dictionary = {}
var pick_done: Dictionary = {}

var _player_by_slot: Dictionary = {}
var _respawn_timers: Dictionary = {}
var _spawned_once: Dictionary = {}
var _star_frames: Dictionary = {}
var _to_remove: Array[Fighter] = []
var _zaps: Array[Dictionary] = []


func _ready() -> void:
	var backdrop := StageBackdrop.new()
	backdrop.length = LENGTH
	add_child(backdrop)

	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	add_child(actors)

	fx = Node2D.new()
	fx.name = "FX"
	fx.z_index = 10
	fx.draw.connect(_draw_fx)
	add_child(fx)

	camera = Camera2D.new()
	camera.position = Vector2(cam_x, VIEW.y * 0.5)
	add_child(camera)
	camera.make_current()

	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = Hud.new()
	hud.stage = self
	hud_layer.add_child(hud)

	if Players.touch_enabled:
		var touch_layer := CanvasLayer.new()
		touch_layer.layer = 11
		add_child(touch_layer)
		touch = TouchControls.new()
		touch_layer.add_child(touch)

	for b in BREAKABLES:
		_spawn_breakable(Vector2(float(b[0]), float(b[1])), str(b[2]))

	Players.accepting_joins = true


func _exit_tree() -> void:
	Players.accepting_joins = false


func _physics_process(delta: float) -> void:
	_reconcile_slots()
	if cleared:
		_tick_cleared()
	elif picking:
		_tick_boon_pick()
	elif paused:
		_tick_paused()
	else:
		_tick_world(delta)
	if banner_frames > 0:
		banner_frames -= 1
	hud.queue_redraw()
	fx.queue_redraw()


func _tick_world(dt: float) -> void:
	frame += 1
	for s in Players.slots:
		if s.state == PlayerSlot.State.PLAYING \
				and Players.frame_for_slot(s).just_pressed(InputFrame.START):
			paused = true
			return

	for f in fighters:
		if f.removed:
			continue
		f.tick(dt)
	_thrown_collisions()
	for p in pickups:
		if is_instance_valid(p):
			p.tick(self)
	var kept: Array[Pickup] = []
	for p in pickups:
		if is_instance_valid(p) and not p.taken:
			kept.append(p)
	pickups = kept

	for f in _to_remove:
		if f is PlayerFighter:
			continue
		fighters.erase(f)
		f.queue_free()
	_to_remove.clear()

	_update_camera(dt)
	_update_segments()
	_update_respawns()

	if combo_timer > 0:
		combo_timer -= 1
		if combo_timer == 0:
			combo = 0
	if go_frames > 0:
		go_frames -= 1
	if star_flash > 0:
		star_flash -= 1
	var live_zaps: Array[Dictionary] = []
	for zap in _zaps:
		zap["t"] = int(zap["t"]) - 1
		if int(zap["t"]) > 0:
			live_zaps.append(zap)
	_zaps = live_zaps
	for f in fighters:
		f.queue_redraw()


func _tick_paused() -> void:
	for s in Players.slots:
		if s.state == PlayerSlot.State.PLAYING \
				and Players.frame_for_slot(s).just_pressed(InputFrame.START):
			paused = false
			return
	if Players.active_count() == 0:
		paused = false


func _tick_cleared() -> void:
	clear_frames += 1
	if clear_frames < 120:
		return
	for key in Players.frames.keys():
		var f: InputFrame = Players.frames[key]
		if f.just_pressed(InputFrame.START) or f.just_pressed(InputFrame.ATTACK):
			Players.accepting_joins = false
			Players.reset_all()
			get_tree().change_scene_to_file("res://ui/title.tscn")
			return


# --- players -----------------------------------------------------------------

func player_fighters() -> Array[PlayerFighter]:
	var out: Array[PlayerFighter] = []
	for key in _player_by_slot.keys():
		var pf: PlayerFighter = _player_by_slot[key]
		if not pf.removed:
			out.append(pf)
	return out


func player_for_slot(index: int) -> PlayerFighter:
	if _player_by_slot.has(index):
		return _player_by_slot[index]
	return null


func _reconcile_slots() -> void:
	for s in Players.slots:
		var pf := player_for_slot(s.index)
		if s.state == PlayerSlot.State.PLAYING and pf == null:
			_spawn_player(s)
		elif s.state != PlayerSlot.State.PLAYING and pf != null:
			_despawn_player(s.index, pf)


func _spawn_player(s: PlayerSlot) -> void:
	var pf := PlayerFighter.new()
	pf.stage = self
	pf.setup(s, Roster.character(s.character_index))
	pf.name = "Player%d" % (s.index + 1)
	actors.add_child(pf)
	fighters.append(pf)
	_player_by_slot[s.index] = pf
	s.fighter = pf
	if Game.mode == GameState.Mode.ARCADE and _spawned_once.has(s.index):
		Game.continues_used += 1
	_spawned_once[s.index] = true
	_grant_catch_up_boons(s, pf)
	pf.respawn_at(_entry_point(s.index))
	announce("%s  %s DROPS IN!" % [s.label(), pf.display_name], 90)


func _despawn_player(index: int, pf: PlayerFighter) -> void:
	if pf.grab_target != null:
		pf.release_grab()
	for f in fighters:
		if f.grabbed_by == pf:
			f.grabbed_by = null
			f.set_state(Fighter.State.IDLE)
	fighters.erase(pf)
	_player_by_slot.erase(index)
	_respawn_timers.erase(index)
	pf.queue_free()
	announce("P%d DROPS OUT" % (index + 1), 90)


## New arrivals get boons up to what the weakest teammate has, so dropping in
## mid-run never means showing up underpowered.
func _grant_catch_up_boons(s: PlayerSlot, pf: PlayerFighter) -> void:
	if not Game.boons_enabled:
		return
	var floor_count := -1
	for other in Players.slots:
		if other.index == s.index or other.state != PlayerSlot.State.PLAYING:
			continue
		if floor_count < 0 or other.boons.size() < floor_count:
			floor_count = other.boons.size()
	while floor_count > s.boons.size():
		var options := _roll_boons(1, s)
		if options.is_empty():
			break
		pf.apply_boon(options[0])


func _entry_point(index: int) -> Vector2:
	var x := cam_x - VIEW.x * 0.5 + 60.0 + index * 24.0
	var y := lerpf(DEPTH_MIN + 16.0, DEPTH_MAX - 16.0, float(index) / 3.0)
	return Vector2(x, y)


func on_player_down(pf: PlayerFighter) -> void:
	var s := pf.slot
	if s.lives < 0:
		_respawn_timers[s.index] = int(Game.setting("respawn_frames"))
		return
	s.lives -= 1
	if s.lives > 0:
		_respawn_timers[s.index] = int(Game.setting("respawn_frames"))
	else:
		announce("%s IS OUT - PRESS START TO CONTINUE" % s.label(), 150)
		Players.drop_slot(s)


func _update_respawns() -> void:
	for key in _respawn_timers.keys():
		var t: int = _respawn_timers[key] - 1
		if t > 0:
			_respawn_timers[key] = t
			continue
		_respawn_timers.erase(key)
		var pf := player_for_slot(int(key))
		if pf != null:
			pf.respawn_at(_entry_point(int(key)))


func on_player_hit(_pf: PlayerFighter) -> void:
	# Shared combo meter breaks when anyone on the team gets hit (SoR4 rule).
	combo = 0
	combo_timer = 0


func register_combo_hit(_pf: PlayerFighter) -> void:
	combo += 1
	combo_timer = COMBO_TIMEOUT
	best_combo = maxi(best_combo, combo)


func on_star_move(pf: PlayerFighter) -> void:
	star_flash = 14
	var now := frame
	for key in _star_frames.keys():
		if int(key) != pf.slot.index and now - int(_star_frames[key]) <= TEAM_STAR_WINDOW:
			announce("CROSSROADS COMBO!", 120)
			for e in _enemies_on_screen():
				var dmg := 20.0
				if e.take_hit(pf, {"launch": true, "push": 160.0}, dmg):
					pf.on_hit_landed(e, dmg)
			break
	_star_frames[pf.slot.index] = now


# --- enemies -----------------------------------------------------------------

func _update_segments() -> void:
	if cleared:
		return
	if not seg_active:
		if seg_index < SEGMENTS.size() and Players.active_count() > 0:
			var seg: Dictionary = SEGMENTS[seg_index]
			if cam_x >= float(seg["at"]) - 1.0:
				_start_segment(seg)
		return
	if _enemy_count() > 0:
		return
	if wave_queue.is_empty():
		_finish_segment()
		return
	wave_delay -= 1
	if wave_delay <= 0:
		_spawn_wave(wave_queue.pop_front())
		wave_delay = 30


func _start_segment(seg: Dictionary) -> void:
	seg_active = true
	var waves: Array = seg["waves"]
	wave_queue = waves.duplicate(true)
	wave_delay = 10


func _finish_segment() -> void:
	var seg: Dictionary = SEGMENTS[seg_index]
	seg_active = false
	seg_index += 1
	if seg_index >= SEGMENTS.size():
		_stage_clear()
		return
	go_frames = 180
	if bool(seg["boon"]) and Game.boons_enabled:
		_open_boon_pick()


func _spawn_wave(wave: Array) -> void:
	var n_players := maxi(1, Players.active_count())
	var spawned := 0
	for i in range(0, wave.size(), 2):
		var kind: String = wave[i]
		var count: int = wave[i + 1]
		var def: Dictionary = Roster.ENEMIES[kind]
		var boss := bool(def.get("boss", false))
		if not boss:
			count += int(roundf((n_players - 1) * count * 0.5))
		var per_player := 0.5 if boss else 0.25
		var hp_scale: float = Game.setting("enemy_hp") * (1.0 + per_player * (n_players - 1))
		for _j in count:
			var side := 1.0 if (spawned % 2 == 0) else -1.0
			var x := cam_x + side * (VIEW.x * 0.5 + 24.0 + spawned * 14.0)
			var y: float = Game.rng.randf_range(DEPTH_MIN + 8.0, DEPTH_MAX - 8.0)
			_spawn_enemy(kind, Vector2(x, y), hp_scale)
			spawned += 1
	if spawned > 0 and wave.has("server_brute"):
		announce("BOSS: SERVER BRUTE", 120)


func _spawn_enemy(kind: String, pos: Vector2, hp_scale: float) -> EnemyFighter:
	var e := EnemyFighter.new()
	e.stage = self
	e.setup(kind, hp_scale, Game.setting("enemy_damage"))
	e.position = pos
	actors.add_child(e)
	fighters.append(e)
	return e


func _spawn_breakable(pos: Vector2, drop: String) -> void:
	var b := Breakable.new()
	b.stage = self
	b.setup(drop, "SERVER")
	b.position = pos
	actors.add_child(b)
	fighters.append(b)


func spawn_pickup(kind: String, pos: Vector2) -> void:
	var p := Pickup.new()
	p.kind = kind
	p.position = pos
	actors.add_child(p)
	pickups.append(p)


func on_enemy_defeated(e: EnemyFighter) -> void:
	enemies_defeated += 1
	Game.watts += e.watts
	if e.is_boss:
		spawn_pickup("pie", e.position)
	elif Game.rng.randf() < 0.12:
		spawn_pickup("corn", e.position)


func on_fighter_removed(f: Fighter) -> void:
	if not _to_remove.has(f):
		_to_remove.append(f)


func _enemy_count() -> int:
	var n := 0
	for f in fighters:
		if f is EnemyFighter and not f.removed:
			n += 1
	return n


func _enemies_on_screen() -> Array[Fighter]:
	var out: Array[Fighter] = []
	for f in fighters:
		if f.team != 0 and f.is_alive() and on_screen(f):
			out.append(f)
	return out


func nearest_player(origin: Fighter) -> PlayerFighter:
	var best: PlayerFighter = null
	var best_d := INF
	for p in player_fighters():
		if not p.is_alive() or p.state == Fighter.State.SPAWN:
			continue
		var d := p.position.distance_squared_to(origin.position)
		if d < best_d:
			best_d = d
			best = p
	return best


func _attackers_on(target: Fighter) -> int:
	var n := 0
	for f in fighters:
		if f is EnemyFighter and f.state == Fighter.State.ATTACK and (f as EnemyFighter).target == target:
			n += 1
	return n


func has_attack_room(target: Fighter) -> bool:
	return _attackers_on(target) < MAX_ATTACKERS_PER_HERO


func request_attack_token(e: EnemyFighter, target: Fighter) -> bool:
	return e.is_boss or has_attack_room(target)


# --- combat ------------------------------------------------------------------

func resolve_hits(attacker: Fighter, data: Dictionary) -> void:
	for t in fighters:
		if t == attacker or not t.is_alive() or t.team == attacker.team:
			continue
		if attacker.team == 1 and t.team != 0:
			continue
		var id := t.get_instance_id()
		if attacker.atk_hits.has(id):
			continue
		if not _in_range(attacker, t, data):
			continue
		attacker.atk_hits.append(id)
		var dmg := float(data.get("damage", 5.0)) * attacker.damage_multiplier()
		if t.take_hit(attacker, data, dmg):
			attacker.on_hit_landed(t, dmg)
			_zaps.append({"a": t.position + Vector2(0, -t.z - t.height * 0.6),
				"b": Vector2.ZERO, "t": 5, "spark": true})


func _in_range(attacker: Fighter, t: Fighter, data: Dictionary) -> bool:
	var area := str(data.get("area", "front"))
	if area == "screen":
		return on_screen(t)
	var depth := float(data.get("depth", Fighter.DEPTH_TOLERANCE))
	if absf(t.position.y - attacker.position.y) > depth:
		return false
	if absf(t.z - attacker.z) > 40.0:
		return false
	var reach := float(data.get("reach", 30.0))
	var dx := t.position.x - attacker.position.x
	if area == "around":
		return absf(dx) <= reach + t.half_width
	var fx_dist := dx * attacker.facing
	return fx_dist >= -6.0 and fx_dist <= reach + t.half_width


func grab_candidate(pf: PlayerFighter) -> Fighter:
	for f in fighters:
		if not (f is EnemyFighter) or not f.can_be_grabbed() or (f as EnemyFighter).is_boss:
			continue
		var dx := f.position.x - pf.position.x
		if dx * pf.facing > 0.0 and absf(dx) <= 24.0 and absf(f.position.y - pf.position.y) <= 8.0:
			return f
	return null


func chain_zap(pf: PlayerFighter, origin: Fighter, damage: float) -> void:
	var best: Fighter = null
	var best_d := 140.0 * 140.0
	for f in fighters:
		if f == origin or f.team != 1 or not f.is_alive():
			continue
		var d := f.position.distance_squared_to(origin.position)
		if d < best_d:
			best_d = d
			best = f
	if best == null:
		return
	if best.take_hit(pf, {"hitstun": 20, "push": 30.0}, damage):
		_zaps.append({"a": origin.position + Vector2(0, -origin.z - 24.0),
			"b": best.position + Vector2(0, -best.z - 24.0), "t": 10, "spark": false})


func _thrown_collisions() -> void:
	for t in fighters:
		if not t.thrown or t.state != Fighter.State.AIRBORNE:
			continue
		for o in fighters:
			if o == t or o.team != t.team or o.thrown or not o.is_alive():
				continue
			if t.atk_hits.has(o.get_instance_id()):
				continue
			if absf(o.position.x - t.position.x) < 22.0 \
					and absf(o.position.y - t.position.y) < 14.0 and o.z < 40.0:
				t.atk_hits.append(o.get_instance_id())
				o.take_hit(t, {"launch": true, "push": 150.0}, 8.0)


func clamp_fighter(f: Fighter) -> void:
	f.position.y = clampf(f.position.y, DEPTH_MIN, DEPTH_MAX)
	if f.team == 0:
		f.position.x = clampf(f.position.x, cam_x - VIEW.x * 0.5 + 12.0,
			cam_x + VIEW.x * 0.5 - 12.0)
	else:
		f.position.x = clampf(f.position.x, -80.0, LENGTH + 80.0)


func on_screen(f: Fighter) -> bool:
	return absf(f.position.x - cam_x) <= VIEW.x * 0.5 + f.half_width


# --- camera, boons, clear ----------------------------------------------------

func _update_camera(dt: float) -> void:
	if seg_active:
		return
	var sum := 0.0
	var n := 0
	for p in player_fighters():
		if p.is_alive():
			sum += p.position.x
			n += 1
	if n == 0:
		return
	var limit := LENGTH - VIEW.x * 0.5
	if seg_index < SEGMENTS.size():
		var seg: Dictionary = SEGMENTS[seg_index]
		limit = minf(limit, float(seg["at"]))
	var desired := minf(maxf(cam_x, sum / n), limit)
	cam_x = move_toward(cam_x, desired, 260.0 * dt)
	camera.position = Vector2(roundf(cam_x), VIEW.y * 0.5)


func _open_boon_pick() -> void:
	pick_options.clear()
	pick_cursor.clear()
	pick_done.clear()
	for s in Players.slots:
		if s.state == PlayerSlot.State.PLAYING:
			pick_options[s.index] = _roll_boons(3, s)
			pick_cursor[s.index] = 0
			pick_done[s.index] = false
	picking = not pick_options.is_empty()
	pick_timer = 600
	if picking:
		announce("ECO-BOON! PICK ONE", 90)


func _tick_boon_pick() -> void:
	pick_timer -= 1
	var all_done := true
	for key in pick_options.keys():
		var idx: int = key
		if pick_done[idx]:
			continue
		var s: PlayerSlot = Players.slots[idx]
		var options: Array = pick_options[idx]
		if s.state != PlayerSlot.State.PLAYING or options.is_empty():
			pick_done[idx] = true
			continue
		var f: InputFrame = Players.frame_for_slot(s)
		if s.menu_cooldown == 0 and absf(f.move.y) > 0.6:
			var step := 1 if f.move.y > 0.0 else -1
			pick_cursor[idx] = posmod(int(pick_cursor[idx]) + step, options.size())
			s.menu_cooldown = 10
		if f.just_pressed(InputFrame.ATTACK) or f.just_pressed(InputFrame.JUMP) or pick_timer <= 0:
			var id: String = options[int(pick_cursor[idx])]
			var pf := player_for_slot(idx)
			if pf != null:
				pf.apply_boon(id)
			else:
				s.boons.append(id)
			pick_done[idx] = true
			var boon: Dictionary = Roster.BOONS[id]
			announce("%s TAKES %s" % [s.label(), str(boon["name"]).to_upper()], 60)
		else:
			all_done = false
	if all_done:
		picking = false


func _roll_boons(count: int, s: PlayerSlot) -> Array[String]:
	var pool: Array[String] = []
	for key in Roster.BOONS.keys():
		var id: String = key
		if not s.boons.has(id):
			pool.append(id)
	var out: Array[String] = []
	while out.size() < count and not pool.is_empty():
		var i: int = Game.rng.randi_range(0, pool.size() - 1)
		out.append(pool[i])
		pool.remove_at(i)
	return out


func _stage_clear() -> void:
	cleared = true
	clear_frames = 0
	announce("STAGE CLEAR!", 240)


func announce(text: String, frames_to_show: int) -> void:
	banner_text = text
	banner_frames = frames_to_show


func _draw_fx() -> void:
	for zap in _zaps:
		var a: Vector2 = zap["a"]
		if bool(zap["spark"]):
			var r := 4.0 + (5 - int(zap["t"])) * 2.0
			fx.draw_circle(a, r, Color(1, 1, 0.7, 0.8))
		else:
			var b: Vector2 = zap["b"]
			var mid := (a + b) * 0.5 + Vector2(0, -10)
			fx.draw_polyline(PackedVector2Array([a, mid, b]), Color(0.5, 0.9, 1.0), 2.0)
	if star_flash > 0:
		var r := Rect2(cam_x - VIEW.x * 0.5, 0, VIEW.x, VIEW.y)
		fx.draw_rect(r, Color(1, 1, 0.8, star_flash / 28.0))
