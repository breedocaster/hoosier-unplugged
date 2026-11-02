class_name Breakable
extends Fighter
## Smashable scenery (the Final Fight oil drum). Drops a pickup when broken.

var drop: String = "corn"
var label_text: String = "SERVER"


func setup(p_drop: String, p_label: String) -> void:
	team = 2
	drop = p_drop
	label_text = p_label
	display_name = p_label
	max_hp = 8.0
	hp = max_hp
	height = 34.0
	half_width = 12.0
	body_color = Color(0.18, 0.2, 0.24)
	accent_color = Color(0.3, 1.0, 0.5)


func tick(dt: float) -> void:
	if tick_common(dt):
		return
	vel = Vector2.ZERO


func take_hit(attacker: Fighter, _data: Dictionary, damage: float) -> bool:
	if not is_alive():
		return false
	hp -= damage
	flash = 6
	if hp <= 0.0:
		set_state(State.DEAD)
		if stage != null:
			stage.spawn_pickup(drop, position + Vector2(0, 2))
	elif attacker != null:
		position.x += 2.0 if attacker.position.x < position.x else -2.0
	return true


func _draw() -> void:
	if removed:
		return
	if state == State.DEAD and (state_frames / 3) % 2 == 0:
		return
	var col := Color.WHITE if flash > 0 else body_color
	draw_rect(Rect2(-half_width, -height, half_width * 2.0, height), col)
	draw_rect(Rect2(-half_width, -height, half_width * 2.0, height), Color(0.5, 0.55, 0.6), false, 1.0)
	for row in 4:
		var on := (Engine.get_physics_frames() / 10 + row) % 4 != 0
		draw_rect(Rect2(-half_width + 3.0, -height + 5.0 + row * 7.0, 3.0, 2.0),
			accent_color if on else accent_color.darkened(0.7))
