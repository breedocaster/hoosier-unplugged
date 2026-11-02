class_name EnemyFighter
extends Fighter
## StratoStack security: Rackbots, Fanboys and the Server Brute.
##
## AI: pick the nearest hero, walk to a spot beside them, and only attack when
## the stage hands out an "attack token" (max 2 attackers per hero). Tokens
## are the classic trick that keeps big co-op crowds from feeling unfair.

const RETARGET_FRAMES := 30
const CIRCLE_DISTANCE := 80.0

var kind: String = "rackbot"
var def: Dictionary = {}
var speed: float = 60.0
var damage: float = 6.0
var watts: int = 5
var hover: float = 0.0
var is_boss: bool = false
var target: PlayerFighter = null
var cooldown: int = 0
var retarget: int = 0


func setup(p_kind: String, hp_scale: float, damage_scale: float) -> void:
	kind = p_kind
	def = Roster.ENEMIES[kind]
	team = 1
	display_name = str(def["name"])
	body_color = def["color"]
	accent_color = def["led"]
	max_hp = float(def["hp"]) * hp_scale
	hp = max_hp
	speed = float(def["speed"])
	damage = float(def["damage"]) * damage_scale
	watts = int(def["watts"])
	height = float(def["height"])
	half_width = float(def["half_width"])
	hover = float(def.get("hover", 0.0))
	is_boss = bool(def.get("boss", false))
	super_armor = bool(def.get("armor", false))
	cooldown = Game.rng.randi_range(20, 60)


func tick(dt: float) -> void:
	if tick_common(dt):
		return
	if cooldown > 0:
		cooldown -= 1
	match state:
		State.IDLE, State.WALK:
			_think(dt)
		State.ATTACK:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			_move(dt)
			if attack_is_active() and stage != null:
				stage.resolve_hits(self, atk)
			if state_frames >= attack_total_frames():
				cooldown = Game.rng.randi_range(40, 100) if not is_boss else 50
				set_state(State.IDLE)
		_:
			set_state(State.IDLE)
	z = hover if state != State.AIRBORNE else z


func damage_multiplier() -> float:
	return 1.0


func on_dead_finished() -> void:
	if stage != null and not removed:
		stage.on_enemy_defeated(self)
	super.on_dead_finished()


func _think(dt: float) -> void:
	retarget -= 1
	if retarget <= 0 or target == null or not target.is_alive():
		retarget = RETARGET_FRAMES
		target = stage.nearest_player(self) if stage != null else null
	if target == null:
		vel = Vector2.ZERO
		state = State.IDLE
		return

	var dx := target.position.x - position.x
	var side := -1.0 if dx > 0.0 else 1.0
	facing = 1 if dx > 0.0 else -1
	var reach := float(def["reach"])
	var dy := target.position.y - position.y
	var in_range := absf(dx) <= reach + target.half_width + 4.0 and absf(dy) <= 8.0

	if in_range and cooldown <= 0 and stage.request_attack_token(self, target):
		_attack()
		return

	# Stand beside the target if we hold a token slot, otherwise circle wide.
	var spot_distance := reach * 0.8 + target.half_width
	if not stage.has_attack_room(target):
		spot_distance = CIRCLE_DISTANCE
	var spot := target.position + Vector2(side * spot_distance, 0.0)
	var to_spot := spot - position
	if to_spot.length() > 4.0:
		vel = to_spot.normalized() * speed
		vel.y *= 0.7
		state = State.WALK
	else:
		vel = Vector2.ZERO
		state = State.IDLE
	_move(dt)


func _attack() -> void:
	var data := {
		"startup": int(def["startup"]),
		"active": int(def["active"]),
		"recovery": int(def["recovery"]),
		"damage": damage,
		"reach": float(def["reach"]),
		"hitstun": 18,
		"push": 70.0,
		"area": str(def.get("area", "front")),
	}
	if is_boss:
		data["launch"] = true
		data["push"] = 180.0
		data["depth"] = 22.0
	vel = Vector2.ZERO
	start_attack(data)


func _draw_standing(col: Color) -> void:
	super._draw_standing(col)
	# Rack LEDs so Rackbots read as servers even as gray boxes.
	var top := -z - height
	for i in 3:
		var led := accent_color if (Engine.get_physics_frames() / 8 + i) % 3 != 0 \
			else accent_color.darkened(0.6)
		draw_rect(Rect2(-half_width + 3.0 + i * 5.0, top + height * 0.3, 3.0, 2.0), led)
	if state == State.ATTACK and not attack_is_active() and state_frames < int(atk.get("startup", 0)):
		# Telegraph: wind-up flash.
		draw_circle(Vector2(facing * half_width, top + height * 0.4), 3.0, Color(1, 1, 1, 0.8))
