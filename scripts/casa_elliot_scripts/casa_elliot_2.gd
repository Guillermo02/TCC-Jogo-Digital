extends Node2D

@export var cena_menu_inicial_path: String = "res://scenes/menus/Inicio_jogo.tscn"

@export var offset_balao_player: Vector2 = Vector2(180, -210)
@export var offset_balao_liz: Vector2 = Vector2(170, -185)

@export var escala_balao: Vector2 = Vector2(0.58, 0.58)

@export var tempo_antes_dialogo: float = 0.8
@export var tempo_fade_final: float = 1.2
@export var tempo_texto_final_visivel: float = 2.2

@onready var dialog_holder: Node2D = $DialogHolder
@onready var dialog_box: Control = $DialogHolder/dialog_box
@onready var filha_liz: Node2D = get_node_or_null("FilhaLiz") as Node2D

var player_ref: Node2D = null
var alvo_dialogo: Node2D = null

var sequencia_rodando := false
var finalizando := false
var cancelar_sequencia := false
var dialogo_token := 0

var player_congelado_na_cutscene := false
var player_process_estava_ativo := true
var player_physics_process_estava_ativo := true

var falas := [
	{
		"alvo": "player",
		"texto": "Liz... finalmente estamos em casa. Você está bem mesmo?"
	},
	{
		"alvo": "liz",
		"texto": "Estou, pai. Cansada, assustada... mas estou bem."
	},
	{
		"alvo": "player",
		"texto": "Sua carta foi muito importante para achar você, filha."
	},
	{
		"alvo": "liz",
		"texto": "Que bom, pai. Eu sabia que você iria encontrar."
	},
	{
		"alvo": "player",
		"texto": "Você foi corajosa demais enfrentando as denúncias dos funcionários da fábrica."
	},
	{
		"alvo": "liz",
		"texto": "Eu não entrei por coragem. Entrei porque alguém precisava ouvir aquelas pessoas."
	},
	{
		"alvo": "player",
		"texto": "Os trabalhadores, a fábrica, o prefeito... tudo isso vai mudar a cidade."
	},
	{
		"alvo": "liz",
		"texto": "Vai. O país precisa saber quem estava destruindo e corrompendo Dystineak Wrotion."
	},
	{
		"alvo": "player",
		"texto": "E o que você vai fazer agora? Ainda pretende publicar tudo?"
	},
	{
		"alvo": "liz",
		"texto": "Vou publicar, junto com o depoimento dos funcionários que foram presos, eles precisam ser ouvidos."
	},
	{
		"alvo": "player",
		"texto": "Seria bom preparar um bom material antes que a luz acabe..."
	},
	{
		"alvo": "liz",
		"texto": "Pode deixar, pai. Vou preparar algo já. Se eu parar agora, eles vencem de outro jeito."
	},
	{
		"alvo": "player",
		"texto": "Você cresceu muito mais do que eu percebi."
	},
	{
		"alvo": "liz",
		"texto": "Obrigada, pai. Ainda temos muita coisa pela frente..."
	},
	{
		"alvo": "player",
		"texto": "Certo, dê o seu melhor filha, a cidade precisa disso."
	},
	{
		"alvo": "liz",
		"texto": "Ouviu isso? Deve estar caindo o mundo lá fora."
	},
	{
		"alvo": "player",
		"texto": "Deve, mas preciso rastrear as cargas ilícitas que o prefeito enviou ainda hoje. Você terá mais provas."
	},
	{
		"alvo": "liz",
		"texto": "Tudo bem, mas cuidado porque você sabe como a cidade fica um caos com chuva."
	}
]


func _ready() -> void:
	add_to_group("casa_elliot_final")

	dialog_holder.scale = escala_balao
	dialog_box.hide()

	await get_tree().process_frame

	encontrar_player()
	preparar_personagens()

	call_deferred("iniciar_sequencia_final")


func _process(_delta: float) -> void:
	if dialog_box.visible and alvo_dialogo != null:
		atualizar_posicao_balao()

	if sequencia_rodando or finalizando:
		manter_player_parado_na_cutscene()


