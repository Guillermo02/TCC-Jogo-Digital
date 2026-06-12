extends Node2D

signal botao_ativado

@onready var area: Area2D = $Botão/Area2D
@onready var botao: Node2D = $Botão
@onready var e_icon: Node2D = $E
@onready var bloqueado: Node2D = $Bloqueado
@onready var desbloqueado: Node2D = $Desbloqueado

@export var escala_desbloqueado_destaque: float = 1.55
@export var tempo_crescer_desbloqueado: float = 0.45
@export var tempo_desbloqueado_visivel: float = 0.35
@export var tempo_fade_desbloqueado: float = 0.65

var player_perto := false
var liberado := false
var pressionado := false
var finalizado := false

var sumindo_indicadores := false

var botao_pos_inicial: Vector2
var botao_scale_inicial: Vector2

var bloqueado_scale_inicial: Vector2
var desbloqueado_scale_inicial: Vector2

var tween_liberacao: Tween = null
var tween_indicadores: Tween = null
var tween_botao: Tween = null


func _ready() -> void:
	botao_pos_inicial = botao.position
	botao_scale_inicial = botao.scale

	bloqueado_scale_inicial = bloqueado.scale
	desbloqueado_scale_inicial = desbloqueado.scale

	e_icon.modulate.a = 1.0
	bloqueado.modulate.a = 1.0
	desbloqueado.modulate.a = 1.0

	e_icon.show()
	bloqueado.show()
	desbloqueado.hide()

	bloqueado.scale = bloqueado_scale_inicial
	desbloqueado.scale = desbloqueado_scale_inicial

	if not area.body_entered.is_connected(_on_area_body_entered):
		area.body_entered.connect(_on_area_body_entered)

	if not area.body_exited.is_connected(_on_area_body_exited):
		area.body_exited.connect(_on_area_body_exited)


func _process(_delta: float) -> void:
	if finalizado:
		return

	if player_perto and liberado and not pressionado:
		if Input.is_action_just_pressed("interagir"):
			await pressionar_botao()


func liberar_com_animacao() -> void:
	if liberado or finalizado:
		return

	liberado = true
	pressionado = false
	sumindo_indicadores = false

	if tween_liberacao != null:
		if tween_liberacao.is_valid():
			tween_liberacao.kill()
		tween_liberacao = null

	e_icon.modulate.a = 1.0
	e_icon.show()

	# Bloqueado fica normal até o momento da troca.
	bloqueado.show()
	bloqueado.modulate.a = 1.0
	bloqueado.scale = bloqueado_scale_inicial

	# Prepara desbloqueado pequeno e invisível.
	desbloqueado.hide()
	desbloqueado.modulate.a = 0.0
	desbloqueado.scale = desbloqueado_scale_inicial

	var tween := create_tween()
	tween_liberacao = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Troca direta: bloqueado some, desbloqueado aparece pequeno.
	tween.tween_callback(func():
		if is_instance_valid(bloqueado):
			bloqueado.hide()
			bloqueado.modulate.a = 1.0
			bloqueado.scale = bloqueado_scale_inicial

		if is_instance_valid(desbloqueado):
			desbloqueado.show()
			desbloqueado.modulate.a = 1.0
			desbloqueado.scale = desbloqueado_scale_inicial
	)

	# Desbloqueado cresce.
	tween.tween_property(
		desbloqueado,
		"scale",
		desbloqueado_scale_inicial * escala_desbloqueado_destaque,
		tempo_crescer_desbloqueado
	)

	# Segura grande por um instante.
	tween.tween_interval(tempo_desbloqueado_visivel)

	# Some com fade ainda grande.
	tween.tween_property(
		desbloqueado,
		"modulate:a",
		0.0,
		tempo_fade_desbloqueado
	)

	tween.tween_callback(func():
		if is_instance_valid(desbloqueado):
			desbloqueado.hide()
			desbloqueado.modulate.a = 1.0
			desbloqueado.scale = desbloqueado_scale_inicial

		if is_instance_valid(e_icon):
			e_icon.show()
			e_icon.modulate.a = 1.0

		tween_liberacao = null
	)

	await tween.finished


