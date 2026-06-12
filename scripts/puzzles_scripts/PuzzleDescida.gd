extends CanvasLayer

signal puzzle_resolvido
signal puzzle_cancelado

var primeiro_ponto = null
var segundo_ponto = null
var puzzle_completo = false
var numero_do_puzzle = 1

var fechando_puzzle := false
var puzzle_aberto := false

@onready var overlay: Control = $Overlay
@onready var puzzle_ui: Control = $puzzleUI
@onready var fios: Node = $puzzleUI/fios


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("puzzle_descida")

	get_tree().paused = false

	visible = false
	overlay.visible = false
	puzzle_ui.visible = false
	puzzle_ui.modulate.a = 0.0

	_configurar_mouse_filter_recursivo(overlay)
	_configurar_mouse_filter_recursivo(puzzle_ui)

	for fio in fios.get_children():
		if fio is Area2D:
			fio.input_pickable = true
			fio.process_mode = Node.PROCESS_MODE_ALWAYS


func _configurar_mouse_filter_recursivo(no: Node) -> void:
	if no is Control:
		no.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for filho in no.get_children():
		_configurar_mouse_filter_recursivo(filho)


func abrir_puzzle() -> void:
	if puzzle_completo:
		return

	if puzzle_aberto or fechando_puzzle:
		return

	puzzle_aberto = true
	fechando_puzzle = false

	visible = true
	overlay.visible = true
	puzzle_ui.visible = true
	puzzle_ui.modulate.a = 0.0

	await get_tree().process_frame

	get_tree().paused = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(puzzle_ui, "modulate:a", 1.0, 0.35)

	await tween.finished


func _input(event: InputEvent) -> void:
	if not puzzle_aberto:
		return

	if fechando_puzzle:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		await sair_do_puzzle(false)


func selecionar_ponto(ponto) -> void:
	if not puzzle_aberto:
		return

	if fechando_puzzle:
		return

	if puzzle_completo:
		return

	if ponto.conectado:
		return

	if primeiro_ponto == ponto:
		return

	if primeiro_ponto == null:
		primeiro_ponto = ponto
		ponto.definir_pressionado()
		print("Primeiro selecionado: ", ponto.nome_fio)
		return

	if segundo_ponto == null:
		segundo_ponto = ponto
		ponto.definir_pressionado()
		print("Segundo selecionado: ", ponto.nome_fio)
		await validar_conexao()


func validar_conexao() -> void:
	if primeiro_ponto == null or segundo_ponto == null:
		return

	if primeiro_ponto == segundo_ponto:
		resetar_selecao()
		return

	if combinacao_correta(primeiro_ponto, segundo_ponto):
		await conectar_pontos(primeiro_ponto, segundo_ponto)
	else:
		print("Combinação errada!")
		await get_tree().create_timer(0.25).timeout
		resetar_selecao()


func combinacao_correta(ponto1, ponto2) -> bool:
	return ponto1.par_nome == ponto2.nome_fio and ponto2.par_nome == ponto1.nome_fio


func conectar_pontos(ponto1, ponto2) -> void:
	print("Conectado corretamente!")

	ponto1.conectado = true
	ponto2.conectado = true

	ponto1.definir_conectado()
	ponto2.definir_conectado()

	primeiro_ponto = null
	segundo_ponto = null

	await verificar_vitoria()


func resetar_selecao() -> void:
	if primeiro_ponto != null and not primeiro_ponto.conectado:
		primeiro_ponto.definir_normal()

	if segundo_ponto != null and not segundo_ponto.conectado:
		segundo_ponto.definir_normal()

	primeiro_ponto = null
	segundo_ponto = null


func verificar_vitoria() -> void:
	for no in fios.get_children():
		if no is Area2D and not no.conectado:
			return

	print("PUZZLE COMPLETO!")
	puzzle_completo = true
	await sair_do_puzzle(true)


func sair_do_puzzle(completou: bool = false) -> void:
	if fechando_puzzle:
		return

	fechando_puzzle = true

	resetar_selecao()

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(puzzle_ui, "modulate:a", 0.0, 0.35)

	await tween.finished

	get_tree().paused = false

	overlay.visible = false
	puzzle_ui.visible = false
	visible = false

	puzzle_aberto = false
	fechando_puzzle = false

	primeiro_ponto = null
	segundo_ponto = null

	if completou:
		puzzle_resolvido.emit()
	else:
		puzzle_cancelado.emit()
