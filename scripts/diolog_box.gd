extends Control

@export var texto_inicial: String = "Olá, viajante. Esta é uma frase maior para verificar se o balão aumenta sozinho conforme o texto ocupa mais espaço."
@export var velocidade_texto: float = 0.03
@export var tempo_espera_antes_saida: float = 0.8

@export_group("Animação de Entrada")
@export var entrada_duracao: float = 0.12
@export var entrada_escala_inicial: Vector2 = Vector2(0.85, 0.85)
@export var entrada_deslocamento_y: float = 6.0

@export_group("Animação de Saída")
@export var saida_duracao: float = 0.10
@export var saida_escala_final: Vector2 = Vector2(0.92, 0.92)
@export var saida_deslocamento_y: float = -4.0

@onready var bg_dialog_box: PanelContainer = $bg_dialog_box
@onready var text_label: Label = $bg_dialog_box/text_container/text_label
@onready var indicador: TextureRect = $indicador

var _posicao_inicial: Vector2
var _animando_texto: bool = false
var _texto_finalizado: bool = false
var _pode_fechar_com_enter: bool = false
var _fechando: bool = false
var _pular_digitacao: bool = false

func _ready() -> void:
	_posicao_inicial = position
	_preparar_balao()
	show()
	await mostrar_texto(texto_inicial)

func _preparar_balao() -> void:
	modulate.a = 1.0
	scale = Vector2.ONE
	position = _posicao_inicial
	text_label.visible_characters = 0
	_texto_finalizado = false
	_pode_fechar_com_enter = false
	_animando_texto = false
	_fechando = false
	_pular_digitacao = false

func mostrar_texto(texto: String) -> void:
	_resetar_estado_para_novo_texto()

	show()
	text_label.text = texto
	text_label.visible_characters = 0

	await get_tree().process_frame
	_atualizar_indicador()

	await _animar_entrada()
	await _animar_texto(texto)

	_texto_finalizado = true
	_pode_fechar_com_enter = true

func mostrar_texto_com_saida(texto: String, esperar: float = -1.0) -> void:
	_resetar_estado_para_novo_texto()

	show()
	text_label.text = texto
	text_label.visible_characters = 0

	await get_tree().process_frame
	_atualizar_indicador()

	await _animar_entrada()
	await _animar_texto(texto)

	_texto_finalizado = true
	_pode_fechar_com_enter = true

	var tempo_final := tempo_espera_antes_saida if esperar < 0.0 else esperar
	if tempo_final > 0.0:
		await get_tree().create_timer(tempo_final).timeout

	if visible and not _fechando:
		await esconder_balao()

func esconder_balao() -> void:
	if _fechando or not visible:
		return

	_fechando = true
	_pode_fechar_com_enter = false
	_animando_texto = false
	_pular_digitacao = false

	await _animar_saida()
	hide()

	_fechando = false
	_texto_finalizado = false

func pular_animacao_texto() -> void:
	if not _animando_texto:
		return

	_pular_digitacao = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if not event.is_action_pressed("ui_accept"):
		return

	if _fechando:
		return

	if _animando_texto:
		pular_animacao_texto()
		return

	if _pode_fechar_com_enter and _texto_finalizado:
		await esconder_balao()

func _resetar_estado_para_novo_texto() -> void:
	modulate.a = 1.0
	scale = Vector2.ONE
	position = _posicao_inicial
	_texto_finalizado = false
	_pode_fechar_com_enter = false
	_animando_texto = false
	_fechando = false
	_pular_digitacao = false

func _animar_entrada() -> void:
	modulate.a = 0.0
	scale = entrada_escala_inicial
	position = _posicao_inicial + Vector2(0, entrada_deslocamento_y)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, entrada_duracao)
	tween.tween_property(self, "scale", Vector2.ONE, entrada_duracao)
	tween.tween_property(self, "position", _posicao_inicial, entrada_duracao)

	await tween.finished

func _animar_saida() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, saida_duracao)
	tween.tween_property(self, "scale", saida_escala_final, saida_duracao)
	tween.tween_property(self, "position", _posicao_inicial + Vector2(0, saida_deslocamento_y), saida_duracao)

	await tween.finished

func _animar_texto(texto: String) -> void:
	_animando_texto = true
	_pular_digitacao = false

	for i in range(texto.length() + 1):
		if _pular_digitacao:
			text_label.visible_characters = texto.length()
			break

		text_label.visible_characters = i
		await get_tree().create_timer(velocidade_texto).timeout

	text_label.visible_characters = texto.length()
	_animando_texto = false
	_pular_digitacao = false

func _atualizar_indicador() -> void:
	var bg_size := bg_dialog_box.size
	var ind_size := indicador.size

	indicador.position.x = bg_dialog_box.position.x + (bg_size.x * 0.5) - (ind_size.x * 0.5)
	indicador.position.y = bg_dialog_box.position.y + bg_size.y - 1.0
