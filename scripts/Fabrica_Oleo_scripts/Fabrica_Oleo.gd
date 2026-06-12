extends Node2D

@onready var dialog_holder: Node2D = $DialogHolder
@onready var dialog_box: Control = $DialogHolder/dialog_box

# NPC Óleo
@onready var npc_oleo: Node2D = $NPC_Oleo
@onready var anim_npc_oleo: AnimatedSprite2D = $NPC_Oleo/AnimatedSprite2D
@onready var area_npc_oleo: Area2D = $NPC_Oleo/Area2D
@onready var tecla_e_npc_oleo: Node2D = $NPC_Oleo/E

# Puzzle
@onready var sistema_puzzle = $SistemaPuzzle
@onready var puzzle_descida = $PuzzleDescida
@onready var chao_caindo: TileMapLayer = $ChãoCaindo

# Capangas agressivos
@onready var capanga_agressivo: Node2D = get_node_or_null("CapangaAgressivo") as Node2D
@onready var capanga_agressivo_2: Node2D = get_node_or_null("CapangaAgressivo2") as Node2D
@onready var capanga_trigger: Area2D = get_node_or_null("CapangaTrigger") as Area2D

# Pássaros do fundo
@onready var parallax_8: Node = get_node_or_null("Parallax8")
@onready var passaro_1: Node2D = get_node_or_null("Parallax8/Passaro1") as Node2D
@onready var passaro_2: Node2D = get_node_or_null("Parallax8/Passaro2") as Node2D
@onready var passaro_3: Node2D = get_node_or_null("Parallax8/Passaro3") as Node2D

@export var intervalo_voo_passaros: float = 10.0
@export var duracao_voo_passaros: float = 13.0
@export var deslocamento_voo_passaros: Vector2 = Vector2(400, -100)
@export var atraso_entre_passaros: float = 0.18
@export var margem_fora_camera_passaros: float = 260.0

var passaros: Array[Node2D] = []
var posicoes_iniciais_passaros: Array[Vector2] = []
var tweens_passaros: Array[Tween] = []
var voo_passaros_rodando := false
var cancelar_voo_passaros := false

var player_ref: Node2D = null

var offset_balao: Vector2 = Vector2(135, -165)
var alvo_dialogo: Node2D = null

var jogador_perto_npc_oleo := false

var dialogo_ativo := false
var dialogo_npc_oleo_feito := false
var puzzle_resolvido := false
var dialogo_token := 0

var capanga_ativado := false
var capanga_2_ativado := false
var evento_capanga_rodando := false

var chao_caindo_pos_inicial: Vector2
var npc_oleo_pos_inicial: Vector2

var distancia_descida_chao := 96.0

# Carta da Liz
var carta_liz_interagida := false
var jogador_perto_carta_liz := false
var area_carta_liz: Area2D = null
var aviso_carta_rodando := false

# Fuga do NPC
var npc_oleo_correndo := false
var velocidade_fuga_npc := 120.0
var margem_sumir_npc := 80.0

var falas := {
	"npc_oleo_1": "Você não devia estar aqui. Essa fábrica ainda está sendo vigiada pelos homens do prefeito.",
	"jogador_1": "Eu vim atrás de respostas. Uma garota esteve aqui antes?",
	"npc_oleo_2": "Esteve! Chamamos uma jornalista para expor o que estava acontecendo aqui, já estou cansado.",
	"jogador_2": "Liz... então ela realmente veio investigar a fábrica de óleo.",
	"npc_oleo_3": "Veio porque nós ligamos para ela. Alguns trabalhadores descobriram um esquema sujo aqui dentro.",
	"jogador_3": "Que tipo de esquema?",
	"npc_oleo_4": "A alta cúpula desviava dinheiro, falsificava relatórios e pagava propina ao prefeito.",
	"npc_oleo_5": "Em troca, ele ignorava vazamentos, acidentes e contratos fraudulentos da gestão.",
	"jogador_4": "Então a fábrica e a prefeitura estavam trabalhando juntas esse tempo todo?",
	"npc_oleo_6": "Sim. Quando Liz chegou perto das provas, tudo saiu do controle.",
	"jogador_5": "O que fizeram com ela e com os trabalhadores?",
	"npc_oleo_7": "Alguns foram levados junto com a garota. Outros sumiram antes do amanhecer.",
	"jogador_6": "E você ficou aqui por quê?",
	"npc_oleo_8": "Consegui me esconder em uma árvore, mas cuidado, eles ainda estão por perto.",
	"npc_oleo_9": "Agora preciso descer daqui, poderia ativar o painel que faz essa plataforma descer?",
	"npc_oleo_10": "Eu não consegui entender o que era pra fazer com aqueles símbolos.",
	"capanga_1": "PARADO! Ninguém deveria estar aqui!",
	"capanga_2": "Você vai pagar! E eu vou ganhar um aumento!",
	"jogador_precisa_carta": "Ainda não posso sair daqui, sinto que preciso encontrar algo, a Liz deve ter deixado alguma coisa para trás..."
}


