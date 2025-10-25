class_name PeerData
extends RefCounted

var dx: float = 0
var dy: float = 0
var dr: float = 0
var energy_left: float = 100

func _to_string() -> String:
	return "delta " + str(dx) + "," + str(dy) + ", " + str(dr) + ", energy: " + str(energy_left)
