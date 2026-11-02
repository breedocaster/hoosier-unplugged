class_name StageBackdrop
extends Node2D
## Graybox backdrop for "Main Street Mayhem": small-town square at night,
## sliding into a StratoStack construction site and server campus.
## Pure vector placeholder until real pixel art exists.

var length: float = 2600.0


func _draw() -> void:
	var h := 360.0
	# Night sky bands.
	draw_rect(Rect2(-100, 0, length + 200, 140), Color(0.07, 0.07, 0.16))
	draw_rect(Rect2(-100, 140, length + 200, 90), Color(0.1, 0.09, 0.2))
	# Moon.
	draw_circle(Vector2(180, 52), 18.0, Color(0.95, 0.93, 0.8))

	# Main Street storefronts (first ~1600px).
	var x := -100.0
	var i := 0
	while x < 1700.0:
		var w := 70.0 + float((i * 37) % 50)
		var bh := 90.0 + float((i * 53) % 70)
		var col := Color(0.2, 0.16, 0.18).lerp(Color(0.25, 0.2, 0.15), float(i % 3) / 2.0)
		draw_rect(Rect2(x, 232 - bh, w - 4.0, bh), col)
		for wy in range(int(232 - bh + 10), 220, 18):
			for wx in range(int(x + 8), int(x + w - 14), 16):
				var lit := ((wx * 7 + wy * 13) % 5) < 2
				draw_rect(Rect2(wx, wy, 8, 10),
					Color(1.0, 0.85, 0.45, 0.9) if lit else Color(0.1, 0.1, 0.14))
		x += w
		i += 1

	# Courthouse with clock tower.
	draw_rect(Rect2(700, 120, 220, 112), Color(0.32, 0.3, 0.27))
	draw_rect(Rect2(780, 60, 60, 60), Color(0.35, 0.33, 0.3))
	draw_circle(Vector2(810, 88), 16.0, Color(0.9, 0.88, 0.75))
	for c in 6:
		draw_rect(Rect2(712 + c * 36, 150, 10, 82), Color(0.45, 0.43, 0.4))

	# Construction fence + StratoStack sign.
	draw_rect(Rect2(1700, 170, 900, 62), Color(0.16, 0.18, 0.2))
	for p in range(1700, 2600, 24):
		draw_line(Vector2(p, 170), Vector2(p + 24, 232), Color(0.3, 0.32, 0.35), 1.0)
		draw_line(Vector2(p + 24, 170), Vector2(p, 232), Color(0.3, 0.32, 0.35), 1.0)
	draw_rect(Rect2(1760, 96, 230, 60), Color(0.9, 0.9, 0.95))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(1772, 122), "STRATOSTACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
		Color(0.15, 0.2, 0.45))
	draw_string(font, Vector2(1772, 144), "Future home of Project Cornfield",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.3, 0.35))
	# Server campus silhouette with blinking aviation lights.
	draw_rect(Rect2(2150, 60, 420, 172), Color(0.12, 0.13, 0.16))
	for r in 8:
		draw_rect(Rect2(2170, 74 + r * 18, 380, 3), Color(0.25, 0.85, 1.0, 0.35))

	# Ground: sidewalk, curb, road, lane dashes.
	draw_rect(Rect2(-100, 232, length + 200, 16), Color(0.42, 0.42, 0.45))
	draw_rect(Rect2(-100, 248, length + 200, 4), Color(0.6, 0.6, 0.6))
	draw_rect(Rect2(-100, 252, length + 200, h - 252), Color(0.2, 0.2, 0.23))
	for d in range(-100, int(length) + 100, 64):
		draw_rect(Rect2(d, 300, 32, 3), Color(0.85, 0.78, 0.3))
	# Corn rows at the very end: what's left of the farm.
	for k in range(2300, int(length) + 100, 10):
		draw_line(Vector2(k, 232), Vector2(k - 3, 205), Color(0.3, 0.45, 0.2), 2.0)
