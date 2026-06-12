extends Area2D

@export_multiline var texto_carta: String = """Pai, sei que vai ler isso...

Deixei esta carta escondida.
A corrupção nessa cidade vai além
da fábrica.

Encontrei provas, mas eles me viram.
Se eu sumir, procure na zona norte
da cidade, pelo visto o prefeito quer
conquistar aquela região.

Não confie nos homens dele.

Estou com medo...
mas precisava fazer isso.

Eu te amo.
Liz"""

@onready var carta_ui: Control = $"../CanvasLayer/TutorialUI"
@onready var texto_ui: Node = $"../CanvasLayer/TutorialUI/Papel/Texto"
@onready var indicador_e: Node2D = $"../E"

var jogador_ref: Node = null
var jogador_perto := false
var carta_aberta := false
var em_transicao := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	carta_ui.visible = false
	carta_ui.modulate.a = 0.0

	# O E fica visível o tempo todo.
	mostrar_indicador_e()

	atualizar_texto_carta()


func atualizar_texto_carta() -> void:
	if texto_ui == null:
		return

	if texto_ui.has_method("set_text"):
		texto_ui.set_text(texto_carta)
	else:
		texto_ui.set("text", texto_carta)


func _input(event: InputEvent) -> void:
	if em_transicao:
		return

	# Só abre se o jogador estiver dentro da AreaCarta,
	# mas o ícone E continua aparecendo sempre.
	if jogador_perto and not carta_aberta and event.is_action_pressed("interagir"):
		abrir_carta()
		get_viewport().set_input_as_handled()
		return

	if carta_aberta and event.is_action_pressed("ui_cancel"):
		fechar_carta()
		get_viewport().set_input_as_handled()
		return


func abrir_carta() -> void:
	if carta_aberta or em_transicao:
		return

	em_transicao = true
	carta_aberta = true

	mostrar_indicador_e()

	if jogador_ref != null and jogador_ref.has_method("set_pode_mover"):
		jogador_ref.set_pode_mover(false)

	carta_ui.visible = true
	carta_ui.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(carta_ui, "modulate:a", 1.0, 0.25)

	await tween.finished

	em_transicao = false


func fechar_carta() -> void:
	if not carta_aberta or em_transicao:
		return

	em_transicao = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(carta_ui, "modulate:a", 0.0, 0.25)

	await tween.finished

	carta_ui.visible = false
	carta_aberta = false

	if jogador_ref != null and jogador_ref.has_method("set_pode_mover"):
		jogador_ref.set_pode_mover(true)

	mostrar_indicador_e()

	em_transicao = false


func mostrar_indicador_e() -> void:
	if indicador_e == null:
		return

	if indicador_e.has_method("aparecer"):
		indicador_e.aparecer()
	else:
		indicador_e.show()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	jogador_ref = body
	jogador_perto = true


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	jogador_perto = false
