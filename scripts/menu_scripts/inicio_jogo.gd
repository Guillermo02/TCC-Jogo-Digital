extends Control

const CENA_CONTINUAR: String = "res://scenes/fases/floresta.tscn"
const CENA_NOVO_JOGO: String = "res://scenes/fases/floresta.tscn"

@onready var btn_continuar: Button = %BtnContinuar
@onready var btn_novo_jogo: Button = %BtnNovoJogo
@onready var btn_configuracoes: Button = %BtnConfiguracoes
@onready var btn_sair: Button = %BtnSair

var transicao_em_andamento: bool = false

func _ready() -> void:
	if btn_continuar == null:
		push_error("BtnContinuar não encontrado.")
		return
	if btn_novo_jogo == null:
		push_error("BtnNovoJogo não encontrado.")
		return
	if btn_configuracoes == null:
		push_error("BtnConfiguracoes não encontrado.")
		return
	if btn_sair == null:
		push_error("BtnSair não encontrado.")
		return

	btn_continuar.pressed.connect(_on_btn_continuar_pressed)
	btn_novo_jogo.pressed.connect(_on_btn_novo_jogo_pressed)
	btn_configuracoes.pressed.connect(_on_btn_configuracoes_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)

	var menu_config = get_tree().root.get_node_or_null("Main/UI/MenuConfig")
	if menu_config != null:
		menu_config.permitir_atalho_escape = false

func _set_botoes_habilitados(habilitado: bool) -> void:
	btn_continuar.disabled = not habilitado
	btn_novo_jogo.disabled = not habilitado
	btn_configuracoes.disabled = not habilitado
	btn_sair.disabled = not habilitado

func _trocar_cena_com_fade(scene_path: String) -> void:
	if transicao_em_andamento:
		return

	transicao_em_andamento = true
	_set_botoes_habilitados(false)

	var main = get_tree().root.get_node_or_null("Main")
	if main == null:
		push_error("Nó 'Main' não encontrado. Rode o projeto com F5 usando main.tscn.")
		transicao_em_andamento = false
		_set_botoes_habilitados(true)
		return

	var menu_config = get_tree().root.get_node_or_null("Main/UI/MenuConfig")
	if menu_config != null:
		menu_config.permitir_atalho_escape = true

	await main.load_scene_with_fade(scene_path)

	transicao_em_andamento = false
	_set_botoes_habilitados(true)

func _on_btn_continuar_pressed() -> void:
	await _trocar_cena_com_fade(CENA_CONTINUAR)

func _on_btn_novo_jogo_pressed() -> void:
	await _trocar_cena_com_fade(CENA_NOVO_JOGO)

func _on_btn_configuracoes_pressed() -> void:
	if transicao_em_andamento:
		return

	var menu_config = get_tree().root.get_node_or_null("Main/UI/MenuConfig")
	if menu_config == null:
		push_error("MenuConfig não encontrado em Main/UI.")
		return

	menu_config.abrir_configuracoes_direto()

func _on_btn_sair_pressed() -> void:
	if transicao_em_andamento:
		return

	get_tree().quit()
