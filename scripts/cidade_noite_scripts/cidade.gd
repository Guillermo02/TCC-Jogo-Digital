extends Node2D

@onready var dialog_holder: Node2D = $DialogHolder
@onready var dialog_box: Control = $DialogHolder/dialog_box

# Capanga
@onready var capanga_1: Node2D = $Capanga1
@onready var area_capanga_1: Area2D = $Capanga1/Area2D
@onready var tecla_e_capanga_1: Node2D = $Capanga1/E

# Mendigo
@onready var mendigo_1: Node2D = $Mendigo1
@onready var area_mendigo_1: Area2D = $Mendigo1/Area2D
@onready var tecla_e_mendigo_1: Node2D = $Mendigo1/E
@onready var sprite_mendigo: AnimatedSprite2D = $Mendigo1/AnimatedSprite2D

# Botão e chão
@onready var sistema_botao = $SistemaBotão
@onready var chao_subida: TileMapLayer = $Terreno/ChãoSubida

# Drones
@onready var drone_1: Node2D = get_node_or_null("Drone1") as Node2D
@onready var drone_2: Node2D = get_node_or_null("Drone2") as Node2D
@onready var drone_3: Node2D = get_node_or_null("Drone3") as Node2D

# Vidas/Escudos que aparecem indicando o caminho
@onready var vidas_container: Node2D = get_node_or_null("Vidas") as Node2D
@onready var vida_escudo_1: Node2D = get_node_or_null("Vidas/VidaEscudo") as Node2D
@onready var vida_escudo_2: Node2D = get_node_or_null("Vidas/VidaEscudo2") as Node2D
@onready var vida_escudo_3: Node2D = get_node_or_null("Vidas/VidaEscudo3") as Node2D

@export var distancia_entrada_drones_fora_camera: float = 220.0
@export var duracao_entrada_drones: float = 1.15
@export var atraso_entre_drones: float = 0.18
@export var altura_extra_entrada_drones: float = -40.0

@export var atraso_vidas_apos_drones: float = 0.2
@export var duracao_fadein_vida: float = 0.45
@export var intervalo_entre_vidas: float = 0.0

var drones: Array[Node2D] = []
var posicoes_finais_drones: Array[Vector2] = []
var drones_ativados := false

var vidas_escudo: Array[Node2D] = []
var vidas_ativadas := false

var player_ref: Node2D = null

var offset_balao: Vector2 = Vector2(135, -165)
var alvo_dialogo: Node2D = null

var jogador_perto_capanga := false
var jogador_perto_mendigo := false

var dialogo_ativo := false
var dialogo_capanga_feito := false
var dialogo_mendigo_feito := false
var dialogo_token := 0

var botao_ativado_processando := false

var falas := {
	"capanga_1": "Ei! Se eu fosse você voltaria para casa, o prefeito não quer ninguém por aqui essas horas.",
	"jogador_1": "Não estou procurando confusão.",
	"capanga_1.1": "Você deveria ter cuidado essas horas, os drones de detecção já devem ter sido ativados por ai.",
	"jogador_1.1": "Eu percebi, desviei de um agora pouco, mas eu preciso passar.",
	"capanga_2": "Passar? Eu estou avisando, principalmente depois do que aconteceu na fábrica de óleo, o prefeito está bravo.",
	"jogador_2": "Na fábrica? O que teve por lá?",
	"capanga_3": "Sai daqui cara, fui pago para bater em caras curiosos como você.",
	"jogador_3": "Por favor, preciso muito saber, me ajudaria demais.",
	"capanga_4": "Você tem sorte que eu não gosto desse prefeito...",
	"capanga_5": "Mas se quiser saber de algo, dê um jeito de falar com o camarada em cima do outro prédio.",
	"capanga_6": "Ele viu tudo, mas o prefeito desprezou ele por morar nas ruas.",

	"mendigo_1": "Fala ai engomadinho, é bem alto aqui né? HAHAHA",
	"jogador_m1": "Preciso da sua ajuda, me falaram que você viu algo na fábrica...",
	"mendigo_2": "To bebado demais HAHAHA. Mas eu vi tudo pelo fundo da garrafa!",
	"jogador_m2": "Como você chegou lá? Ela fica depois da floresta, impossível chegar sem estar sóbrio.",
	"mendigo_3": "Acho que é tipo um super poder, eu bebo e quando me dou conta estou nos lugares... HAHAHA.",
	"jogador_m3": "Ta bom, mas você viu o que por lá então?",
	"mendigo_4": "HAHAHA não sei o que aquela garota encontrou, mas o prefeito ficou bem bravo por ela estar lá.",
	"jogador_m4": "GAROTA?! Uma de cabelo curto e voz fina?",
	"mendigo_5": "Ela mesmaaaaa, como você sabia? Ou você é um detetive ou lê mentes, a gente tem poderes cara HAHAHA.",
	"mendigo_6": "Se for até lá, vá de manhã cedo. Se for agora à noite, vai encontrar os homens do prefeito por lá."
}