func _ready() -> void:
	dialog_holder.scale = Vector2(0.5, 0.5)
	dialog_box.hide()

	tecla_e_npc_oleo.show()

	if anim_npc_oleo.sprite_frames.has_animation("idle"):
		anim_npc_oleo.play("idle")

	chao_caindo_pos_inicial = chao_caindo.position
	npc_oleo_pos_inicial = npc_oleo.position

	if puzzle_descida.has_method("hide"):
		puzzle_descida.hide()

	if not area_npc_oleo.body_entered.is_connected(_on_npc_oleo_enter):
		area_npc_oleo.body_entered.connect(_on_npc_oleo_enter)

	if not area_npc_oleo.body_exited.is_connected(_on_npc_oleo_exit):
		area_npc_oleo.body_exited.connect(_on_npc_oleo_exit)

	if not sistema_puzzle.puzzle_acionado.is_connected(_on_puzzle_acionado):
		sistema_puzzle.puzzle_acionado.connect(_on_puzzle_acionado)

	if not puzzle_descida.puzzle_resolvido.is_connected(_on_puzzle_resolvido):
		puzzle_descida.puzzle_resolvido.connect(_on_puzzle_resolvido)

	if puzzle_descida.has_signal("puzzle_cancelado"):
		if not puzzle_descida.puzzle_cancelado.is_connected(_on_puzzle_cancelado):
			puzzle_descida.puzzle_cancelado.connect(_on_puzzle_cancelado)

	if capanga_trigger != null:
		if not capanga_trigger.body_entered.is_connected(_on_capanga_trigger_body_entered):
			capanga_trigger.body_entered.connect(_on_capanga_trigger_body_entered)
	else:
		push_warning("CapangaTrigger não encontrado na cena Fabrica_Oleo.")

	if capanga_agressivo == null:
		push_warning("CapangaAgressivo não encontrado na cena Fabrica_Oleo.")
	else:
		if capanga_agressivo.has_signal("faltando_um_hit_para_morrer"):
			if not capanga_agressivo.is_connected(
				"faltando_um_hit_para_morrer",
				Callable(self, "_on_capanga_agressivo_faltando_um_hit")
			):
				capanga_agressivo.connect(
					"faltando_um_hit_para_morrer",
					Callable(self, "_on_capanga_agressivo_faltando_um_hit")
				)
		else:
			push_warning("CapangaAgressivo não tem o sinal faltando_um_hit_para_morrer.")

	if capanga_agressivo_2 == null:
		push_warning("CapangaAgressivo2 não encontrado na cena Fabrica_Oleo.")

	configurar_carta_liz()
	configurar_passaros()

	await get_tree().process_frame

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0] as Node2D
	else:
		push_warning("Nenhum player encontrado no grupo 'player' na cena Fabrica_Oleo.")

	call_deferred("iniciar_loop_voo_passaros")


func _process(delta: float) -> void:
	if dialog_box.visible and alvo_dialogo != null:
		atualizar_posicao_balao()

	if jogador_perto_npc_oleo and not dialogo_ativo and not dialogo_npc_oleo_feito:
		if Input.is_action_just_pressed("interagir"):
			await iniciar_dialogo_npc_oleo()

	if jogador_perto_carta_liz and not carta_liz_interagida:
		if Input.is_action_just_pressed("interagir"):
			marcar_carta_liz_interagida()

	if npc_oleo_correndo:
		mover_npc_oleo_para_esquerda(delta)


func configurar_passaros() -> void:
	passaros.clear()
	posicoes_iniciais_passaros.clear()

	var lista_passaros := [passaro_1, passaro_2, passaro_3]

	for passaro in lista_passaros:
		if passaro == null:
			continue

		passaros.append(passaro)
		posicoes_iniciais_passaros.append(passaro.position)

		passaro.visible = false

		if passaro is AnimatedSprite2D:
			var anim := passaro as AnimatedSprite2D
			tocar_animacao_passaro(anim)


