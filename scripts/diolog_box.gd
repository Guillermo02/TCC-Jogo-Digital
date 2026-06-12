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
var _fechando: bool = false
var _pular_digitacao: bool = false

var _tween_atual: Tween = null
var _fluxo_id: int = 0


func _ready() -> void:
	_posicao_inicial = position
	_preparar_balao()
	hide()


func _preparar_balao() -> void:
	_parar_tween_atual()

	modulate.a = 1.0
	scale = Vector2.ONE
	position = _posicao_inicial

	text_label.text = ""
	text_label.visible_characters = 0

	indicador.show()

	_animando_texto = false
	_texto_finalizado = false
	_fechando = false
	_pular_digitacao = false


func mostrar_texto(texto: String) -> void:
	_fluxo_id += 1
	var fluxo_local: int = _fluxo_id

	_resetar_estado_para_novo_texto()

	show()
	indicador.show()

	text_label.text = texto
	text_label.visible_characters = 0

	await get_tree().process_frame
	if not _fluxo_valido(fluxo_local):
		return

	await get_tree().process_frame
	if not _fluxo_valido(fluxo_local):
		return

	_atualizar_indicador()

	await _animar_entrada(fluxo_local)

	if not _fluxo_valido(fluxo_local):
		return

	await _animar_texto(texto, fluxo_local)

	if not _fluxo_valido(fluxo_local):
		return

	_texto_finalizado = true
	indicador.show()
	_atualizar_indicador()


func mostrar_texto_com_saida(texto: String, esperar: float = -1.0) -> void:
	_fluxo_id += 1
	var fluxo_local: int = _fluxo_id

	await mostrar_texto(texto)

	if not _fluxo_valido(fluxo_local):
		return

	var tempo_final: float = tempo_espera_antes_saida if esperar < 0.0 else esperar

	if tempo_final > 0.0:
		await get_tree().create_timer(tempo_final).timeout

	if not _fluxo_valido(fluxo_local):
		return

	if visible and not _fechando:
		await esconder_balao()


func esconder_balao() -> void:
	if _fechando:
		return

	if not visible:
		return

	_fluxo_id += 1

	_fechando = true
	_animando_texto = false
	_pular_digitacao = false

	await _animar_saida()

	hide()

	_fechando = false
	_texto_finalizado = false
	text_label.visible_characters = 0


func pular_animacao_texto() -> void:
	if not _animando_texto:
		return

	_pular_digitacao = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if _fechando:
		return

	if not event.is_action_pressed("ui_accept"):
		return

	if _animando_texto:
		pular_animacao_texto()
		get_viewport().set_input_as_handled()


func _resetar_estado_para_novo_texto() -> void:
	_parar_tween_atual()

	modulate.a = 1.0
	scale = Vector2.ONE
	position = _posicao_inicial

	_animando_texto = false
	_texto_finalizado = false
	_fechando = false
	_pular_digitacao = false

	indicador.show()


func _animar_entrada(fluxo_local: int) -> void:
	_parar_tween_atual()

	if not _fluxo_valido(fluxo_local):
		return

	modulate.a = 0.0
	scale = entrada_escala_inicial
	position = _posicao_inicial + Vector2(0, entrada_deslocamento_y)

	indicador.show()

	_tween_atual = create_tween()
	_tween_atual.set_parallel(true)
	_tween_atual.tween_property(self, "modulate:a", 1.0, entrada_duracao)
	_tween_atual.tween_property(self, "scale", Vector2.ONE, entrada_duracao)
	_tween_atual.tween_property(self, "position", _posicao_inicial, entrada_duracao)

	await get_tree().create_timer(entrada_duracao).timeout

	if not _fluxo_valido(fluxo_local):
		return

	_parar_tween_atual()

	modulate.a = 1.0
	scale = Vector2.ONE
	position = _posicao_inicial
	indicador.show()


func _animar_saida() -> void:
	_parar_tween_atual()

	_tween_atual = create_tween()
	_tween_atual.set_parallel(true)
	_tween_atual.tween_property(self, "modulate:a", 0.0, saida_duracao)
	_tween_atual.tween_property(self, "scale", saida_escala_final, saida_duracao)
	_tween_atual.tween_property(self, "position", _posicao_inicial + Vector2(0, saida_deslocamento_y), saida_duracao)

	await get_tree().create_timer(saida_duracao).timeout

	_parar_tween_atual()

	modulate.a = 0.0
	scale = saida_escala_final
	position = _posicao_inicial + Vector2(0, saida_deslocamento_y)


func _animar_texto(texto: String, fluxo_local: int) -> void:
	if not _fluxo_valido(fluxo_local):
		return

	_animando_texto = true
	_pular_digitacao = false
	indicador.show()

	var total_caracteres: int = texto.length()

	for i in range(total_caracteres + 1):
		if not _fluxo_valido(fluxo_local):
			return

		if not visible:
			break

		if _fechando:
			break

		if _pular_digitacao:
			text_label.visible_characters = total_caracteres
			break

		text_label.visible_characters = i

		if velocidade_texto > 0.0:
			await get_tree().create_timer(velocidade_texto).timeout
		else:
			await get_tree().process_frame

	if not _fluxo_valido(fluxo_local):
		return

	text_label.visible_characters = total_caracteres

	_animando_texto = false
	_pular_digitacao = false
	indicador.show()


func _atualizar_indicador() -> void:
	var bg_size: Vector2 = bg_dialog_box.size
	var ind_size: Vector2 = indicador.size

	indicador.position.x = bg_dialog_box.position.x + (bg_size.x * 0.5) - (ind_size.x * 0.5)
	indicador.position.y = bg_dialog_box.position.y + bg_size.y - 1.0


func _fluxo_valido(fluxo_local: int) -> bool:
	if not is_inside_tree():
		return false

	if fluxo_local != _fluxo_id:
		return false

	return true


func _parar_tween_atual() -> void:
	if _tween_atual != null:
		if _tween_atual.is_valid():
			_tween_atual.kill()

	_tween_atual = null


func _exit_tree() -> void:
	_fluxo_id += 1
	_parar_tween_atual()