func sequencia_ainda_valida() -> bool:
	return is_inside_tree() and not cancelar_sequencia


func dialogo_ainda_valido(token: int) -> bool:
	if not is_inside_tree():
		return false

	if token != dialogo_token:
		return false

	return true


func encontrar_player() -> void:
	var players := get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		player_ref = players[0] as Node2D
	else:
		push_warning("Nenhum player encontrado no grupo 'player' na cena CasaElliot2.")


func preparar_personagens() -> void:
	if player_ref != null and is_instance_valid(player_ref):
		congelar_player_cutscene(true)
		parar_personagem(player_ref)
		tocar_animacao_personagem(player_ref, "idle")

	if filha_liz != null and is_instance_valid(filha_liz):
		parar_personagem(filha_liz)
		tocar_animacao_personagem(filha_liz, "idle")

	virar_personagens_um_para_o_outro(player_ref, filha_liz)


func iniciar_sequencia_final() -> void:
	if sequencia_rodando:
		return

	if player_ref == null or filha_liz == null:
		return

	if not is_instance_valid(player_ref) or not is_instance_valid(filha_liz):
		return

	sequencia_rodando = true
	cancelar_sequencia = false

	congelar_player_cutscene(true)
	manter_player_parado_na_cutscene()

	await get_tree().create_timer(tempo_antes_dialogo).timeout

	if not sequencia_ainda_valida():
		return

	virar_personagens_um_para_o_outro(player_ref, filha_liz)

	for fala in falas:
		if not sequencia_ainda_valida():
			return

		manter_player_parado_na_cutscene()

		var alvo_nome: String = fala["alvo"]
		var texto: String = fala["texto"]

		if alvo_nome == "player":
			virar_personagens_um_para_o_outro(player_ref, filha_liz)
			await mostrar_fala(player_ref, texto)
		else:
			virar_personagens_um_para_o_outro(player_ref, filha_liz)
			await mostrar_fala(filha_liz, texto)

		manter_player_parado_na_cutscene()

	if not sequencia_ainda_valida():
		return

	await dialog_box.esconder_balao()
	alvo_dialogo = null

	manter_player_parado_na_cutscene()

	await finalizar_jogo()


func finalizar_jogo() -> void:
	if finalizando:
		return

	finalizando = true
	sequencia_rodando = false

	congelar_player_cutscene(true)
	manter_player_parado_na_cutscene()

	var fade_layer := CanvasLayer.new()
	fade_layer.name = "FinalFadeLayer"
	fade_layer.layer = 200
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)

	var fade := ColorRect.new()
	fade.name = "FinalFade"
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade.process_mode = Node.PROCESS_MODE_ALWAYS
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade)

	var label := Label.new()
	label.name = "TextoFinal"
	label.text = "Fim...\nObrigado por jogar!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate.a = 0.0
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	var fonte_pixel := load("res://fonts/PixelifySans-SemiBold.ttf") as FontFile
	if fonte_pixel != null:
		label.add_theme_font_override("font", fonte_pixel)

	label.add_theme_font_size_override("font_size", 32)

	fade_layer.add_child(label)

	var tween_fade_out := create_tween()
	tween_fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_fade_out.tween_property(fade, "color:a", 1.0, tempo_fade_final)

	await tween_fade_out.finished

	if not is_inside_tree():
		return

	var tween_texto_in := create_tween()
	tween_texto_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_texto_in.tween_property(label, "modulate:a", 1.0, 1.0)

	await tween_texto_in.finished

	if not is_inside_tree():
		return

	await get_tree().create_timer(tempo_texto_final_visivel).timeout

	if not is_inside_tree():
		return

	var tween_texto_out := create_tween()
	tween_texto_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_texto_out.tween_property(label, "modulate:a", 0.0, 1.0)

	await tween_texto_out.finished

	if not is_inside_tree():
		return

	await voltar_para_menu_inicial()


