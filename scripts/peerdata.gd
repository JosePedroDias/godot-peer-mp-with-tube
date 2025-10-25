class_name PeerData
extends RefCounted

var dx: float = 0
var dy: float = 0

func _to_string() -> String:
	return "delta " + str(dx) + "," + str(dy)
