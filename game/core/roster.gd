class_name Roster
extends RefCounted
## All tunable data in one place: heroes, attacks, enemies, boons, pickups.
## Frame counts assume 60 physics ticks per second.
## Placeholder numbers - tune by feel once real animations exist.

## Shared three-hit ground string. A hit has to connect to advance the chain
## (Final Fight rule), otherwise you repeat the jab.
const COMBO := [
	{"startup": 4, "active": 3, "recovery": 9, "damage": 4.0, "reach": 30.0,
		"hitstun": 16, "push": 40.0},
	{"startup": 4, "active": 3, "recovery": 10, "damage": 5.0, "reach": 30.0,
		"hitstun": 18, "push": 50.0},
	{"startup": 6, "active": 4, "recovery": 18, "damage": 8.0, "reach": 34.0,
		"hitstun": 0, "push": 170.0, "launch": true},
]

const JUMP_KICK := {"startup": 0, "active": 999, "recovery": 0, "damage": 7.0,
	"reach": 30.0, "hitstun": 0, "push": 150.0, "launch": true}

const KNEE := {"damage": 4.0, "hitstun": 20, "push": 0.0}

const STAR_MOVE := {"startup": 24, "active": 2, "recovery": 24, "damage": 30.0,
	"area": "screen", "hitstun": 0, "push": 120.0, "launch": true}

## Elements double as the boon "spirits" (see docs/GDD.md).
const ELEMENT_COLORS := {
	"current": Color(0.35, 0.8, 1.0),
	"juice": Color(1.0, 0.45, 0.75),
	"stone": Color(0.75, 0.72, 0.62),
	"water": Color(0.25, 0.5, 0.95),
	"wind": Color(0.75, 0.95, 0.85),
	"grow": Color(0.4, 0.85, 0.3),
	"corp": Color(0.6, 0.6, 0.65),
}

## Special "kind" drives how the move behaves (see PlayerFighter._start_special).
const CHARACTERS := [
	{
		"id": "kurt", "name": "KURT", "title": "The Breaker", "element": "current",
		"color": Color(0.85, 0.3, 0.2), "hp": 110.0, "speed": 120.0, "jump": 430.0,
		"damage": 1.0, "reach": 1.0,
		"special": {"name": "Power Chord", "kind": "around", "cost": 8.0, "startup": 8,
			"active": 6, "recovery": 18, "damage": 11.0, "reach": 56.0, "depth": 22.0,
			"hitstun": 0, "push": 200.0, "launch": true},
		"star": "Loop Pedal",
	},
	{
		"id": "juicejam", "name": "JUICEJAM", "title": "Low End Theory", "element": "juice",
		"color": Color(0.85, 0.2, 0.6), "hp": 120.0, "speed": 108.0, "jump": 400.0,
		"damage": 1.15, "reach": 1.15,
		"special": {"name": "Drop the Bass", "kind": "slam", "cost": 10.0, "startup": 14,
			"active": 6, "recovery": 20, "damage": 14.0, "reach": 64.0, "depth": 26.0,
			"hitstun": 0, "push": 150.0, "launch": true},
		"star": "Rhythm Section",
	},
	{
		"id": "lou", "name": "LIMESTONE LOU", "title": "Quarry Hand", "element": "stone",
		"color": Color(0.6, 0.55, 0.45), "hp": 140.0, "speed": 92.0, "jump": 380.0,
		"damage": 1.3, "reach": 0.95,
		"special": {"name": "Quarry Drop", "kind": "slam", "cost": 10.0, "startup": 16,
			"active": 6, "recovery": 22, "damage": 16.0, "reach": 48.0, "depth": 22.0,
			"hitstun": 0, "push": 120.0, "launch": true},
		"star": "Cornerstone",
	},
	{
		"id": "wren", "name": "WABASH WREN", "title": "River Guide", "element": "water",
		"color": Color(0.2, 0.5, 0.85), "hp": 100.0, "speed": 118.0, "jump": 420.0,
		"damage": 0.95, "reach": 1.35,
		"special": {"name": "Paddle Sweep", "kind": "front", "cost": 7.0, "startup": 7,
			"active": 6, "recovery": 16, "damage": 9.0, "reach": 72.0, "depth": 20.0,
			"hitstun": 30, "push": 90.0},
		"star": "Flash Flood",
	},
	{
		"id": "tess", "name": "TURBINE TESS", "title": "Wind Tech", "element": "wind",
		"color": Color(0.85, 0.85, 0.85), "hp": 95.0, "speed": 135.0, "jump": 480.0,
		"damage": 0.95, "reach": 1.0,
		"special": {"name": "Updraft", "kind": "rush", "cost": 7.0, "startup": 5,
			"active": 14, "recovery": 14, "damage": 8.0, "reach": 30.0, "depth": 16.0,
			"hitstun": 0, "push": 80.0, "launch": true, "dash": 300.0},
		"star": "Derecho",
	},
	{
		"id": "prairie", "name": "PRAIRIE", "title": "Restoration Crew", "element": "grow",
		"color": Color(0.45, 0.7, 0.25), "hp": 100.0, "speed": 115.0, "jump": 420.0,
		"damage": 0.9, "reach": 1.1,
		"special": {"name": "Root Snare", "kind": "front", "cost": 6.0, "startup": 10,
			"active": 8, "recovery": 16, "damage": 5.0, "reach": 90.0, "depth": 30.0,
			"hitstun": 90, "push": 0.0},
		"star": "Bloom",
	},
]

