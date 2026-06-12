extends Area2D

@export var proxima_cena: String = "res://scenes/fases/ZonaNorte.tscn"

var trocando_cena := false
var player_dentro := false
var player_ref: Node2D = null
var aviso_bloqueio_rodando := false


func _ready() -> void:
	collision_layer = 0

	# Detecta player na Layer 1 ou Layer 2.
	collision_mask = 1 | 2

	monitoring = true
	monitorable = true

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

	var fabrica = main.current_scene

	if fabrica == null:
		push_error("Cena atual não encontrada dentro da Main.")
		return

	if not fabrica.has_method("pode_ir_para_zona_norte"):
		push_error("A cena Fabrica_Oleo não possui o método pode_ir_para_zona_norte().")
		return

	if not fabrica.pode_ir_para_zona_norte():
		if not aviso_bloqueio_rodando:
			aviso_bloqueio_rodando = true

			if fabrica.has_method("mostrar_aviso_precisa_encontrar_carta"):
				await fabrica.mostrar_aviso_precisa_encontrar_carta(body)

			aviso_bloqueio_rodando = false

		return

	trocando_cena = true
	print("Indo para: ", proxima_cena)

	if main.has_method("load_scene_with_fade"):
		await main.load_scene_with_fade(proxima_cena, 0.8, 0.8)
	else:
		push_error("Main não possui load_scene_with_fade().")
		trocando_cena = false