func liberar() -> void:
	if liberado or finalizado:
		return

	liberado = true
	pressionado = false
	sumindo_indicadores = false

	if tween_liberacao != null:
		if tween_liberacao.is_valid():
			tween_liberacao.kill()
		tween_liberacao = null

	e_icon.modulate.a = 1.0
	e_icon.show()

	bloqueado.hide()
	bloqueado.modulate.a = 1.0
	bloqueado.scale = bloqueado_scale_inicial

	desbloqueado.hide()
	desbloqueado.modulate.a = 1.0
	desbloqueado.scale = desbloqueado_scale_inicial


func pressionar_botao() -> void:
	if finalizado:
		return

	pressionado = true
	finalizado = true
	liberado = false
	player_perto = false

	sumir_indicadores_suave()

	botao_ativado.emit()

	await get_tree().create_timer(0.2).timeout

	var pos_apertada := botao_pos_inicial + Vector2(2, 0)

	if tween_botao != null:
		if tween_botao.is_valid():
			tween_botao.kill()
		tween_botao = null

	tween_botao = create_tween()
	tween_botao.set_parallel(true)
	tween_botao.set_trans(Tween.TRANS_SINE)
	tween_botao.set_ease(Tween.EASE_IN_OUT)

	tween_botao.tween_property(botao, "scale:y", botao_scale_inicial.y * 0.45, 0.12)
	tween_botao.tween_property(botao, "position", pos_apertada, 0.12)

	await tween_botao.finished

	await get_tree().create_timer(1.0).timeout

	if tween_botao != null:
		if tween_botao.is_valid():
			tween_botao.kill()
		tween_botao = null

	tween_botao = create_tween()
	tween_botao.set_parallel(true)
	tween_botao.set_trans(Tween.TRANS_SINE)
	tween_botao.set_ease(Tween.EASE_IN_OUT)

	tween_botao.tween_property(botao, "scale:y", botao_scale_inicial.y, 0.12)
	tween_botao.tween_property(botao, "position", botao_pos_inicial, 0.12)

	await tween_botao.finished
	tween_botao = null


func mostrar_e_icon() -> void:
	if finalizado:
		return

	e_icon.modulate.a = 1.0
	e_icon.show()


func sumir_indicadores_suave() -> void:
	if sumindo_indicadores:
		return

	sumindo_indicadores = true

	await get_tree().create_timer(0.25).timeout

	if tween_indicadores != null:
		if tween_indicadores.is_valid():
			tween_indicadores.kill()
		tween_indicadores = null

	var tween := create_tween()
	tween_indicadores = tween
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Depois de apertar E, o E some.
	if e_icon.visible:
		tween.tween_property(e_icon, "modulate:a", 0.0, 0.85)

	# Segurança: se algum cadeado ainda estiver visível, some também.
	if bloqueado.visible:
		tween.tween_property(bloqueado, "modulate:a", 0.0, 0.85)

	if desbloqueado.visible:
		tween.tween_property(desbloqueado, "modulate:a", 0.0, 0.85)

	await tween.finished

	e_icon.hide()
	bloqueado.hide()
	desbloqueado.hide()

	e_icon.modulate.a = 1.0
	bloqueado.modulate.a = 1.0
	desbloqueado.modulate.a = 1.0

	bloqueado.scale = bloqueado_scale_inicial
	desbloqueado.scale = desbloqueado_scale_inicial

	sumindo_indicadores = false
	tween_indicadores = null


func _on_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = true

		if liberado and not pressionado and not finalizado:
			mostrar_e_icon()


func _on_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = false


func _exit_tree() -> void:
	if tween_liberacao != null:
		if tween_liberacao.is_valid():
			tween_liberacao.kill()
		tween_liberacao = null

	if tween_indicadores != null:
		if tween_indicadores.is_valid():
			tween_indicadores.kill()
		tween_indicadores = null

	if tween_botao != null:
		if tween_botao.is_valid():
			tween_botao.kill()
		tween_botao = null
