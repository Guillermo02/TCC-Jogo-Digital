extends Node2D

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_BARREIRA_PREFEITO := 16 # Layer 5

@export var cena_casa_elliot_path: String = "res://scenes/fases/CasaElliot2.tscn"

@export var velocidade_entrada_player: float = 130.0
@export var velocidade_liz: float = 105.0
@export var intervalo_entrada_capangas: float = 2.0

@export var offset_balao: Vector2 = Vector2(135, -165)

@onready var dialog_holder: Node2D = $DialogHolder
@onready var dialog_box: Control = $DialogHolder/dialog_box

@onready var filha_liz: Node2D = $FilhaLiz
@onready var prefeito: Node2D = $Prefeito
@onready var camera: Camera2D = $Camera2D

@onready var capanga_1: Node2D = $CapangaAgressivo
@onready var capanga_2: Node2D = $CapangaAgressivo2

@onready var player_entrada_ponto: Marker2D = $PlayerEntradaPonto
@onready var liz_ponto_pai: Marker2D = $LizPontoPai
@onready var liz_saida_ponto: Marker2D = $LizSaidaPonto

@onready var barreira_prefeito: StaticBody2D = get_node_or_null("BarreiraPrefeito") as StaticBody2D
@onready var barreira_prefeito_collision: CollisionShape2D = get_node_or_null("BarreiraPrefeito/CollisionShape2D") as CollisionShape2D
@onready var barreira_prefeito_area_aviso: Area2D = get_node_or_null("BarreiraPrefeito/AreaAviso") as Area2D
@onready var barreira_prefeito_area_collision: CollisionShape2D = get_node_or_null("BarreiraPrefeito/AreaAviso/CollisionShape2D") as CollisionShape2D

var player_ref: Node2D = null
var alvo_dialogo: Node2D = null

var luta_capangas_rodando := false
var luta_prefeito_rodando := false

var barreira_prefeito_ativa := false
var aviso_barreira_ativo := false

var camera_process_estava_ativo := true

var sequencia_rodando := false
var cancelar_sequencia := false
var dialogo_token := 0
var transicao_final_rodando := false

var falas := {
	"liz_1": "Você não vai conseguir esconder isso por muito tempo.",
	"prefeito_1": "Esconder? Minha querida, Dystineak Wrotion sempre pertenceu a quem soube mandar nela.",
	"liz_2": "Acha que prender os trabalhadores para abafar tudo isso não vai dar em nada?",
	"prefeito_2": "Eu estou dando um futuro a este lugar. Algumas pessoas só precisam sair do caminho.",
	"liz_3": "Usar a linha de metrô da Zona Norte para transportar cargas ilícitas da fábrica de óleo não é dar futuro.",
	"liz_3b": "E quando a chuva chegar, ninguém vai notar esses barris que foram desviados. Você é sujo!",
	"prefeito_3": "Provas somem. Pessoas também. Você deveria ter aprendido isso antes de vir até aqui.",
	"liz_4": "Meu pai vai me encontrar.",
	"prefeito_4": "Então espero que ele venha rápido. Assim resolvo os dois problemas no mesmo dia.",
	"jogador_1": "O Prefeito...",
	"jogador_2": "SAIA DE PERTO DA MINHA FILHA!",
	"prefeito_5": "Olha só, eu sabia que você tinha dado um jeito de chamar alguém, garota. PEGUEM ELE!!!",
	"jogador_barreira": "Vou cuidar desses caras primeiro antes de acabar com esse prefeito.",
	"liz_5": "Eu sabia que você viria, pai.",
	"jogador_3": "Que bom que está bem, filha. Agora vá pra casa, fique segura.",
	"prefeito_6": "Já que esses incompetentes não me ajudam em nada, eu mesmo vou cuidar de você!",
	"prefeito_7": "E depois vou atrás dessa sua filhinha, ela sabe demais...",
	"jogador_4": "Agora vou ver como a minha filha está e você será preso antes dessa tempestade que está vindo!"
}


