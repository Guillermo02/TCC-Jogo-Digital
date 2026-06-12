extends Node2D

@export var offset_balao: Vector2 = Vector2(180, -210)
@export var escala_balao: Vector2 = Vector2(0.58, 0.58)

@onready var dialog_holder: Node2D = $DialogHolder
@onready var dialog_box: Control = $DialogHolder/dialog_box

var player_ref: Node2D = null

var falas_mostradas := {}

var interacao_atual := 0

var interacao_1_feita := false
var interacao_2_feita := false

var dialogo_ativo := false
var dialogo_token := 0

var falas := {
	1: "Esse escritório está uma bagunça, quem deixou esse extintor aqui?",
	2: "Já olhei a localização do celular da Liz pelo computador... ela não estava na floresta.",
	3: "Ainda não achei uma pista relevante, vou à cidade investigar e ver se alguém viu alguma coisa, ser detetive não é fácil..."
}


func _ready() -> void:
	add_to_group("casa")

	dialog_holder.scale = escala_balao
	dialog_box.hide()

	await get_tree().process_frame

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		push_warning("Nenhum player encontrado no grupo 'player' na cena CasaElliot.")


func _process(_delta: float) -> void:
	if player_ref == null:
		return

	if not is_instance_valid(player_ref):
		return

	if dialog_box.visible:
		atualizar_posicao_balao()

	if dialogo_ativo:
		return

	if Input.is_action_just_pressed("interagir"):
		match interacao_atual:
			1:
				await mostrar_interacao_1()
			2:
				await mostrar_interacao_2()


func atualizar_posicao_balao() -> void:
	if player_ref == null:
		return

	if not is_instance_valid(player_ref):
		return

	dialog_holder.global_position = player_ref.global_position + offset_balao


func dialogo_ainda_valido(token: int) -> bool:
	if not is_inside_tree():
		return false

	if token != dialogo_token:
		return false

	return true


func aguardar_soltar_enter(token: int) -> void:
	await get_tree().process_frame

	while is_inside_tree() and Input.is_action_pressed("ui_accept") and dialogo_ainda_valido(token):
		await get_tree().process_frame


func esperar_enter(token: int) -> void:
	await aguardar_soltar_enter(token)

	while is_inside_tree() and not Input.is_action_just_pressed("ui_accept") and dialogo_ainda_valido(token):
		await get_tree().process_frame

	await aguardar_soltar_enter(token)


func mostrar_fala(numero: int) -> void:
	if falas_mostradas.has(numero):
		return

	if not falas.has(numero):
		return

	falas_mostradas[numero] = true
	await mostrar_texto_com_enter(falas[numero])


func mostrar_fala_repetivel(numero: int) -> void:
	if not falas.has(numero):
		return

	await mostrar_texto_com_enter(falas[numero])


func mostrar_texto_com_enter(texto: String) -> void:
	if dialogo_ativo:
		return

	dialogo_ativo = true
	dialogo_token += 1

	var token_local := dialogo_token

	await dialog_box.esconder_balao()

	if not dialogo_ainda_valido(token_local):
		return

	await get_tree().create_timer(0.08).timeout

	if not dialogo_ainda_valido(token_local):
		return

	if player_ref != null and is_instance_valid(player_ref):
		atualizar_posicao_balao()

	await dialog_box.mostrar_texto(texto)

	if not dialogo_ainda_valido(token_local):
		return

	await esperar_enter(token_local)

	if not dialogo_ainda_valido(token_local):
		return

	await dialog_box.esconder_balao()

	finalizar_dialogo(token_local)


func finalizar_dialogo(token: int = -1) -> void:
	if token != -1 and token != dialogo_token:
		return

	dialogo_ativo = false


func esconder_fala() -> void:
	if dialogo_ativo:
		return

	await dialog_box.esconder_balao()


func mostrar_interacao_1() -> void:
	if interacao_1_feita:
		return

	interacao_1_feita = true
	await mostrar_fala_repetivel(2)


func mostrar_interacao_2() -> void:
	if interacao_2_feita:
		return

	interacao_2_feita = true
	await mostrar_fala_repetivel(3)


func pode_ir_para_cidade() -> bool:
	return interacao_1_feita and interacao_2_feita


func _on_fala_inicial_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		await mostrar_fala(1)


func _on_interacao_1_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		interacao_atual = 1


func _on_interacao_1_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and interacao_atual == 1:
		interacao_atual = 0

		if not dialogo_ativo:
			await esconder_fala()


func _on_interacao_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		interacao_atual = 2


func _on_interacao_2_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and interacao_atual == 2:
		interacao_atual = 0

		if not dialogo_ativo:
			await esconder_fala()


func _exit_tree() -> void:
	dialogo_token += 1
	dialogo_ativo = false
