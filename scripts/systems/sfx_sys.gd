class_name SfxSys
extends Node

enum Sfx { FIRE, HIT, MOVE }

@onready var _fire_pl: AudioStreamPlayer = $FirePlayer
@onready var _hit_pl: AudioStreamPlayer = $HitPlayer
@onready var _move_pl: AudioStreamPlayer = $MovePlayer

func play(sfx: Sfx) -> void:
	match sfx:
		Sfx.FIRE: _fire_pl.play()
		Sfx.HIT: _hit_pl.play()
		_: _move_pl.play()