func tocar_animacao_passaro(anim: AnimatedSprite2D) -> void:
	if anim == null:
		return

	if anim.sprite_frames == null:
		return

	if anim.sprite_frames.has_animation("fly"):
		anim.play("fly")
	elif anim.sprite_frames.has_animation("voando"):
		anim.play("voando")
	elif anim.sprite_frames.has_animation("default"):
		anim.play("default")


func iniciar_loop_voo_passaros() -> void:
	if voo_passaros_rodando:
		return

	if passaros.is_empty():
		push_warning("Nenhum pássaro encontrado em Parallax8/Passaro1, Passaro2 ou Passaro3.")
		return

	cancelar_voo_passaros = false
	voo_passaros_rodando = true

	while is_inside_tree() and not cancelar_voo_passaros:
		await get_tree().create_timer(intervalo_voo_passaros).timeout

		if not is_inside_tree() or cancelar_voo_passaros:
			break

		await executar_voo_passaros()

	voo_passaros_rodando = false


func executar_voo_passaros() -> void:
	limpar_tweens_passaros()

	for i in range(passaros.size()):
		if not is_inside_tree() or cancelar_voo_passaros:
			return

		var passaro := passaros[i]

		if passaro == null or not is_instance_valid(passaro):
			continue

		var pos_inicial := posicoes_iniciais_passaros[i]

		passaro.position = pos_inicial
		passaro.visible = true

		if passaro is AnimatedSprite2D:
			tocar_animacao_passaro(passaro as AnimatedSprite2D)

		var pos_final_global := calcular_posicao_final_passaro(passaro)

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(passaro, "global_position", pos_final_global, duracao_voo_passaros)
		tween.tween_callback(func():
			if is_instance_valid(passaro):
				passaro.visible = false
				passaro.position = pos_inicial
		)

		tweens_passaros.append(tween)

		if i < passaros.size() - 1:
			await get_tree().create_timer(atraso_entre_passaros).timeout

	if not is_inside_tree() or cancelar_voo_passaros:
		return

	await get_tree().create_timer(duracao_voo_passaros + 0.2).timeout


func limpar_tweens_passaros() -> void:
	for tween in tweens_passaros:
		if tween != null and tween.is_valid():
			tween.kill()

	tweens_passaros.clear()


func calcular_posicao_final_passaro(passaro: Node2D) -> Vector2:
	var inicio_global := passaro.global_position
	var direcao := deslocamento_voo_passaros.normalized()

	if direcao == Vector2.ZERO:
		return inicio_global

	var final_global := inicio_global + deslocamento_voo_passaros
	var camera_atual := get_viewport().get_camera_2d()

	if camera_atual == null:
		return final_global + Vector2(margem_fora_camera_passaros, 0)

	if direcao.x <= 0.0:
		return final_global

	var centro_camera := camera_atual.get_screen_center_position()
	var tamanho_tela := get_viewport_rect().size
	var metade_largura := tamanho_tela.x * camera_atual.zoom.x * 0.5
	var limite_direita := centro_camera.x + metade_largura + margem_fora_camera_passaros

	if final_global.x >= limite_direita:
		return final_global

	var distancia_necessaria := (limite_direita - inicio_global.x) / direcao.x

	if distancia_necessaria <= 0.0:
		return final_global

	return inicio_global + direcao * distancia_necessaria


func configurar_carta_liz() -> void:
	var area_encontrada := procurar_no_por_nome(self, "AreaCarta")

	if area_encontrada == null:
		push_warning("AreaCarta não encontrada. A saída para ZonaNorte dependerá de carta_liz_interagida ser marcada por outro script.")
		return

	if not area_encontrada is Area2D:
		push_warning("Nó chamado AreaCarta foi encontrado, mas não é Area2D.")
		return

	area_carta_liz = area_encontrada as Area2D

	area_carta_liz.collision_layer = 0
	area_carta_liz.collision_mask = 1 | 2
	area_carta_liz.monitoring = true
	area_carta_liz.monitorable = true

	if not area_carta_liz.body_entered.is_connected(_on_area_carta_liz_body_entered):
		area_carta_liz.body_entered.connect(_on_area_carta_liz_body_entered)

	if not area_carta_liz.body_exited.is_connected(_on_area_carta_liz_body_exited):
		area_carta_liz.body_exited.connect(_on_area_carta_liz_body_exited)


func procurar_no_por_nome(no: Node, nome_procurado: String) -> Node:
	if no.name == nome_procurado:
		return no

	for filho in no.get_children():
		var encontrado := procurar_no_por_nome(filho, nome_procurado)
		if encontrado != null:
			return encontrado

	return null