func _ready() -> void:
	dialog_holder.scale = Vector2(0.5, 0.5)
	dialog_box.hide()

	await get_tree().process_frame

	encontrar_player()

	preparar_camera_para_cutscene()
	preparar_personagens()
	preparar_capangas()
	configurar_barreira_prefeito()
	aplicar_colisoes_somente_com_mundo()

	call_deferred("iniciar_sequencia_zona_norte")


func _process(_delta: float) -> void:
	if dialog_box.visible and alvo_dialogo != null:
		atualizar_posicao_balao()


func sequencia_ainda_valida() -> bool:
	return is_inside_tree() and not cancelar_sequencia


func encontrar_player() -> void:
	var players := get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		player_ref = players[0] as Node2D
	else:
		push_warning("Nenhum player encontrado no grupo 'player' na cena ZonaNorte.")


func preparar_camera_para_cutscene() -> void:
	if camera == null:
		return

	camera_process_estava_ativo = camera.is_processing()
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.make_current()


func liberar_camera_apos_cutscene() -> void:
	if camera == null:
		return

	camera.set_process(camera_process_estava_ativo)
	camera.set_physics_process(true)


func preparar_personagens() -> void:
	if player_ref != null:
		bloquear_controle_player(true)
		tocar_animacao_personagem(player_ref, "idle")

	if filha_liz != null:
		filha_liz.add_to_group("filha_liz")
		filha_liz.set("speed", velocidade_liz)
		tocar_animacao_personagem(filha_liz, "idle")

	if prefeito != null:
		prefeito.add_to_group("prefeito")
		prefeito.set("active", false)
		tocar_animacao_personagem(prefeito, "idle")

		if prefeito.has_signal("derrotado"):
			if not prefeito.derrotado.is_connected(_on_prefeito_derrotado):
				prefeito.derrotado.connect(_on_prefeito_derrotado)


func preparar_capangas() -> void:
	preparar_capanga(capanga_1)
	preparar_capanga(capanga_2)


func preparar_capanga(capanga: Node2D) -> void:
	if capanga == null:
		return

	capanga.add_to_group("capanga_agressivo")
	capanga.set("active", false)

	if capanga.has_method("configurar_colisoes"):
		capanga.configurar_colisoes()

	tocar_animacao_personagem(capanga, "idle")


func configurar_barreira_prefeito() -> void:
	barreira_prefeito_ativa = false
	aviso_barreira_ativo = false

	if barreira_prefeito != null:
		barreira_prefeito.collision_layer = 0
		barreira_prefeito.collision_mask = 0

		barreira_prefeito.set_collision_layer_value(5, true)

		barreira_prefeito.set_collision_mask_value(1, false)
		barreira_prefeito.set_collision_mask_value(2, false)
		barreira_prefeito.set_collision_mask_value(3, false)
		barreira_prefeito.set_collision_mask_value(4, false)
		barreira_prefeito.set_collision_mask_value(5, false)

	if barreira_prefeito_collision != null:
		barreira_prefeito_collision.set_deferred("disabled", true)

	if barreira_prefeito_area_aviso != null:
		barreira_prefeito_area_aviso.collision_layer = 0
		barreira_prefeito_area_aviso.collision_mask = 0
		barreira_prefeito_area_aviso.set_collision_mask_value(2, true)
		barreira_prefeito_area_aviso.monitoring = false
		barreira_prefeito_area_aviso.monitorable = false

		if not barreira_prefeito_area_aviso.body_entered.is_connected(_on_barreira_prefeito_body_entered):
			barreira_prefeito_area_aviso.body_entered.connect(_on_barreira_prefeito_body_entered)

	if barreira_prefeito_area_collision != null:
		barreira_prefeito_area_collision.set_deferred("disabled", true)


func ativar_barreira_prefeito() -> void:
	barreira_prefeito_ativa = true

	if barreira_prefeito != null:
		barreira_prefeito.collision_layer = 0
		barreira_prefeito.collision_mask = 0
		barreira_prefeito.set_collision_layer_value(5, true)

	if barreira_prefeito_collision != null:
		barreira_prefeito_collision.set_deferred("disabled", false)

	if barreira_prefeito_area_aviso != null:
		barreira_prefeito_area_aviso.collision_layer = 0
		barreira_prefeito_area_aviso.collision_mask = 0
		barreira_prefeito_area_aviso.set_collision_mask_value(2, true)
		barreira_prefeito_area_aviso.set_deferred("monitoring", true)
		barreira_prefeito_area_aviso.set_deferred("monitorable", true)

	if barreira_prefeito_area_collision != null:
		barreira_prefeito_area_collision.set_deferred("disabled", false)

	atualizar_colisao_player_com_barreira()
	remover_colisao_barreira_dos_outros_personagens()


