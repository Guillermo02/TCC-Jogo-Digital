extends Area2D

@onready var tutorial_ui = $"../../CanvasLayer/TutorialUI"
@onready var jogador = $"../../Jogador"

var jogador_perto := false
var tutorial_aberto := false
var em_transicao := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	tutorial_ui.visible = false
	tutorial_ui.modulate.a = 0.0

func _input(event: InputEvent) -> void:
	if em_transicao:
		return

	if jogador_perto and not tutorial_aberto and event.is_action_pressed("interagir"):
		abrir_tutorial()
		get_viewport().set_input_as_handled()
		return

	if tutorial_aberto and event.is_action_pressed("ui_cancel"):
		fechar_tutorial()
		get_viewport().set_input_as_handled()
		return

func abrir_tutorial() -> void:
	em_transicao = true
	tutorial_aberto = true
	tutorial_ui.visible = true
	tutorial_ui.modulate.a = 0.0
	jogador.set_pode_mover(false)

	var tween := create_tween()
	tween.tween_property(tutorial_ui, "modulate:a", 1.0, 0.25)

	await tween.finished
	em_transicao = false

func fechar_tutorial() -> void:
	em_transicao = true

	var tween := create_tween()
	tween.tween_property(tutorial_ui, "modulate:a", 0.0, 0.25)

	await tween.finished

	tutorial_ui.visible = false
	tutorial_aberto = false
	jogador.set_pode_mover(true)
	em_transicao = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		jogador_perto = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		jogador_perto = false
