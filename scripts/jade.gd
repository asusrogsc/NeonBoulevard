# scripts/jade.gd
extends Node3D
var locked := false

func set_locked(value: bool) -> void:
    locked = value