func voltar_para_menu_inicial() -> void:
	SaveManager.delete_save()

	var main := get_tree().get_first_node_in_group("scene_manager")

	if main != null and main.has_method("load_scene_with_fade"):
		await main.load_scene_with_fade(cena_menu_inicial_path, 0.2, 0.8)
	else:
		get_tree().change_scene_to_file(cena_menu_inicial_path)


func mostrar_fala(alvo: Node2D, texto: String) -> void:
	if alvo == null:
		return

	if not is_instance_valid(alvo):
		return

	dialogo_token += 1
	var token_local := dialogo_token

	manter_player_parado_na_cutscene()

	await dialog_box.esconder_balao()

	if not dialogo_ainda_valido(token_local):
		return

	await get_tree().create_timer(0.15).timeout

	if not dialogo_ainda_valido(token_local):
		return

	manter_player_parado_na_cutscene()

	alvo_dialogo = alvo
	atualizar_posicao_balao()

	await dialog_box.mostrar_texto(texto)

	if not dialogo_ainda_valido(token_local):
		return

	manter_player_parado_na_cutscene()

	await esperar_enter(token_local)

	if not dialogo_ainda_valido(token_local):
		return

	manter_player_parado_na_cutscene()


func atualizar_posicao_balao() -> void:
	if alvo_dialogo == null:
		return

	if not is_instance_valid(alvo_dialogo):
		return

	var offset_atual := offset_balao_player

	if alvo_dialogo == filha_liz:
		offset_atual = offset_balao_liz

	dialog_holder.global_position = alvo_dialogo.global_position + offset_atual


func aguardar_soltar_enter(token: int) -> void:
	await get_tree().process_frame

	while is_inside_tree() and Input.is_action_pressed("ui_accept") and dialogo_ainda_valido(token):
		manter_player_parado_na_cutscene()
		await get_tree().process_frame


func esperar_enter(token: int) -> void:
	await aguardar_soltar_enter(token)

	while is_inside_tree() and not Input.is_action_just_pressed("ui_accept") and dialogo_ainda_valido(token):
		manter_player_parado_na_cutscene()
		await get_tree().process_frame

	await aguardar_soltar_enter(token)


func congelar_player_cutscene(congelar: bool) -> void:
	if player_ref == null:
		return

	if not is_instance_valid(player_ref):
		return

	if congelar:
		if not player_congelado_na_cutscene:
			player_process_estava_ativo = player_ref.is_processing()
			player_physics_process_estava_ativo = player_ref.is_physics_processing()

		player_congelado_na_cutscene = true

		bloquear_controle_player(true)
		parar_personagem(player_ref)
		tocar_animacao_personagem(player_ref, "idle")

		player_ref.set_process(false)
		player_ref.set_physics_process(false)
	else:
		if not player_congelado_na_cutscene:
			return

		player_ref.set_process(player_process_estava_ativo)
		player_ref.set_physics_process(player_physics_process_estava_ativo)

		player_congelado_na_cutscene = false

		bloquear_controle_player(false)


func manter_player_parado_na_cutscene() -> void:
	if player_ref == null:
		return

	if not is_instance_valid(player_ref):
		return

	if player_ref is CharacterBody2D:
		player_ref.velocity = Vector2.ZERO

	if player_ref.has_method("set_controle_bloqueado"):
		player_ref.set_controle_bloqueado(true)
	elif player_ref.has_method("set_pode_mover"):
		player_ref.set_pode_mover(false)
	elif player_ref.has_method("set_can_move"):
		player_ref.set_can_move(false)

	tocar_animacao_personagem(player_ref, "idle")


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


func parar_personagem(personagem: Node) -> void:
	if personagem == null:
		return

	if not is_instance_valid(personagem):
		return

	if personagem.has_method("parar_movimento"):
		personagem.parar_movimento()

	if personagem is CharacterBody2D:
		personagem.velocity = Vector2.ZERO


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


func _exit_tree() -> void:
	cancelar_sequencia = true
	dialogo_token += 1
	sequencia_rodando = false
	finalizando = false
	alvo_dialogo = null

	if player_ref != null and is_instance_valid(player_ref):
		congelar_player_cutscene(false)