func _ready() -> void:
	dialog_holder.scale = Vector2(0.5, 0.5)
	dialog_box.hide()

	tecla_e_capanga_1.show()
	tecla_e_mendigo_1.show()

	chao_subida.hide()
	chao_subida.modulate.a = 0.0
	chao_subida.collision_enabled = false

	configurar_drones_iniciais()
	configurar_vidas_iniciais()

	if not area_capanga_1.body_entered.is_connected(_on_capanga_enter):
		area_capanga_1.body_entered.connect(_on_capanga_enter)

	if not area_capanga_1.body_exited.is_connected(_on_capanga_exit):
		area_capanga_1.body_exited.connect(_on_capanga_exit)

	if not area_mendigo_1.body_entered.is_connected(_on_mendigo_enter):
		area_mendigo_1.body_entered.connect(_on_mendigo_enter)

	if not area_mendigo_1.body_exited.is_connected(_on_mendigo_exit):
		area_mendigo_1.body_exited.connect(_on_mendigo_exit)

	if not sistema_botao.botao_ativado.is_connected(_on_botao_ativado):
		sistema_botao.botao_ativado.connect(_on_botao_ativado)

	await get_tree().process_frame

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0] as Node2D
	else:
		push_warning("Nenhum player encontrado no grupo 'player' na cena Cidade.")


func _process(_delta: float) -> void:
	if dialog_box.visible and alvo_dialogo != null:
		atualizar_posicao_balao()

	if not dialogo_ativo:
		if jogador_perto_capanga and not dialogo_capanga_feito:
			if Input.is_action_just_pressed("interagir"):
				await iniciar_dialogo_capanga()

		elif jogador_perto_mendigo and not dialogo_mendigo_feito:
			if Input.is_action_just_pressed("interagir"):
				await iniciar_dialogo_mendigo()


func configurar_drones_iniciais() -> void:
	drones.clear()
	posicoes_finais_drones.clear()

	var lista_drones := [drone_1, drone_2, drone_3]

	for drone in lista_drones:
		if drone == null:
			continue

		drones.append(drone)
		posicoes_finais_drones.append(drone.global_position)

		drone.visible = false
		drone.modulate.a = 0.0

		if drone.has_method("desativar_drone"):
			drone.desativar_drone()
		else:
			desativar_luz_drone_fallback(drone)


func configurar_vidas_iniciais() -> void:
	vidas_escudo.clear()

	var lista_vidas := [vida_escudo_1, vida_escudo_2, vida_escudo_3]

	for vida in lista_vidas:
		if vida == null:
			continue

		vidas_escudo.append(vida)
		vida.visible = false
		vida.modulate.a = 0.0


func desativar_luz_drone_fallback(drone: Node2D) -> void:
	if drone == null:
		return

	var luz_area := drone.get_node_or_null("LuzArea") as Area2D
	var luz_visual := drone.get_node_or_null("LuzArea/LuzVisual") as Polygon2D
	var colisao_luz := drone.get_node_or_null("LuzArea/CollisionPolygon2D") as CollisionPolygon2D

	if luz_area != null:
		luz_area.monitoring = false

	if luz_visual != null:
		luz_visual.visible = false
		luz_visual.modulate.a = 0.0

	if colisao_luz != null:
		colisao_luz.disabled = true


func ativar_drones_com_animacao() -> void:
	if drones_ativados:
		return

	drones_ativados = true

	if drones.is_empty():
		push_warning("Nenhum drone encontrado. Crie Drone1, Drone2 e Drone3 na cidade.tscn.")
		return

	var ultimo_tween: Tween = null

	for i in range(drones.size()):
		if not is_inside_tree():
			return

		var drone := drones[i]

		if drone == null or not is_instance_valid(drone):
			continue

		var pos_final := posicoes_finais_drones[i]
		var pos_inicial := calcular_posicao_entrada_drone(pos_final, i)

		drone.global_position = pos_inicial
		drone.visible = true
		drone.modulate.a = 0.0

		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)

		tween.tween_property(drone, "global_position", pos_final, duracao_entrada_drones)
		tween.tween_property(drone, "modulate:a", 1.0, duracao_entrada_drones * 0.55)

		tween.tween_callback(func():
			if is_instance_valid(drone):
				if drone.has_method("ativar_drone"):
					drone.ativar_drone()
		)

		ultimo_tween = tween

		if i < drones.size() - 1:
			await get_tree().create_timer(atraso_entre_drones).timeout

	if ultimo_tween != null:
		await ultimo_tween.finished


func ativar_vidas_com_animacao() -> void:
	if vidas_ativadas:
		return

	vidas_ativadas = true

	if vidas_escudo.is_empty():
		push_warning("Nenhuma vida/escudo encontrada dentro do nó Vidas.")
		return

	for vida in vidas_escudo:
		if not is_inside_tree():
			return

		if vida == null or not is_instance_valid(vida):
			continue

		vida.visible = true
		vida.modulate.a = 0.0

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(vida, "modulate:a", 1.0, duracao_fadein_vida)

		await tween.finished

		if intervalo_entre_vidas > 0.0:
			await get_tree().create_timer(intervalo_entre_vidas).timeout


