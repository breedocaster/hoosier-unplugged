class_name Fighter
extends Node2D
## Base for anything that can hit or be hit on the belt.
##
## Coordinates: node position = point on the ground (x = scroll, y = depth).
## `z` is height above the ground; the body is drawn at (0, -z) so the
## parent's y-sort orders everyone by depth. The stage calls tick() in a fixed
## order every physics frame (no per-node _physics_process) to keep the
## simulation deterministic, which online play will need later.

enum State { IDLE, WALK, JUMP, ATTACK, GRAB, GRABBED, HITSTUN, AIRBORNE, DOWN, GETUP, DEAD, SPAWN }

const GRAVITY := 1400.0
const DEPTH_TOLERANCE := 14.0
const DOWN_FRAMES := 40
const GETUP_FRAMES := 20
const DEAD_FRAMES := 60

## 0 = players, 1 = enemies, 2 = neutral breakables.
var team: int = 0
var display_name: String = ""
var body_color := Color.WHITE
var accent_color := Color.WHITE
var max_hp: float = 100.0
var hp: float = 100.0
## Health spent on specials that can be won back by landing hits (SoR4 rule).
var green_hp: float = 0.0
var z: float = 0.0
var vz: float = 0.0
var vel := Vector2.ZERO
var facing: int = 1
var state: State = State.IDLE
var state_frames: int = 0
var invuln: int = 0
var flash: int = 0
var height: float = 44.0
var half_width: float = 10.0
var super_armor: bool = false
var thrown: bool = false
var removed: bool = false
## Attack in progress (one of the dictionaries in Roster).
var atk: Dictionary = {}
var atk_hits: Array[int] = []
var grabbed_by: Fighter = null
var grab_target: Fighter = null

var stage: BrawlStage = null


func tick(_dt: float) -> void:
	pass


func is_alive() -> bool:
	return state != State.DEAD and hp > 0.0 and not removed


func is_grounded() -> bool:
	return z <= 0.0


func can_be_grabbed() -> bool:
	return is_grounded() and (state == State.IDLE or state == State.WALK
		or state == State.HITSTUN)


func set_state(new_state: State) -> void:
	state = new_state
	state_frames = 0


func start_attack(data: Dictionary) -> void:
	atk = data
	atk_hits.clear()
	set_state(State.ATTACK)


func attack_total_frames() -> int:
	return int(atk.get("startup", 0)) + int(atk.get("active", 0)) + int(atk.get("recovery", 0))


func attack_is_active() -> bool:
	var startup := int(atk.get("startup", 0))
	return state_frames >= startup and state_frames < startup + int(atk.get("active", 0))


func damage_multiplier() -> float:
	return 1.0


func on_hit_landed(_target: Fighter, _damage: float) -> void:
	pass


## Returns true if the hit connected.
func take_hit(attacker: Fighter, data: Dictionary, damage: float) -> bool:
	if invuln > 0 or not is_alive():
		return false
	hp -= damage
	green_hp = 0.0
	flash = 6
	var dir := 1.0
	if attacker != null:
		dir = 1.0 if position.x >= attacker.position.x else -1.0
		facing = -int(dir)
	if grab_target != null:
		release_grab()
	if state == State.GRABBED and grabbed_by != null and grabbed_by == attacker:
		# Knees while held: hurt, but stay held.
		if hp <= 0.0:
			grabbed_by.release_grab()
			launch(dir * 120.0, 220.0)
		return true
	if grabbed_by != null:
		grabbed_by.release_grab()
	var push := float(data.get("push", 40.0))
	var launches := bool(data.get("launch", false)) or int(data.get("hitstun", 0)) == 0
	if hp <= 0.0:
		launch(dir * maxf(push, 120.0), 260.0)
	elif super_armor and state == State.ATTACK:
		pass
	elif launches:
		launch(dir * push, 260.0)
	else:
		set_state(State.HITSTUN)
		vel = Vector2(dir * push, 0.0)
		state_frames = -int(data.get("hitstun", 14))
	return true


func launch(x_speed: float, up_speed: float) -> void:
	set_state(State.AIRBORNE)
	vel = Vector2(x_speed, 0.0)
	vz = up_speed
	z = maxf(z, 1.0)


func get_grabbed(by: Fighter) -> void:
	grabbed_by = by
	vel = Vector2.ZERO
	set_state(State.GRABBED)


