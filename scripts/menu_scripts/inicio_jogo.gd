extends Control

@onready var btn_continuar: Button = %BtnContinuar
@onready var btn_novo_jogo: Button = %BtnNovoJogo
@onready var btn_configuracoes: Button = %BtnConfiguracoes
@onready var btn_sair: Button = %BtnSair

var transicao_em_andamento: bool = false


func _ready() -> void:
	if not validar_botoes():
		return

	conectar_botoes()
	set_permitir_atalho_escape_menu_config(false)
	atualizar_botao_continuar()


func validar_botoes() -> bool:
	if btn_continuar == null:
		push_error("BtnContinuar não encontrado.")
		return false

	if btn_novo_jogo == null:
		push_error("BtnNovoJogo não encontrado.")
		return false

	if btn_configuracoes == null:
		push_error("BtnConfiguracoes não encontrado.")
		return false

	if btn_sair == null:
		push_error("BtnSair não encontrado.")
		return false

	return true


func conectar_botoes() -> void:
	if not btn_continuar.pressed.is_connected(_on_btn_continuar_pressed):
		btn_continuar.pressed.connect(_on_btn_continuar_pressed)

	if not btn_novo_jogo.pressed.is_connected(_on_btn_novo_jogo_pressed):
		btn_novo_jogo.pressed.connect(_on_btn_novo_jogo_pressed)

	if not btn_configuracoes.pressed.is_connected(_on_btn_configuracoes_pressed):
		btn_configuracoes.pressed.connect(_on_btn_configuracoes_pressed)

	if not btn_sair.pressed.is_connected(_on_btn_sair_pressed):
		btn_sair.pressed.connect(_on_btn_sair_pressed)


func atualizar_botao_continuar() -> void:
	if btn_continuar == null:
		return

	var tem_save := SaveManager.has_save()

	btn_continuar.disabled = not tem_save

	if tem_save:
		btn_continuar.modulate = Color(1, 1, 1, 1)
		btn_continuar.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_continuar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		btn_continuar.modulate = Color(0.502, 0.502, 0.502, 0.682)
		btn_continuar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_continuar.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _set_botoes_habilitados(habilitado: bool) -> void:
	if btn_novo_jogo != null:
		btn_novo_jogo.disabled = not habilitado

	if btn_configuracoes != null:
		btn_configuracoes.disabled = not habilitado

	if btn_sair != null:
		btn_sair.disabled = not habilitado

	if btn_continuar == null:
		return

	if habilitado:
		atualizar_botao_continuar()
	else:
		btn_continuar.disabled = true


func _pegar_main() -> Node:
	var main := get_tree().root.get_node_or_null("Main")

	if main == null:
		push_error("Nó 'Main' não encontrado. Rode o projeto com F5 usando main.tscn.")

	return main


func pegar_menu_config() -> Node:
	return get_tree().root.get_node_or_null("Main/UI/MenuConfig")


func set_permitir_atalho_escape_menu_config(permitir: bool) -> void:
	var menu_config := pegar_menu_config()

	if menu_config != null:
		menu_config.permitir_atalho_escape = permitir


func iniciar_transicao_menu() -> void:
	transicao_em_andamento = true
	_set_botoes_habilitados(false)
	set_permitir_atalho_escape_menu_config(true)


func finalizar_transicao_menu() -> void:
	if not is_inside_tree():
		return

	transicao_em_andamento = false
	_set_botoes_habilitados(true)


func _on_btn_continuar_pressed() -> void:
	if transicao_em_andamento:
		return

	if not SaveManager.has_save():
		atualizar_botao_continuar()
		return

	var main := _pegar_main()

	if main == null:
		return

	iniciar_transicao_menu()

	if main.has_method("continuar_jogo"):
		await main.continuar_jogo()
	else:
		push_error("Main não possui continuar_jogo().")

	finalizar_transicao_menu()


func _on_btn_novo_jogo_pressed() -> void:
	if transicao_em_andamento:
		return

	var main := _pegar_main()

	if main == null:
		return

	iniciar_transicao_menu()

	if main.has_method("novo_jogo"):
		await main.novo_jogo()
	else:
		push_error("Main não possui novo_jogo().")

	finalizar_transicao_menu()


func _on_btn_configuracoes_pressed() -> void:
	if transicao_em_andamento:
		return

	var menu_config := pegar_menu_config()

	if menu_config == null:
		push_error("MenuConfig não encontrado em Main/UI.")
		return

	menu_config.abrir_configuracoes_direto()


func _on_btn_sair_pressed() -> void:
	if transicao_em_andamento:
		return

	get_tree().quit()