func calcular_posicao_entrada_drone(pos_final: Vector2, indice: int) -> Vector2:
	var camera_atual := get_viewport().get_camera_2d()

	if camera_atual == null:
		return pos_final + Vector2(260.0 + indice * 40.0, altura_extra_entrada_drones)

	var centro_camera := camera_atual.get_screen_center_position()
	var tamanho_tela := get_viewport_rect().size
	var metade_largura := tamanho_tela.x * camera_atual.zoom.x * 0.5
	var limite_direita := centro_camera.x + metade_largura + distancia_entrada_drones_fora_camera

	return Vector2(
		limite_direita + indice * 45.0,
		pos_final.y + altura_extra_entrada_drones
	)


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


func iniciar_dialogo_capanga() -> void:
	if dialogo_ativo:
		return

	dialogo_ativo = true
	dialogo_capanga_feito = true
	dialogo_token += 1

	var token_local := dialogo_token

	await mostrar_fala(capanga_1, falas["capanga_1"], token_local)
	await mostrar_fala(player_ref, falas["jogador_1"], token_local)
	await mostrar_fala(capanga_1, falas["capanga_1.1"], token_local)
	await mostrar_fala(player_ref, falas["jogador_1.1"], token_local)
	await mostrar_fala(capanga_1, falas["capanga_2"], token_local)
	await mostrar_fala(player_ref, falas["jogador_2"], token_local)
	await mostrar_fala(capanga_1, falas["capanga_3"], token_local)
	await mostrar_fala(player_ref, falas["jogador_3"], token_local)
	await mostrar_fala(capanga_1, falas["capanga_4"], token_local)
	await mostrar_fala(capanga_1, falas["capanga_5"], token_local)
	await mostrar_fala(capanga_1, falas["capanga_6"], token_local)

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = null
	dialogo_ativo = false
	await dialog_box.esconder_balao()

	if sistema_botao != null and sistema_botao.has_method("liberar_com_animacao"):
		await sistema_botao.liberar_com_animacao()


func iniciar_dialogo_mendigo() -> void:
	if dialogo_ativo:
		return

	dialogo_ativo = true
	dialogo_mendigo_feito = true
	dialogo_token += 1

	var token_local := dialogo_token

	sprite_mendigo.flip_h = false

	await mostrar_fala(mendigo_1, falas["mendigo_1"], token_local)
	await mostrar_fala(player_ref, falas["jogador_m1"], token_local)
	await mostrar_fala(mendigo_1, falas["mendigo_2"], token_local)
	await mostrar_fala(player_ref, falas["jogador_m2"], token_local)
	await mostrar_fala(mendigo_1, falas["mendigo_3"], token_local)
	await mostrar_fala(player_ref, falas["jogador_m3"], token_local)
	await mostrar_fala(mendigo_1, falas["mendigo_4"], token_local)
	await mostrar_fala(player_ref, falas["jogador_m4"], token_local)
	await mostrar_fala(mendigo_1, falas["mendigo_5"], token_local)
	await mostrar_fala(mendigo_1, falas["mendigo_6"], token_local)

	if not dialogo_ainda_valido(token_local):
		return

	alvo_dialogo = null
	dialogo_ativo = false
	await dialog_box.esconder_balao()


func _on_botao_ativado() -> void:
	print("BOTAO: iniciou")

	if player_ref != null and player_ref.has_method("tocar_attack_botao"):
		await player_ref.tocar_attack_botao()

	print("BOTAO: depois ataque player")

	await get_tree().create_timer(0.3).timeout

	print("BOTAO: depois timer 0.3")

	chao_subida.show()
	chao_subida.modulate.a = 0.0
	chao_subida.collision_enabled = true

	var pos_final := chao_subida.position
	chao_subida.position.y += 40

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(chao_subida, "modulate:a", 1.0, 0.6)
	tween.tween_property(chao_subida, "position:y", pos_final.y, 0.6)

	print("BOTAO: antes drones")
	await ativar_drones_com_animacao()

	print("BOTAO: depois drones")

	if atraso_vidas_apos_drones > 0.0:
		await get_tree().create_timer(atraso_vidas_apos_drones).timeout

	print("BOTAO: antes vidas")
	await ativar_vidas_com_animacao()

	print("BOTAO: terminou")


func _on_capanga_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_capanga = true


func _on_capanga_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_capanga = false

		if not dialogo_ativo:
			await dialog_box.esconder_balao()


func _on_mendigo_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_mendigo = true


func _on_mendigo_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		jogador_perto_mendigo = false

		if not dialogo_ativo:
			await dialog_box.esconder_balao()


func pode_ir_para_fabrica() -> bool:
	return dialogo_mendigo_feito and not dialogo_ativo


func _exit_tree() -> void:
	dialogo_token += 1
	dialogo_ativo = false
	alvo_dialogo = null
	botao_ativado_processando = false