func _on_area_carta_liz_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_carta_liz = true
		player_ref = body


func _on_area_carta_liz_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_carta_liz = false


func marcar_carta_liz_interagida() -> void:
	if carta_liz_interagida:
		return

	carta_liz_interagida = true


func pode_ir_para_zona_norte() -> bool:
	return carta_liz_interagida


func mostrar_aviso_precisa_encontrar_carta(alvo: Node2D = null) -> void:
	if aviso_carta_rodando:
		return

	aviso_carta_rodando = true
	dialogo_token += 1

	var token_local := dialogo_token

	if alvo == null:
		alvo = player_ref

	if alvo == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			alvo = players[0] as Node2D

	if alvo != null:
		await mostrar_fala_temporaria_com_enter(alvo, falas["jogador_precisa_carta"], 3.2, token_local)

	aviso_carta_rodando = false


func atualizar_posicao_balao() -> void:
	if alvo_dialogo == null:
		return

	if not is_instance_valid(alvo_dialogo):
		return

	dialog_holder.global_position = alvo_dialogo.global_position + offset_balao


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


func esperar_enter_ou_tempo(duracao: float, token: int) -> void:
	await aguardar_soltar_enter(token)

	var tempo_passado := 0.0

	while is_inside_tree() and tempo_passado < duracao and dialogo_ainda_valido(token):
		if Input.is_action_just_pressed("ui_accept"):
			await aguardar_soltar_enter(token)
			return

		await get_tree().process_frame
		tempo_passado += get_process_delta_time()


func mostrar_fala(alvo: Node2D, texto: String, token: int) -> void:
	if alvo == null:
		return

	if not is_instance_valid(alvo):
		return

	if not dialogo_ainda_valido(token):
		return

	await dialog_box.esconder_balao()

	if not dialogo_ainda_valido(token):
		return

	await get_tree().create_timer(0.15).timeout

	if not dialogo_ainda_valido(token):
		return

	alvo_dialogo = alvo
	atualizar_posicao_balao()

	await dialog_box.mostrar_texto(texto)

	if not dialogo_ainda_valido(token):
		return

	await esperar_enter(token)


func mostrar_fala_temporaria(alvo: Node2D, texto: String, duracao: float = 2.0) -> void:
	dialogo_token += 1
	var token_local := dialogo_token
	await mostrar_fala_temporaria_com_enter(alvo, texto, duracao, token_local)


func mostrar_fala_temporaria_com_enter(alvo: Node2D, texto: String, duracao: float = 2.0, token: int = -1) -> void:
	if alvo == null:
		return

	if not is_instance_valid(alvo):
		return

	var token_local := token

	if token_local == -1:
		dialogo_token += 1
		token_local = dialogo_token

	if not dialogo_ainda_valido(token_local):
		return

	await dialog_box.esconder_balao()

	if not dialogo_ainda_valido(token_local):
		return

	await get_tree().create_timer(0.15).timeout

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = alvo
	atualizar_posicao_balao()

	await dialog_box.mostrar_texto(texto)

	if not dialogo_ainda_valido(token_local):
		return

	await esperar_enter_ou_tempo(duracao, token_local)

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = null
	await dialog_box.esconder_balao()


