class_name GameState
extends Node
## Session settings shared by every scene: mode, difficulty, RNG, team currency.
## Autoloaded as `Game`.

enum Mode { STORY, ARCADE, ROLLBACK }

## lives: -1 = unlimited. Story always respawns; Arcade uses lives + continues.
const DIFFICULTIES := {
	"chill": {"label": "Chill", "enemy_damage": 0.5, "enemy_hp": 0.8, "lives": -1,
		"respawn_frames": 60},
	"normal": {"label": "Normal", "enemy_damage": 1.0, "enemy_hp": 1.0, "lives": 3,
		"respawn_frames": 90},
	"hard": {"label": "Hoosier Hard", "enemy_damage": 1.4, "enemy_hp": 1.25, "lives": 2,
		"respawn_frames": 120},
}

var mode: Mode = Mode.STORY
var difficulty: String = "chill"
var boons_enabled: bool = true
var watts: int = 0
var continues_used: int = 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Fixed seed keeps the prototype and the smoke test reproducible.
	rng.seed = 1816


func setting(key: String) -> float:
	var table: Dictionary = DIFFICULTIES[difficulty]
	return float(table[key])


func lives_per_player() -> int:
	var lives := int(setting("lives"))
	if mode == Mode.STORY:
		# Story mode never ends your run; lives only matter for score.
		return -1
	if lives < 0:
		return 3
	return lives


func mode_label() -> String:
	match mode:
		Mode.STORY:
			return "STORY"
		Mode.ARCADE:
			return "ARCADE"
		Mode.ROLLBACK:
			return "ROLLBACK RUN"
	return "?"


func reset_run() -> void:
	watts = 0
	continues_used = 0
	rng.seed = 1816
