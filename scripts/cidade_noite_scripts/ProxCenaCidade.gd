extends Area2D

@export var proxima_cena: String = "res://scenes/fases/Fabrica_Oleo.tscn"

var trocando_cena := false
var player_dentro := false
var player_ref: Node2D = null

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_dentro and player_ref != null and not trocando_cena:
		await tentar_trocar_cena(player_ref)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_dentro = true
		player_ref = body
		await tentar_trocar_cena(body)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_dentro = false
		player_ref = null

func tentar_trocar_cena(body: Node2D) -> void:
	if trocando_cena:
		return

	if not body.is_in_group("player"):
		return

	var main := get_tree().get_first_node_in_group("scene_manager")

	if main == null:
		push_error("Main não encontrada no grupo 'scene_manager'.")
		return

	var cidade = main.current_scene

	if cidade == null:
		push_error("Cena atual não encontrada dentro da Main.")
		return

	if not cidade.has_method("pode_ir_para_fabrica"):
		push_error("A cena atual não possui o método pode_ir_para_fabrica().")
		return

	if not cidade.pode_ir_para_fabrica():
		return

	trocando_cena = true
	print("Indo para: ", proxima_cena)

	if main.has_method("load_scene_with_fade"):
		await main.load_scene_with_fade(proxima_cena, 0.8, 0.8)
	else:
		push_error("Main não possui load_scene_with_fade().")
		trocando_cena = false
