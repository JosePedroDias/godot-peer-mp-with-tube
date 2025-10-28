class_name PeerData
extends RefCounted

const THRUST_SAMPLES: int = 20
const BODY_DROT_SANPLES: int = 10

var _thrust_buf: Array[float] = [0]
var _barrel_drot_buf: Array[float] = [0]
var _last_thrust: float = 0
var _last_barrel_drot: float = 0

var thrust: float = 0: # forward
	get:
		var v: float = 0
		for i in _thrust_buf: v += i
		return v / float(_thrust_buf.size())
	set(v):
		_last_thrust = v
		
var body_drot: float = 0: # to the right
	get:
		var v: float = 0
		for i in _barrel_drot_buf: v += i
		return v / float(_barrel_drot_buf.size())
	set(v):
		_last_barrel_drot = v

var barrel_drot: float = 0 # barrel rot

func bump() -> void:
		if _thrust_buf.size() == THRUST_SAMPLES: _thrust_buf.pop_front()
		_thrust_buf.append(_last_thrust)
		
		if _barrel_drot_buf.size() == BODY_DROT_SANPLES: _barrel_drot_buf.pop_front()
		_barrel_drot_buf.append(_last_barrel_drot)

func _to_string() -> String:
	return "thrust: " + str(thrust) + ", body_dr: " + str(body_drot) + ", barrel_dr:" + str(barrel_drot)