func iniciar_dialogo_npc_oleo() -> void:
	if dialogo_ativo:
		return

	dialogo_ativo = true
	dialogo_npc_oleo_feito = true
	dialogo_token += 1

	var token_local := dialogo_token

	await mostrar_fala(npc_oleo, falas["npc_oleo_1"], token_local)
	await mostrar_fala(player_ref, falas["jogador_1"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_2"], token_local)
	await mostrar_fala(player_ref, falas["jogador_2"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_3"], token_local)
	await mostrar_fala(player_ref, falas["jogador_3"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_4"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_5"], token_local)
	await mostrar_fala(player_ref, falas["jogador_4"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_6"], token_local)
	await mostrar_fala(player_ref, falas["jogador_5"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_7"], token_local)
	await mostrar_fala(player_ref, falas["jogador_6"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_8"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_9"], token_local)
	await mostrar_fala(npc_oleo, falas["npc_oleo_10"], token_local)

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = null
	dialogo_ativo = false
	await dialog_box.esconder_balao()

	if sistema_puzzle != null and sistema_puzzle.has_method("liberar_com_animacao"):
		await sistema_puzzle.liberar_com_animacao()


func _on_capanga_trigger_body_entered(body: Node2D) -> void:
	if capanga_ativado:
		return

	if evento_capanga_rodando:
		return

	if not body.is_in_group("player"):
		return

	if capanga_agressivo == null:
		push_error("Não foi possível ativar o capanga: nó CapangaAgressivo não encontrado.")
		return

	if not capanga_agressivo.has_method("activate"):
		push_error("O CapangaAgressivo não tem o método activate(target). Verifique o script dele.")
		return

	capanga_ativado = true
	evento_capanga_rodando = true

	if capanga_trigger != null:
		capanga_trigger.set_deferred("monitoring", false)
		capanga_trigger.set_deferred("monitorable", false)

	player_ref = body

	dialogo_ativo = true
	await mostrar_fala_temporaria(capanga_agressivo, falas["capanga_1"], 2.0)
	dialogo_ativo = false

	if is_inside_tree() and is_instance_valid(capanga_agressivo):
		capanga_agressivo.activate(player_ref)

	evento_capanga_rodando = false


func _on_capanga_agressivo_faltando_um_hit(capanga: Node) -> void:
	if capanga_2_ativado:
		return

	if capanga_agressivo_2 == null:
		push_error("Não foi possível ativar o segundo capanga: CapangaAgressivo2 não encontrado.")
		return

	if not capanga_agressivo_2.has_method("activate"):
		push_error("CapangaAgressivo2 não tem o método activate(target).")
		return

	if player_ref == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0] as Node2D
		else:
			push_error("Não foi possível ativar o segundo capanga: player não encontrado.")
			return

	capanga_2_ativado = true

	capanga_agressivo_2.activate(player_ref)

	dialogo_ativo = true
	await mostrar_fala_temporaria(capanga_agressivo_2, falas["capanga_2"], 3.0)
	dialogo_ativo = false


func _on_puzzle_acionado() -> void:
	if not dialogo_npc_oleo_feito:
		sistema_puzzle.liberar_interacao()
		return

	if puzzle_resolvido:
		return

	await puzzle_descida.abrir_puzzle()


func _on_puzzle_cancelado() -> void:
	if puzzle_resolvido:
		return

	sistema_puzzle.liberar_interacao()


func _on_puzzle_resolvido() -> void:
	if puzzle_resolvido:
		return

	puzzle_resolvido = true

	sistema_puzzle.finalizar_interacao()

	var pos_final_chao := chao_caindo_pos_inicial + Vector2(0, distancia_descida_chao)
	var pos_final_npc := npc_oleo_pos_inicial + Vector2(0, distancia_descida_chao)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(chao_caindo, "position", pos_final_chao, 0.8)
	tween.tween_property(npc_oleo, "position", pos_final_npc, 0.8)

	await tween.finished

	if not is_inside_tree():
		return

	iniciar_fuga_npc_oleo()


func iniciar_fuga_npc_oleo() -> void:
	if not is_instance_valid(npc_oleo):
		return

	jogador_perto_npc_oleo = false
	tecla_e_npc_oleo.hide()

	if area_npc_oleo != null:
		area_npc_oleo.set_deferred("monitoring", false)
		area_npc_oleo.set_deferred("monitorable", false)

	if anim_npc_oleo.sprite_frames.has_animation("run"):
		anim_npc_oleo.play("run")

	anim_npc_oleo.flip_h = true
	npc_oleo_correndo = true


func mover_npc_oleo_para_esquerda(delta: float) -> void:
	if not is_instance_valid(npc_oleo):
		npc_oleo_correndo = false
		return

	npc_oleo.global_position.x -= velocidade_fuga_npc * delta

	if npc_oleo_saiu_da_camera():
		npc_oleo_correndo = false
		npc_oleo.queue_free()


func npc_oleo_saiu_da_camera() -> bool:
	if not is_instance_valid(npc_oleo):
		return true

	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return npc_oleo.global_position.x < -margem_sumir_npc

	var centro_camera := camera.get_screen_center_position()
	var tamanho_tela := get_viewport_rect().size
	var metade_largura := tamanho_tela.x * camera.zoom.x * 0.5
	var limite_esquerdo := centro_camera.x - metade_largura - margem_sumir_npc

	return npc_oleo.global_position.x < limite_esquerdo


func _on_npc_oleo_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_npc_oleo = true


func _on_npc_oleo_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_npc_oleo = false

		if not dialogo_ativo:
			await dialog_box.esconder_balao()


func _exit_tree() -> void:
	cancelar_voo_passaros = true
	voo_passaros_rodando = false

	limpar_tweens_passaros()

	dialogo_token += 1
	dialogo_ativo = false
	aviso_carta_rodando = false
	evento_capanga_rodando = false
	alvo_dialogo = null