## Enemy archetypes. hp/damage get scaled by difficulty and player count.
const ENEMIES := {
	"rackbot": {"name": "RACKBOT", "hp": 28.0, "speed": 62.0, "damage": 6.0,
		"reach": 26.0, "startup": 16, "active": 4, "recovery": 22, "watts": 5,
		"color": Color(0.32, 0.36, 0.45), "led": Color(0.3, 0.9, 1.0),
		"height": 44.0, "half_width": 10.0},
	"rackbot_red": {"name": "RACKBOT-R", "hp": 34.0, "speed": 76.0, "damage": 8.0,
		"reach": 26.0, "startup": 11, "active": 4, "recovery": 18, "watts": 8,
		"color": Color(0.42, 0.24, 0.26), "led": Color(1.0, 0.25, 0.25),
		"height": 44.0, "half_width": 10.0},
	"fanboy": {"name": "FANBOY", "hp": 18.0, "speed": 95.0, "damage": 4.0,
		"reach": 24.0, "startup": 8, "active": 3, "recovery": 14, "watts": 4,
		"color": Color(0.5, 0.52, 0.55), "led": Color(1.0, 0.9, 0.3),
		"height": 30.0, "half_width": 9.0, "hover": 18.0},
	"server_brute": {"name": "SERVER BRUTE", "hp": 220.0, "speed": 44.0, "damage": 14.0,
		"reach": 44.0, "startup": 24, "active": 6, "recovery": 30, "watts": 60,
		"color": Color(0.16, 0.17, 0.2), "led": Color(0.95, 0.3, 0.95),
		"height": 68.0, "half_width": 18.0, "armor": true, "boss": true, "area": "around"},
}

const PICKUPS := {
	"corn": {"name": "Sweet Corn", "heal": 20.0},
	"tenderloin": {"name": "Pork Tenderloin", "heal": 60.0},
	"pie": {"name": "Sugar Cream Pie", "heal": 999.0},
	"spark": {"name": "Spark", "sparks": 1},
	"watts": {"name": "Watts", "watts": 10},
}

## Roguelite boons. Multipliers stack multiplicatively; flags are 0/1.
const BOONS := {
	"live_wire": {"name": "Live Wire", "element": "current",
		"desc": "3rd combo hit arcs to another enemy", "mods": {"chain_zap": 1.0}},
	"bass_boost": {"name": "Bass Boost", "element": "juice",
		"desc": "Specials cost 40% less health", "mods": {"special_cost": 0.6}},
	"bedrock": {"name": "Bedrock", "element": "stone",
		"desc": "Take 20% less damage", "mods": {"damage_taken": 0.8}},
	"rain_barrel": {"name": "Rain Barrel", "element": "water",
		"desc": "Food heals 50% more", "mods": {"food": 1.5}},
	"tailwind": {"name": "Tailwind", "element": "wind",
		"desc": "Move 20% faster", "mods": {"speed": 1.2}},
	"second_growth": {"name": "Second Growth", "element": "grow",
		"desc": "Win back green health 2x faster", "mods": {"green_recover": 2.0}},
	"terms_and_conditions": {"name": "Terms & Conditions", "element": "corp",
		"desc": "+40% damage, but no green health", "mods": {"damage": 1.4, "no_green": 1.0}},
}


static func character(index: int) -> Dictionary:
	return CHARACTERS[posmod(index, CHARACTERS.size())]


static func character_count() -> int:
	return CHARACTERS.size()
