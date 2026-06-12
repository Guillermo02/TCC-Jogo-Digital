extends Area2D

@export var proxima_cena: String = "res://scenes/fases/cidade.tscn"

var trocando_cena := false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if trocando_cena:
		return

	if not body.is_in_group("player"):
		return

	var casa := get_tree().get_first_node_in_group("casa")

	if casa == null:
		push_error("Casa não encontrada no grupo 'casa'.")
		return

	if not casa.pode_ir_para_cidade():
		print("Ainda faltam interações antes de sair.")
		return

	trocando_cena = true
	print("Indo para: ", proxima_cena)

	var main := get_tree().current_scene

	if main != null and main.has_method("load_scene_with_fade"):
		await main.load_scene_with_fade(proxima_cena, 0.8, 0.8)
	else:
		push_error("Main não encontrada ou não possui load_scene_with_fade().")
		trocando_cena = false
