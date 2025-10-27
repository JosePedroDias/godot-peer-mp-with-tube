class_name PeerData
extends Resource

@export var thrust: float = 0 # forward
@export var body_drot: float = 0 # to the right
@export var barrel_drot: float = 0 # barrel rot

func _to_string() -> String:
	return "thrust: " + str(thrust) + ", body_dr: " + str(body_drot) + ", barrel_dr:" + str(barrel_drot)