func desativar_barreira_prefeito() -> void:
	barreira_prefeito_ativa = false
	aviso_barreira_ativo = false

	if barreira_prefeito_collision != null:
		barreira_prefeito_collision.set_deferred("disabled", true)

	if barreira_prefeito_area_aviso != null:
		barreira_prefeito_area_aviso.set_deferred("monitoring", false)
		barreira_prefeito_area_aviso.set_deferred("monitorable", false)

	if barreira_prefeito_area_collision != null:
		barreira_prefeito_area_collision.set_deferred("disabled", true)

	atualizar_colisao_player_com_barreira()
	remover_colisao_barreira_dos_outros_personagens()


func atualizar_colisao_player_com_barreira() -> void:
	if player_ref == null:
		return

	if not is_instance_valid(player_ref):
		return

	if player_ref is PhysicsBody2D:
		if barreira_prefeito_ativa:
			player_ref.set_collision_mask_value(5, true)
		else:
			player_ref.set_collision_mask_value(5, false)


func remover_colisao_barreira_dos_outros_personagens() -> void:
	remover_barreira_da_mask(filha_liz)
	remover_barreira_da_mask(prefeito)
	remover_barreira_da_mask(capanga_1)
	remover_barreira_da_mask(capanga_2)

	for capanga in get_tree().get_nodes_in_group("capanga_agressivo"):
		remover_barreira_da_mask(capanga)


func remover_barreira_da_mask(no: Node) -> void:
	if no == null:
		return

	if not is_instance_valid(no):
		return

	if no is PhysicsBody2D:
		no.set_collision_mask_value(5, false)


func _on_barreira_prefeito_body_entered(body: Node2D) -> void:
	if not barreira_prefeito_ativa:
		return

	if aviso_barreira_ativo:
		return

	if not body.is_in_group("player"):
		return

	aviso_barreira_ativo = true

	await mostrar_fala_temporaria(player_ref, falas["jogador_barreira"], 2.2)

	aviso_barreira_ativo = false


func aplicar_colisoes_somente_com_mundo() -> void:
	configurar_corpo_somente_mundo(player_ref, true)
	configurar_corpo_somente_mundo(filha_liz, false)
	configurar_corpo_somente_mundo(prefeito, false)
	configurar_corpo_somente_mundo(capanga_1, false)
	configurar_corpo_somente_mundo(capanga_2, false)

	criar_excecao_fisica(player_ref, filha_liz)
	criar_excecao_fisica(player_ref, prefeito)
	criar_excecao_fisica(player_ref, capanga_1)
	criar_excecao_fisica(player_ref, capanga_2)
	criar_excecao_fisica(filha_liz, prefeito)
	criar_excecao_fisica(filha_liz, capanga_1)
	criar_excecao_fisica(filha_liz, capanga_2)
	criar_excecao_fisica(prefeito, capanga_1)
	criar_excecao_fisica(prefeito, capanga_2)
	criar_excecao_fisica(capanga_1, capanga_2)

	atualizar_colisao_player_com_barreira()
	remover_colisao_barreira_dos_outros_personagens()


func configurar_corpo_somente_mundo(no: Node, manter_layer_player: bool) -> void:
	if no == null:
		return

	if not is_instance_valid(no):
		return

	if no is PhysicsBody2D:
		no.collision_mask = LAYER_WORLD

		if manter_layer_player:
			no.collision_layer = LAYER_PLAYER


func criar_excecao_fisica(a: Node, b: Node) -> void:
	if a == null or b == null:
		return

	if not is_instance_valid(a) or not is_instance_valid(b):
		return

	if a is PhysicsBody2D and b is PhysicsBody2D:
		a.add_collision_exception_with(b)
		b.add_collision_exception_with(a)


