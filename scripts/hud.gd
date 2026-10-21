class_name Hud
extends Control
## Couche 2D (barres de vie, score, menus). Le dessin est fait par main.gd.

var game = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if game:
		game.draw_hud(self)
