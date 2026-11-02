class_name PlayerFighter
extends Fighter
## A hero driven by one PlayerSlot's InputFrames.

const GRAB_HOLD_FRAMES := 8
const GRAB_MAX_FRAMES := 150
const COMBO_BUFFER_FRAMES := 12

var slot: PlayerSlot = null
var def: Dictionary = {}
var speed: float = 120.0
var jump_speed: float = 420.0
var reach_mult: float = 1.0
var power_mult: float = 1.0
var sparks: int = 1
var combo_step: int = 0
var combo_hits_this_attack: int = 0
var buffered_attack: bool = false
var air_attack: bool = false
var grab_hold: int = 0
var knees: int = 0
var chain_counter: int = 0
var respawn_wait: int = 0
var mods := {
	"speed": 1.0, "damage": 1.0, "damage_taken": 1.0, "food": 1.0,
	"green_recover": 1.0, "special_cost": 1.0, "chain_zap": 0.0, "no_green": 0.0,
}


func setup(p_slot: PlayerSlot, p_def: Dictionary) -> void:
	slot = p_slot
	def = p_def
	team = 0
	display_name = str(def["name"])
	body_color = def["color"]
	accent_color = slot.color()
	max_hp = float(def["hp"])
	hp = max_hp
	speed = float(def["speed"])
	jump_speed = float(def["jump"])
	power_mult = float(def["damage"])
	reach_mult = float(def["reach"])
	height = 46.0
	half_width = 10.0
	for id in slot.boons:
		_apply_mods(id)


func apply_boon(id: String) -> void:
	slot.boons.append(id)
	_apply_mods(id)


func _apply_mods(id: String) -> void:
	var boon: Dictionary = Roster.BOONS[id]
	var m: Dictionary = boon["mods"]
	for key in m.keys():
		if key == "chain_zap" or key == "no_green":
			mods[key] = 1.0
		else:
			mods[key] = float(mods[key]) * float(m[key])


func damage_multiplier() -> float:
	return power_mult * float(mods["damage"])


func tick(dt: float) -> void:
	if tick_common(dt):
		return
	var f: InputFrame = Players.frame_for_slot(slot)
	match state:
		State.SPAWN:
			_tick_spawn(dt)
		State.IDLE, State.WALK:
			_tick_ground(f, dt)
		State.JUMP:
			_tick_jump(f, dt)
		State.ATTACK:
			_tick_attack(f, dt)
		State.GRAB:
			_tick_grab(f)


func take_hit(attacker: Fighter, data: Dictionary, damage: float) -> bool:
	var scaled := damage * float(mods["damage_taken"])
	var hit: bool = super.take_hit(attacker, data, scaled)
	if hit and stage != null:
		stage.on_player_hit(self)
	return hit


func on_hit_landed(target: Fighter, damage: float) -> void:
	combo_hits_this_attack += 1
	slot.score += int(damage * 10.0)
	# Win back green health by staying aggressive without getting hit.
	if green_hp > 0.0 and float(mods["no_green"]) == 0.0:
		var back := minf(green_hp, damage * 0.6 * float(mods["green_recover"]))
		hp = minf(max_hp, hp + back)
		green_hp -= back
	if float(mods["chain_zap"]) > 0.0:
		chain_counter += 1
		if chain_counter % 3 == 0 and stage != null:
			stage.chain_zap(self, target, damage * 0.5)
	if stage != null:
		stage.register_combo_hit(self)


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount * float(mods["food"]))


func on_dead_finished() -> void:
	# Players never get freed; the stage respawns or benches them.
	if removed:
		return
	removed = true
	if stage != null:
		stage.on_player_down(self)


func respawn_at(pos: Vector2) -> void:
	removed = false
	hp = max_hp
	green_hp = 0.0
	position = pos
	z = 160.0
	vz = 0.0
	vel = Vector2.ZERO
	invuln = 120
	thrown = false
	grabbed_by = null
	grab_target = null
	set_state(State.SPAWN)


# --- states ------------------------------------------------------------------

func _tick_spawn(dt: float) -> void:
	vz -= GRAVITY * 0.5 * dt
	z = maxf(0.0, z + vz * dt)
	if z <= 0.0:
		set_state(State.IDLE)