func iniciar_sequencia_zona_norte() -> void:
	if sequencia_rodando:
		return

	if player_ref == null:
		return

	sequencia_rodando = true
	cancelar_sequencia = false

	await conversa_inicial_liz_prefeito()
	if not sequencia_ainda_valida():
		return

	await entrada_do_jogador()
	if not sequencia_ainda_valida():
		return

	await iniciar_luta_capangas()
	if not sequencia_ainda_valida():
		return

	await esperar_capangas_derrotados()
	if not sequencia_ainda_valida():
		return

	await reencontro_liz_pai()
	if not sequencia_ainda_valida():
		return

	await iniciar_luta_prefeito()


func conversa_inicial_liz_prefeito() -> void:
	await mostrar_fala(filha_liz, falas["liz_1"])
	await mostrar_fala(prefeito, falas["prefeito_1"])
	await mostrar_fala(filha_liz, falas["liz_2"])
	await mostrar_fala(prefeito, falas["prefeito_2"])
	await mostrar_fala(filha_liz, falas["liz_3"])
	await mostrar_fala(filha_liz, falas["liz_3b"])
	await mostrar_fala(prefeito, falas["prefeito_3"])
	await mostrar_fala(filha_liz, falas["liz_4"])
	await mostrar_fala(prefeito, falas["prefeito_4"])

	await finalizar_dialogo_sequencial()


func entrada_do_jogador() -> void:
	bloquear_controle_player(true)

	await mover_personagem_ate(player_ref, player_entrada_ponto.global_position, velocidade_entrada_player)

	await mostrar_fala(player_ref, falas["jogador_1"])
	await mostrar_fala(player_ref, falas["jogador_2"])
	await mostrar_fala(prefeito, falas["prefeito_5"])

	await finalizar_dialogo_sequencial()


func iniciar_luta_capangas() -> void:
	luta_capangas_rodando = true

	bloquear_controle_player(false)
	liberar_camera_apos_cutscene()

	ativar_barreira_prefeito()
	aplicar_colisoes_somente_com_mundo()

	await ativar_capanga(capanga_1)

	if not sequencia_ainda_valida():
		return

	await get_tree().create_timer(intervalo_entrada_capangas).timeout

	if not sequencia_ainda_valida():
		return

	await ativar_capanga(capanga_2)


func ativar_capanga(capanga: Node2D) -> void:
	if capanga == null:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		encontrar_player()

	if player_ref == null:
		return

	await get_tree().process_frame

	if not sequencia_ainda_valida():
		return

	if capanga.has_method("activate"):
		capanga.activate(player_ref)
	else:
		push_error(capanga.name + " não tem método activate(target).")
		return

	aplicar_colisoes_somente_com_mundo()


func esperar_capangas_derrotados() -> void:
	while sequencia_ainda_valida() and luta_capangas_rodando:
		aplicar_colisoes_somente_com_mundo()

		var capanga_1_morto := inimigo_esta_morto(capanga_1)
		var capanga_2_morto := inimigo_esta_morto(capanga_2)

		if capanga_1_morto and capanga_2_morto:
			break

		await get_tree().create_timer(0.25).timeout

	if not sequencia_ainda_valida():
		return

	luta_capangas_rodando = false
	desativar_barreira_prefeito()
	bloquear_controle_player(true)
	tocar_animacao_personagem(player_ref, "idle")


func inimigo_esta_morto(inimigo: Node) -> bool:
	if inimigo == null:
		return true

	if not is_instance_valid(inimigo):
		return true

	var morto = inimigo.get("dead")

	if morto == null:
		return false

	return morto


func reencontro_liz_pai() -> void:
	aplicar_colisoes_somente_com_mundo()

	await filha_liz_ir_ate_attack_area_do_player()

	if not sequencia_ainda_valida():
		return

	aplicar_colisoes_somente_com_mundo()

	virar_personagens_um_para_o_outro(player_ref, filha_liz)

	await mostrar_fala(filha_liz, falas["liz_5"])

	virar_personagens_um_para_o_outro(player_ref, filha_liz)

	await mostrar_fala(player_ref, falas["jogador_3"])

	virar_personagem_para_alvo(player_ref, filha_liz)

	await finalizar_dialogo_sequencial()

	if not sequencia_ainda_valida():
		return

	if filha_liz.has_method("sair_correndo_para_esquerda"):
		filha_liz.sair_correndo_para_esquerda()
	else:
		await mover_personagem_ate(filha_liz, liz_saida_ponto.global_position, velocidade_liz)

	await mostrar_fala(prefeito, falas["prefeito_6"])
	await mostrar_fala(prefeito, falas["prefeito_7"])

	await finalizar_dialogo_sequencial()


