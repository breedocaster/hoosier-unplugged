class_name PlayerSlot
extends RefCounted
## One of the four player seats. Owned by the Players autoload.
##
## EMPTY -> (press START on any free device) -> SELECTING
## SELECTING -> (left/right picks a fighter, ATTACK confirms) -> PLAYING
## PLAYING -> (hold BACK, or controller unplugged past the grace period) -> EMPTY

enum State { EMPTY, SELECTING, PLAYING }

const PLAYER_COLORS := [
	Color(0.93, 0.27, 0.27),
	Color(0.28, 0.55, 0.98),
	Color(0.33, 0.85, 0.42),
	Color(0.98, 0.82, 0.25),
]

var index: int = 0
var state: State = State.EMPTY
## "kb0", "kb1", "joy3", "touch", "script:p1", later "net:<peer>:<n>".
var device: String = ""
var character_index: int = 0
## The PlayerFighter in the current stage, or null. Typed as Node to keep
## this data class free of scene dependencies.
var fighter: Node = null
## -1 means unlimited (Story / Chill).
var lives: int = -1
var score: int = 0
var boons: Array[String] = []
var drop_hold: int = 0
var disconnect_timer: int = 0
var menu_cooldown: int = 0


func color() -> Color:
	return PLAYER_COLORS[index % PLAYER_COLORS.size()]


func label() -> String:
	return "P%d" % (index + 1)


func clear() -> void:
	state = State.EMPTY
	device = ""
	fighter = null
	lives = -1
	score = 0
	boons.clear()
	drop_hold = 0
	disconnect_timer = 0
	menu_cooldown = 0