func _tick_ground(f: InputFrame, dt: float) -> void:
	var spd := speed * float(mods["speed"])
	vel = Vector2(f.move.x * spd, f.move.y * spd * 0.6)
	if absf(f.move.x) > 0.1:
		facing = 1 if f.move.x > 0.0 else -1
	set_state_keep_frames(State.WALK if vel.length() > 1.0 else State.IDLE)
	_move(dt)

	# Final Fight grab: walk into an enemy for a moment.
	var target: Fighter = null
	if absf(f.move.x) > 0.3 and stage != null:
		target = stage.grab_candidate(self)
	if target != null:
		grab_hold += 1
		if grab_hold >= GRAB_HOLD_FRAMES:
			_begin_grab(target)
			return
	else:
		grab_hold = 0

	if f.just_pressed(InputFrame.STAR) and sparks > 0:
		_start_star()
	elif f.just_pressed(InputFrame.SPECIAL) and hp > 1.0:
		_start_special()
	elif f.just_pressed(InputFrame.JUMP):
		set_state(State.JUMP)
		vz = jump_speed
		air_attack = false
		atk_hits.clear()
	elif f.just_pressed(InputFrame.ATTACK):
		combo_step = 0
		_start_combo_hit()


func _tick_jump(f: InputFrame, dt: float) -> void:
	_air_physics(dt)
	if f.just_pressed(InputFrame.ATTACK) and not air_attack:
		air_attack = true
		atk = _scaled(Roster.JUMP_KICK)
		atk_hits.clear()
	if air_attack and stage != null:
		stage.resolve_hits(self, atk)
	if is_grounded():
		air_attack = false
		set_state(State.IDLE)


func _tick_attack(f: InputFrame, dt: float) -> void:
	vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
	if atk.has("dash") and attack_is_active():
		vel = Vector2(facing * float(atk["dash"]), 0.0)
	_move(dt)
	if attack_is_active() and stage != null:
		stage.resolve_hits(self, atk)
	var total := attack_total_frames()
	if f.just_pressed(InputFrame.ATTACK) and state_frames >= total - COMBO_BUFFER_FRAMES:
		buffered_attack = true
	if state_frames >= total:
		var chain := buffered_attack and combo_hits_this_attack > 0 \
			and atk.has("combo") and combo_step < Roster.COMBO.size() - 1
		buffered_attack = false
		if chain:
			combo_step += 1
			_start_combo_hit()
		else:
			combo_step = 0
			set_state(State.IDLE)


func _tick_grab(f: InputFrame) -> void:
	var t := grab_target
	if t == null or not t.is_alive() or state_frames > GRAB_MAX_FRAMES:
		release_grab()
		return
	t.position = position + Vector2(facing * 18.0, 0.5)
	t.facing = -facing
	if f.just_pressed(InputFrame.ATTACK):
		if f.move.x * facing < -0.5:
			_throw(true)
		else:
			knees += 1
			var dmg := float(Roster.KNEE["damage"]) * damage_multiplier()
			if t.take_hit(self, Roster.KNEE, dmg):
				on_hit_landed(t, dmg)
			if knees >= 3 and grab_target != null:
				_throw(false)


# --- moves -------------------------------------------------------------------

func _start_combo_hit() -> void:
	var data := _scaled(Roster.COMBO[combo_step])
	data["combo"] = true
	combo_hits_this_attack = 0
	start_attack(data)


func _start_special() -> void:
	var sp: Dictionary = def["special"]
	var cost := float(sp["cost"]) * float(mods["special_cost"])
	cost = minf(cost, hp - 1.0)
	hp -= cost
	if float(mods["no_green"]) == 0.0:
		green_hp += cost
	var data := _scaled(sp)
	var kind := str(sp["kind"])
	data["area"] = "around" if kind == "around" or kind == "slam" else "front"
	invuln = int(sp["startup"]) + int(sp["active"])
	combo_hits_this_attack = 0
	start_attack(data)


func _start_star() -> void:
	sparks -= 1
	var data: Dictionary = Roster.STAR_MOVE.duplicate()
	invuln = attack_total_frames_for(data)
	combo_hits_this_attack = 0
	start_attack(data)
	if stage != null:
		stage.on_star_move(self)


func _begin_grab(t: Fighter) -> void:
	grab_hold = 0
	knees = 0
	grab_target = t
	vel = Vector2.ZERO
	t.get_grabbed(self)
	set_state(State.GRAB)


func _throw(backwards: bool) -> void:
	var t := grab_target
	grab_target = null
	if backwards:
		facing = -facing
	t.grabbed_by = null
	t.position = position + Vector2(facing * 14.0, 0.5)
	t.thrown = true
	t.launch(facing * 260.0, 230.0)
	set_state(State.IDLE)
	if stage != null:
		stage.register_combo_hit(self)


func _scaled(src: Dictionary) -> Dictionary:
	var data := src.duplicate()
	if data.has("reach"):
		data["reach"] = float(data["reach"]) * reach_mult
	return data


func attack_total_frames_for(data: Dictionary) -> int:
	return int(data.get("startup", 0)) + int(data.get("active", 0)) + int(data.get("recovery", 0))


## Switches between IDLE and WALK without resetting the frame counter.
func set_state_keep_frames(new_state: State) -> void:
	if state != new_state:
		state = new_state
