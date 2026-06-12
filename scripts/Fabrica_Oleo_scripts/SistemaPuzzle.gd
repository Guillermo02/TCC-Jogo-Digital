extends Node2D

signal puzzle_acionado

@onready var area: Area2D = $Area2D
@onready var e_icon: Node2D = $E
@onready var bloqueado: Node2D = $Bloqueado
@onready var desbloqueado: Node2D = $Desbloqueado

@export var escala_desbloqueado_destaque: float = 1.55
@export var tempo_crescer_desbloqueado: float = 0.45
@export var tempo_desbloqueado_visivel: float = 0.35
@export var tempo_fade_desbloqueado: float = 0.65

var player_perto := false
var liberado := false
var acionado := false
var finalizado := false

var sumindo_indicadores := false

var bloqueado_scale_inicial: Vector2
var desbloqueado_scale_inicial: Vector2

var tween_liberacao: Tween = null
var tween_indicadores: Tween = null


func _ready() -> void:
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

	if player_perto and liberado and not acionado:
		if Input.is_action_just_pressed("interagir"):
			acionado = true
			puzzle_acionado.emit()


func liberar_com_animacao() -> void:
	if liberado or finalizado:
		return

	liberado = true
	finalizado = false
	acionado = false
	sumindo_indicadores = false

	_matar_tween_liberacao()

	e_icon.show()
	e_icon.modulate.a = 1.0

	# Bloqueado fica normal até a troca.
	bloqueado.show()
	bloqueado.modulate.a = 1.0
	bloqueado.scale = bloqueado_scale_inicial

	# Desbloqueado começa pequeno e invisível.
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
	finalizado = false
	acionado = false
	sumindo_indicadores = false

	_matar_tween_liberacao()

	e_icon.show()
	e_icon.modulate.a = 1.0

	bloqueado.hide()
	bloqueado.modulate.a = 1.0
	bloqueado.scale = bloqueado_scale_inicial

	desbloqueado.hide()
	desbloqueado.modulate.a = 1.0
	desbloqueado.scale = desbloqueado_scale_inicial


func liberar_interacao() -> void:
	if finalizado:
		return

	if not liberado:
		return

	acionado = false

	e_icon.show()
	e_icon.modulate.a = 1.0


func finalizar_interacao() -> void:
	if finalizado:
		return

	finalizado = true
	acionado = true
	liberado = false
	player_perto = false

	sumir_indicadores_suave()


func sumir_indicadores_suave() -> void:
	if sumindo_indicadores:
		return

	sumindo_indicadores = true

	await get_tree().create_timer(0.25).timeout

	_matar_tween_indicadores()

	var tween := create_tween()
	tween_indicadores = tween
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	if e_icon.visible:
		tween.tween_property(e_icon, "modulate:a", 0.0, 0.85)

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

		if not finalizado:
			e_icon.show()
			e_icon.modulate.a = 1.0


func _on_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_perto = false


func _matar_tween_liberacao() -> void:
	if tween_liberacao != null:
		if tween_liberacao.is_valid():
			tween_liberacao.kill()

	tween_liberacao = null


func _matar_tween_indicadores() -> void:
	if tween_indicadores != null:
		if tween_indicadores.is_valid():
			tween_indicadores.kill()

	tween_indicadores = null


func _exit_tree() -> void:
	_matar_tween_liberacao()
	_matar_tween_indicadores()