func release_grab() -> void:
	if grab_target != null:
		var t := grab_target
		grab_target = null
		if t.state == State.GRABBED:
			t.grabbed_by = null
			t.set_state(State.HITSTUN)
			t.state_frames = -10
	if state == State.GRAB:
		set_state(State.IDLE)


## Advances timers and runs the "not in control" states. Subclasses call this
## first every tick; it returns true if it handled the frame, so they only
## drive IDLE / WALK / JUMP / ATTACK / GRAB themselves.
func tick_common(dt: float) -> bool:
	state_frames += 1
	if invuln > 0:
		invuln -= 1
	if flash > 0:
		flash -= 1
	match state:
		State.HITSTUN:
			vel = vel.move_toward(Vector2.ZERO, 600.0 * dt)
			_move(dt)
			if state_frames >= 0:
				set_state(State.IDLE)
			return true
		State.AIRBORNE:
			_air_physics(dt)
			if is_grounded():
				_on_landed_hard()
			return true
		State.DOWN:
			vel = Vector2.ZERO
			if state_frames >= DOWN_FRAMES:
				if hp <= 0.0:
					set_state(State.DEAD)
				else:
					set_state(State.GETUP)
					invuln = GETUP_FRAMES + 10
			return true
		State.GETUP:
			if state_frames >= GETUP_FRAMES:
				set_state(State.IDLE)
			return true
		State.DEAD:
			if state_frames >= DEAD_FRAMES:
				on_dead_finished()
			return true
		State.GRABBED:
			if grabbed_by == null or not grabbed_by.is_alive():
				grabbed_by = null
				set_state(State.IDLE)
			return true
	return false


func on_dead_finished() -> void:
	if removed:
		return
	removed = true
	if stage != null:
		stage.on_fighter_removed(self)


func _air_physics(dt: float) -> void:
	vz -= GRAVITY * dt
	z += vz * dt
	_move(dt)
	if z <= 0.0:
		z = 0.0


func _on_landed_hard() -> void:
	if thrown and stage != null:
		thrown = false
		hp -= 10.0
		flash = 6
	thrown = false
	vel = Vector2.ZERO
	set_state(State.DOWN)


func _move(dt: float) -> void:
	position += vel * dt
	if stage != null:
		stage.clamp_fighter(self)


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	if removed:
		return
	# Shadow stays on the ground.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, half_width + 4.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if invuln > 0 and (invuln / 3) % 2 == 0 and state != State.DEAD:
		return
	if state == State.DEAD and (state_frames / 4) % 2 == 0:
		return
	var col := body_color
	if flash > 0:
		col = Color.WHITE
	if state == State.DOWN or state == State.DEAD:
		_draw_lying(col)
	else:
		_draw_standing(col)


func _draw_standing(col: Color) -> void:
	var top := -z - height
	var w := half_width * 2.0
	# Legs, torso, head.
	draw_rect(Rect2(-half_width, -z - height * 0.4, w * 0.4, height * 0.4), col.darkened(0.3))
	draw_rect(Rect2(half_width * 0.2, -z - height * 0.4, w * 0.4, height * 0.4), col.darkened(0.3))
	draw_rect(Rect2(-half_width, top + height * 0.25, w, height * 0.4), col)
	draw_circle(Vector2(0, top + height * 0.13), half_width * 0.75, col.lightened(0.15))
	# Eye/visor on the facing side.
	draw_rect(Rect2(facing * half_width * 0.25 - 2.0, top + height * 0.1, 4.0, 3.0), accent_color)
	# Arm: extended while an attack is live.
	var arm_y := top + height * 0.38
	var arm_len := half_width * 0.6
	if state == State.ATTACK and attack_is_active():
		arm_len = float(atk.get("reach", 26.0)) * 0.8
	elif state == State.GRAB:
		arm_len = 14.0
	var arm_x := 0.0 if facing > 0 else -arm_len
	draw_rect(Rect2(arm_x, arm_y, arm_len, 5.0), col.lightened(0.25))


func _draw_lying(col: Color) -> void:
	draw_rect(Rect2(-height * 0.5, -z - half_width, height, half_width * 1.2), col.darkened(0.15))
	draw_circle(Vector2(-facing * height * 0.5, -z - half_width * 0.4), half_width * 0.6, col)