func filha_liz_ir_ate_attack_area_do_player() -> void:
	if filha_liz == null:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		encontrar_player()

	if player_ref == null:
		return

	var attack_area_liz := filha_liz.get_node_or_null("AttackArea") as Area2D

	if attack_area_liz != null:
		attack_area_liz.monitoring = true
		attack_area_liz.monitorable = true
		attack_area_liz.collision_layer = 0
		attack_area_liz.collision_mask = LAYER_PLAYER

	if filha_liz.has_method("ir_para_posicao"):
		var destino := player_ref.global_position
		destino.y = filha_liz.global_position.y

		filha_liz.ir_para_posicao(destino)

		while sequencia_ainda_valida():
			if player_ref == null or not is_instance_valid(player_ref):
				break

			if attack_area_liz != null and attack_area_liz.get_overlapping_bodies().has(player_ref):
				if filha_liz.has_method("parar_movimento"):
					filha_liz.parar_movimento()
				else:
					filha_liz.set("indo_para_destino", false)
					filha_liz.set("saindo_da_tela", false)

					if filha_liz is CharacterBody2D:
						filha_liz.velocity = Vector2.ZERO

					tocar_animacao_personagem(filha_liz, "idle")

				break

			var liz_chegou := false
			var valor_chegou = filha_liz.get("indo_para_destino")

			if valor_chegou != null and valor_chegou == false:
				liz_chegou = true

			if liz_chegou:
				break

			await get_tree().process_frame
	else:
		await mover_personagem_ate(filha_liz, player_ref.global_position, velocidade_liz)

	tocar_animacao_personagem(filha_liz, "idle")


func iniciar_luta_prefeito() -> void:
	luta_prefeito_rodando = true
	bloquear_controle_player(false)

	desativar_barreira_prefeito()
	aplicar_colisoes_somente_com_mundo()

	if prefeito.has_method("activate"):
		prefeito.activate(player_ref)
	else:
		push_error("Prefeito não tem o método activate(target).")


func _on_prefeito_derrotado(_prefeito: Node) -> void:
	if transicao_final_rodando:
		return

	if not luta_prefeito_rodando:
		return

	transicao_final_rodando = true
	luta_prefeito_rodando = false
	cancelar_sequencia = true

	bloquear_controle_player(true)
	desativar_barreira_prefeito()

	virar_personagem_para_alvo(player_ref, prefeito)
	tocar_animacao_personagem(player_ref, "idle")

	await mostrar_fala(player_ref, falas["jogador_4"])
	await finalizar_dialogo_sequencial()

	await transicao_final_para_casa_elliot()


func transicao_final_para_casa_elliot() -> void:
	var main := get_tree().get_first_node_in_group("scene_manager")

	if main != null and main.has_method("load_scene_with_fade"):
		await main.load_scene_with_fade(cena_casa_elliot_path, 1.2, 1.2)
	else:
		push_warning("SceneManager não encontrado. Usando change_scene_to_file como fallback.")
		get_tree().change_scene_to_file(cena_casa_elliot_path)


func mover_personagem_ate(personagem: Node2D, destino: Vector2, velocidade: float) -> void:
	if personagem == null:
		return

	if not is_instance_valid(personagem):
		return

	var distancia := personagem.global_position.distance_to(destino)
	var duracao := maxf(0.1, distancia / velocidade)

	var direcao_x := signf(destino.x - personagem.global_position.x)

	if direcao_x != 0.0:
		virar_personagem(personagem, direcao_x)

	if personagem == player_ref:
		tocar_animacao_personagem(personagem, "run")
	else:
		tocar_animacao_personagem(personagem, "walk")

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(personagem, "global_position", destino, duracao)

	await tween.finished

	if not sequencia_ainda_valida():
		return

	if personagem != null and is_instance_valid(personagem):
		tocar_animacao_personagem(personagem, "idle")


