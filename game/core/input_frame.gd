class_name InputFrame
extends RefCounted
## One tick of input for one player.
##
## Every input source (keyboard scheme, gamepad, touch overlay, test script,
## and later a network peer) is turned into one of these per physics tick.
## Gameplay code only ever reads InputFrames, so online play becomes
## "send frames over the wire" instead of a rewrite.

const ATTACK := 1
const JUMP := 2
const SPECIAL := 4
const STAR := 8
const START := 16
const BACK := 32

var move := Vector2.ZERO
var held: int = 0
var pressed: int = 0


func is_held(button: int) -> bool:
	return (held & button) != 0


func just_pressed(button: int) -> bool:
	return (pressed & button) != 0


func to_dict() -> Dictionary:
	return {"mx": move.x, "my": move.y, "held": held}


static func from_values(move_value: Vector2, held_value: int) -> InputFrame:
	var f := InputFrame.new()
	f.move = move_value.limit_length(1.0)
	f.held = held_value
	return f
