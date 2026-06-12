extends Area2D

@export var proxima_cena: String = "res://scenes/fases/CasaElliot.tscn"

var trocando_cena := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if trocando_cena:
		return

	if body.is_in_group("player"):
		trocando_cena = true
		print("Indo para: ", proxima_cena)

		var main := get_tree().current_scene

		if main != null and main.has_method("load_scene_with_fade"):
			await main.load_scene_with_fade(proxima_cena, 0.8, 0.8)
		else:
			push_error("Main não encontrada ou não possui load_scene_with_fade().")
			trocando_cena = false