func bloquear_controle_player(travar: bool) -> void:
	if player_ref == null:
		return

	if not is_instance_valid(player_ref):
		return

	if player_ref.has_method("set_controle_bloqueado"):
		player_ref.set_controle_bloqueado(travar)
	elif player_ref.has_method("set_pode_mover"):
		player_ref.set_pode_mover(not travar)
	elif player_ref.has_method("set_can_move"):
		player_ref.set_can_move(not travar)

	if player_ref is CharacterBody2D:
		player_ref.velocity = Vector2.ZERO


func tocar_animacao_personagem(personagem: Node, animacao: String) -> void:
	if personagem == null:
		return

	if not is_instance_valid(personagem):
		return

	var sprite := personagem.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if sprite == null:
		return

	if sprite.sprite_frames.has_animation(animacao):
		sprite.play(animacao)


func virar_personagem(personagem: Node, direcao_x: float) -> void:
	if personagem == null:
		return

	if not is_instance_valid(personagem):
		return

	var sprite := personagem.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if sprite == null:
		return

	sprite.flip_h = direcao_x < 0.0


func virar_personagem_para_alvo(personagem: Node, alvo: Node) -> void:
	if personagem == null or alvo == null:
		return

	if not is_instance_valid(personagem) or not is_instance_valid(alvo):
		return

	if not personagem is Node2D or not alvo is Node2D:
		return

	var personagem_2d := personagem as Node2D
	var alvo_2d := alvo as Node2D

	var direcao_x := signf(alvo_2d.global_position.x - personagem_2d.global_position.x)

	if direcao_x == 0.0:
		return

	virar_personagem(personagem, direcao_x)


func virar_personagens_um_para_o_outro(personagem_a: Node, personagem_b: Node) -> void:
	virar_personagem_para_alvo(personagem_a, personagem_b)
	virar_personagem_para_alvo(personagem_b, personagem_a)


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


func aguardar_novo_enter(token: int) -> void:
	await aguardar_soltar_enter(token)

	while is_inside_tree() and not Input.is_action_just_pressed("ui_accept") and dialogo_ainda_valido(token):
		await get_tree().process_frame

	await aguardar_soltar_enter(token)


func mostrar_fala(alvo: Node2D, texto: String) -> void:
	if alvo == null:
		return

	if not is_instance_valid(alvo):
		return

	dialogo_token += 1
	var token_local := dialogo_token

	await aguardar_soltar_enter(token_local)

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = alvo
	atualizar_posicao_balao()

	await dialog_box.mostrar_texto(texto)

	if not dialogo_ainda_valido(token_local):
		return

	await get_tree().create_timer(0.08).timeout

	if not dialogo_ainda_valido(token_local):
		return

	await aguardar_novo_enter(token_local)


func finalizar_dialogo_sequencial() -> void:
	dialogo_token += 1
	var token_local := dialogo_token

	await aguardar_soltar_enter(token_local)

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = null
	await dialog_box.esconder_balao()


func mostrar_fala_temporaria(alvo: Node2D, texto: String, duracao: float = 2.0) -> void:
	if alvo == null:
		return

	if not is_instance_valid(alvo):
		return

	dialogo_token += 1
	var token_local := dialogo_token

	await aguardar_soltar_enter(token_local)

	if not dialogo_ainda_valido(token_local):
		return

	await dialog_box.esconder_balao()
	await get_tree().create_timer(0.08).timeout

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = alvo
	atualizar_posicao_balao()

	await dialog_box.mostrar_texto(texto)

	if not dialogo_ainda_valido(token_local):
		return

	await get_tree().create_timer(duracao).timeout

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = null
	await dialog_box.esconder_balao()


func _exit_tree() -> void:
	cancelar_sequencia = true
	dialogo_token += 1
	sequencia_rodando = false
	luta_capangas_rodando = false
	luta_prefeito_rodando = false
	aviso_barreira_ativo = false
	alvo_dialogo = null

	if player_ref != null and is_instance_valid(player_ref):
		bloquear_controle_player(false)

	desativar_barreira_prefeito()
