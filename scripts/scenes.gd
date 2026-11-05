# scripts/scenes.gd
extends Node

var oldman: Node3D
var jade: Node3D
var active_scene: String = ""
var struggle: float = 0.0

const STRUGGLE_THRESHOLD := 1.5
const FALL_THRESHOLD := -0.5  # Seuil pour détecter que Jade est tombée (ajuste si nécessaire)

func _ready() -> void:
	oldman = get_node("/root/Main/Oldman")
	jade = get_node("/root/Main/Jade")
	
	print("Scenes initialisees : Oldman=", oldman, " Jade=", jade)

	if jade:
		if not jade.has_method("set_locked"):
			var jade_script = preload("res://scripts/jade.gd")
			jade.set_script(jade_script)
			jade.set_locked(false)

func _process(delta: float) -> void:
	# Si une scene est deja active, gerer la lutte
	if active_scene != "":
		var input := Input.get_vector("left", "right", "up", "down")
		if input.length() > 0.3:
			struggle += input.length() * delta
			if struggle >= STRUGGLE_THRESHOLD:
				_break_free()
		return

	# Detecter si Jade est tombee
	if jade and jade.global_position.y < FALL_THRESHOLD:
		print("Jade est tombee ! Lancement de N1 (grab + kiss)")
		_trigger_fall()

func _trigger_fall() -> void:
	if jade:
		jade.set_locked(true)
	active_scene = "N1"
	struggle = 0.0
	get_node("Animations").play_n1_animation()

func _break_free() -> void:
	print("Jade se degage !")
	if active_scene == "N1":
		get_node("Animations").break_n1_animation()
	if jade:
		jade.set_locked(false)
	active_scene = ""
	struggle = 0.0

func trigger(scene_name: String) -> void:
	print("Declenchement manuel : ", scene_name)
	match scene_name:
		"N1":
			_play_n1()
		"N2":
			_play_n2()
		"N3":
			_play_n3()

func _play_n1() -> void:
	active_scene = "N1"
	struggle = 0.0
	if jade:
		jade.set_locked(true)
	get_node("Animations").play_n1_animation()

func _play_n2() -> void:
	active_scene = "N2"
	struggle = 0.0
	if jade:
		jade.set_locked(true)
	# Ajoute ici la logique pour N2
	pass

func _play_n3() -> void:
	active_scene = "N3"
	struggle = 0.0
	if jade:
		jade.set_locked(true)
	# Ajoute ici la logique
