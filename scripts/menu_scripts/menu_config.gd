extends Control

const CENA_TELA_INICIAL: String = "res://scenes/menus/Inicio_jogo.tscn"

@onready var menu_principal: VBoxContainer = %MenuPrincipal
@onready var painel_configuracoes: VBoxContainer = %PainelConfiguracoes

@onready var btn_voltar_jogo: Button = %BtnVoltarJogo
@onready var btn_salvar_jogo: Button = %BtnSalvarJogo
@onready var btn_configuracoes: Button = %BtnConfiguracoes
@onready var btn_tela_inicial: Button = %BtnTelaInicial
@onready var btn_sair: Button = %BtnSair

@onready var option_daltonismo: OptionButton = %OptionButtonDaltonismo
@onready var btn_voltar_config: Button = %BtnVoltarConfig

var aberto: bool = false
var abriu_direto_em_configuracoes: bool = false
var permitir_atalho_escape: bool = true
var transicao_em_andamento: bool = false

func _ready() -> void:
	visible = false

	menu_principal.visible = true
	painel_configuracoes.visible = false

	btn_voltar_jogo.pressed.connect(_on_btn_voltar_jogo_pressed)
	btn_salvar_jogo.pressed.connect(_on_btn_salvar_jogo_pressed)
	btn_configuracoes.pressed.connect(_on_btn_configuracoes_pressed)
	btn_tela_inicial.pressed.connect(_on_btn_tela_inicial_pressed)
	btn_sair.pressed.connect(_on_btn_sair_pressed)
	btn_voltar_config.pressed.connect(_on_btn_voltar_config_pressed)

	option_daltonismo.item_selected.connect(_on_option_daltonismo_item_selected)

	_configurar_opcoes_daltonismo()
	_estilizar_option_button_daltonismo()

func _unhandled_input(event: InputEvent) -> void:
	if transicao_em_andamento:
		return

	if not permitir_atalho_escape:
		return

	if event.is_action_pressed("ui_cancel"):
		if aberto:
			fechar_menu()
		else:
			abrir_menu()

func _set_botoes_habilitados(habilitado: bool) -> void:
	btn_voltar_jogo.disabled = not habilitado
	btn_salvar_jogo.disabled = not habilitado
	btn_configuracoes.disabled = not habilitado
	btn_tela_inicial.disabled = not habilitado
	btn_sair.disabled = not habilitado
	btn_voltar_config.disabled = not habilitado

func abrir_menu() -> void:
	visible = true
	aberto = true
	abriu_direto_em_configuracoes = false

	menu_principal.visible = true
	painel_configuracoes.visible = false

	get_tree().paused = true

func abrir_configuracoes_direto() -> void:
	visible = true
	aberto = false
	abriu_direto_em_configuracoes = true

	menu_principal.visible = false
	painel_configuracoes.visible = true

func fechar_menu() -> void:
	visible = false
	aberto = false
	abriu_direto_em_configuracoes = false

	painel_configuracoes.visible = false
	menu_principal.visible = true

	get_tree().paused = false

func _configurar_opcoes_daltonismo() -> void:
	option_daltonismo.clear()
	option_daltonismo.add_item("Nenhum", 0)
	option_daltonismo.add_item("Protanopia", 1)
	option_daltonismo.add_item("Deuteranopia", 2)
	option_daltonismo.add_item("Tritanopia", 3)

	option_daltonismo.select(GameManager.colorblind_mode)

func _estilizar_option_button_daltonismo() -> void:
	var popup := option_daltonismo.get_popup()

	var fonte_pixel = preload("res://fonts/PixelifySans-SemiBold.ttf")

	popup.add_theme_font_override("font", fonte_pixel)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _on_btn_voltar_jogo_pressed() -> void:
	if transicao_em_andamento:
		return

	fechar_menu()

func _on_btn_salvar_jogo_pressed() -> void:
	if transicao_em_andamento:
		return

	print("Salvar jogo ainda não implementado.")

func _on_btn_configuracoes_pressed() -> void:
	if transicao_em_andamento:
		return

	menu_principal.visible = false
	painel_configuracoes.visible = true

func _on_btn_voltar_config_pressed() -> void:
	if transicao_em_andamento:
		return

	if abriu_direto_em_configuracoes:
		visible = false
		abriu_direto_em_configuracoes = false
		painel_configuracoes.visible = false
		menu_principal.visible = true
	else:
		painel_configuracoes.visible = false
		menu_principal.visible = true

func _on_btn_tela_inicial_pressed() -> void:
	if transicao_em_andamento:
		return

	transicao_em_andamento = true
	_set_botoes_habilitados(false)

	get_tree().paused = false
	aberto = false
	abriu_direto_em_configuracoes = false
	visible = false
	painel_configuracoes.visible = false
	menu_principal.visible = true
	permitir_atalho_escape = false

	var main = get_tree().root.get_node_or_null("Main")
	if main == null:
		push_error("Main não encontrado.")
		transicao_em_andamento = false
		_set_botoes_habilitados(true)
		return

	await main.load_scene_with_fade(CENA_TELA_INICIAL)

	transicao_em_andamento = false
	_set_botoes_habilitados(true)

func _on_btn_sair_pressed() -> void:
	if transicao_em_andamento:
		return

	get_tree().quit()

func _on_option_daltonismo_item_selected(index: int) -> void:
	print("OptionButton mudou para índice:", index)

	GameManager.colorblind_mode = index

	var filtro = get_tree().root.get_node_or_null("Main/UI/ColorblindFilter")
	if filtro == null:
		push_error("ColorblindFilter não encontrado em Main/UI.")
		return

	print("Filtro encontrado:", filtro.name)
	filtro.aplicar_modo(index)
