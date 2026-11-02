class_name Pickup
extends Node2D
## Food, Sparks and Watts lying on the street. Walk over it to take it.

const PICKUP_RADIUS := 16.0
const LIFETIME_FRAMES := 1200

var kind: String = "corn"
var age: int = 0
var taken: bool = false


func tick(stage: BrawlStage) -> void:
	age += 1
	if taken:
		return
	for p in stage.player_fighters():
		if not p.is_alive() or not p.is_grounded():
			continue
		var d := p.position - position
		if absf(d.x) < PICKUP_RADIUS and absf(d.y) < 10.0:
			_apply(p, stage)
			return
	if age > LIFETIME_FRAMES:
		taken = true
		queue_free()
	queue_redraw()


func _apply(p: PlayerFighter, stage: BrawlStage) -> void:
	var data: Dictionary = Roster.PICKUPS[kind]
	if data.has("heal"):
		p.heal(float(data["heal"]))
	if data.has("sparks"):
		p.sparks += int(data["sparks"])
	if data.has("watts"):
		Game.watts += int(data["watts"])
		p.slot.score += 100
	stage.announce("%s  %s" % [p.slot.label(), str(data["name"]).to_upper()], 50)
	taken = true
	queue_free()


func _draw() -> void:
	if age > LIFETIME_FRAMES - 180 and (age / 6) % 2 == 0:
		return
	match kind:
		"corn":
			draw_rect(Rect2(-3, -12, 6, 12), Color(1.0, 0.85, 0.3))
			draw_rect(Rect2(-5, -6, 3, 6), Color(0.4, 0.75, 0.3))
		"tenderloin":
			draw_circle(Vector2(0, -5), 9.0, Color(0.85, 0.6, 0.3))
			draw_circle(Vector2(0, -5), 4.0, Color(0.95, 0.85, 0.6))
		"pie":
			draw_rect(Rect2(-8, -6, 16, 6), Color(0.75, 0.5, 0.25))
			draw_rect(Rect2(-7, -8, 14, 3), Color(1.0, 0.95, 0.8))
		"spark":
			var pts := PackedVector2Array([Vector2(0, -14), Vector2(4, -7), Vector2(0, 0), Vector2(-4, -7)])
			draw_colored_polygon(pts, Color(1.0, 0.95, 0.3))
		_:
			draw_circle(Vector2(0, -5), 5.0, Color(0.4, 0.9, 1.0))
