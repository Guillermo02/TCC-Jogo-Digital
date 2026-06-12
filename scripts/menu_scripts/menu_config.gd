extends Control

const CENA_TELA_INICIAL: String = "res://scenes/menus/Inicio_jogo.tscn"

const ICONE_SAVE_TEXTURE: Texture2D = preload("res://UI/HUD_Mono/save.png")
const FONTE_PIXEL: FontFile = preload("res://fonts/PixelifySans-SemiBold.ttf")

@export var feedback_margem: Vector2 = Vector2(20, 18)
@export var feedback_tamanho_caixa: Vector2 = Vector2(175, 40)
@export var feedback_largura_label: float = 110.0
@export var feedback_tamanho_icone: Vector2 = Vector2(22, 22)
@export var feedback_tamanho_fonte: int = 18
@export var feedback_espaco_entre_texto_e_icone: int = 8

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

var tween_feedback_save: Tween = null

var feedback_panel: PanelContainer = null
var feedback_label: Label = null
var feedback_icone: TextureRect = null


func _ready() -> void:
	visible = false

	menu_principal.visible = true
	painel_configuracoes.visible = false

	criar_feedback_save()

	if get_viewport() != null and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	if not btn_voltar_jogo.pressed.is_connected(_on_btn_voltar_jogo_pressed):
		btn_voltar_jogo.pressed.connect(_on_btn_voltar_jogo_pressed)

	if not btn_salvar_jogo.pressed.is_connected(_on_btn_salvar_jogo_pressed):
		btn_salvar_jogo.pressed.connect(_on_btn_salvar_jogo_pressed)

	if not btn_configuracoes.pressed.is_connected(_on_btn_configuracoes_pressed):
		btn_configuracoes.pressed.connect(_on_btn_configuracoes_pressed)

	if not btn_tela_inicial.pressed.is_connected(_on_btn_tela_inicial_pressed):
		btn_tela_inicial.pressed.connect(_on_btn_tela_inicial_pressed)

	if not btn_sair.pressed.is_connected(_on_btn_sair_pressed):
		btn_sair.pressed.connect(_on_btn_sair_pressed)

	if not btn_voltar_config.pressed.is_connected(_on_btn_voltar_config_pressed):
		btn_voltar_config.pressed.connect(_on_btn_voltar_config_pressed)

	if not option_daltonismo.item_selected.is_connected(_on_option_daltonismo_item_selected):
		option_daltonismo.item_selected.connect(_on_option_daltonismo_item_selected)

	_configurar_opcoes_daltonismo()
	_estilizar_option_button_daltonismo()

	call_deferred("aplicar_filtro_daltonismo_salvo")
	call_deferred("reposicionar_feedback_save")


func criar_feedback_save() -> void:
	if feedback_panel != null and is_instance_valid(feedback_panel):
		return

	feedback_panel = PanelContainer.new()
	feedback_panel.name = "FeedbackSavePanel"
	feedback_panel.top_level = true
	feedback_panel.z_index = 4096
	feedback_panel.z_as_relative = false
	feedback_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_panel.visible = false
	feedback_panel.modulate.a = 0.0
	feedback_panel.custom_minimum_size = feedback_tamanho_caixa
	feedback_panel.size = feedback_tamanho_caixa

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.28)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	feedback_panel.add_theme_stylebox_override("panel", style)

	add_child(feedback_panel)

	var hbox := HBoxContainer.new()
	hbox.name = "FeedbackSaveHBox"
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", feedback_espaco_entre_texto_e_icone)
	feedback_panel.add_child(hbox)

	feedback_icone = TextureRect.new()
	feedback_icone.name = "IconeSalvar"
	feedback_icone.texture = ICONE_SAVE_TEXTURE
	feedback_icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_icone.custom_minimum_size = feedback_tamanho_icone
	feedback_icone.size = feedback_tamanho_icone
	feedback_icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feedback_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(feedback_icone)

	feedback_label = Label.new()
	feedback_label.name = "LabelJogoSalvo"
	feedback_label.text = "Jogo salvo"
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.custom_minimum_size = Vector2(feedback_largura_label, feedback_tamanho_caixa.y - 8)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	feedback_label.add_theme_font_override("font", FONTE_PIXEL)
	feedback_label.add_theme_font_size_override("font_size", feedback_tamanho_fonte)
	feedback_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	hbox.add_child(feedback_label)

	reposicionar_feedback_save()


func reposicionar_feedback_save() -> void:
	if feedback_panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size

	feedback_panel.size = feedback_tamanho_caixa
	feedback_panel.position = Vector2(
		viewport_size.x - feedback_margem.x - feedback_tamanho_caixa.x,
		viewport_size.y - feedback_margem.y - feedback_tamanho_caixa.y
	)


func _on_viewport_size_changed() -> void:
	reposicionar_feedback_save()


func aplicar_filtro_daltonismo_salvo() -> void:
	aplicar_filtro_daltonismo(GameManager.colorblind_mode)


func aplicar_filtro_daltonismo(modo: int) -> void:
	var filtro: Node = get_tree().root.get_node_or_null("Main/UI/ColorblindFilter")

	if filtro == null:
		push_warning("ColorblindFilter não encontrado em Main/UI.")
		return

	if filtro.has_method("aplicar_modo"):
		filtro.aplicar_modo(modo)


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
	btn_configuracoes.disabled = not habilitado
	btn_tela_inicial.disabled = not habilitado
	btn_sair.disabled = not habilitado
	btn_voltar_config.disabled = not habilitado

	if habilitado:
		atualizar_botao_salvar()
	else:
		btn_salvar_jogo.disabled = true


func atualizar_botao_salvar() -> void:
	var main: Node = get_tree().root.get_node_or_null("Main")
	var pode_salvar: bool = false

	if main != null and main.has_method("pode_salvar_jogo_atual"):
		pode_salvar = main.pode_salvar_jogo_atual()

	btn_salvar_jogo.disabled = not pode_salvar

	if pode_salvar:
		btn_salvar_jogo.modulate = Color(1, 1, 1, 1)
		btn_salvar_jogo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		btn_salvar_jogo.modulate = Color(0.45, 0.45, 0.45, 1)
		btn_salvar_jogo.mouse_default_cursor_shape = Control.CURSOR_ARROW


func abrir_menu() -> void:
	visible = true
	aberto = true
	abriu_direto_em_configuracoes = false

	menu_principal.visible = true
	painel_configuracoes.visible = false

	atualizar_botao_salvar()
	reposicionar_feedback_save()

	get_tree().paused = true


func abrir_configuracoes_direto() -> void:
	visible = true
	aberto = false
	abriu_direto_em_configuracoes = true

	menu_principal.visible = false
	painel_configuracoes.visible = true

	reposicionar_feedback_save()


func fechar_menu() -> void:
	visible = false
	aberto = false
	abriu_direto_em_configuracoes = false

	painel_configuracoes.visible = false
	menu_principal.visible = true

	esconder_feedback_save_imediato()

	get_tree().paused = false


func esconder_feedback_save_imediato() -> void:
	_matar_tween_feedback()

	if feedback_panel != null:
		feedback_panel.visible = false
		feedback_panel.modulate.a = 0.0
		feedback_panel.scale = Vector2.ONE


func mostrar_feedback_salvo() -> void:
	if feedback_panel == null:
		return

	_matar_tween_feedback()
	reposicionar_feedback_save()

	feedback_panel.visible = true
	feedback_panel.modulate.a = 1.0
	feedback_panel.scale = Vector2.ONE

	tween_feedback_save = create_tween()
	tween_feedback_save.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween_feedback_save.tween_interval(1.5)
	tween_feedback_save.tween_property(feedback_panel, "modulate:a", 0.0, 0.35)

	tween_feedback_save.tween_callback(func():
		if feedback_panel != null:
			feedback_panel.visible = false
			feedback_panel.modulate.a = 0.0
			feedback_panel.scale = Vector2.ONE

		tween_feedback_save = null
	)


func _configurar_opcoes_daltonismo() -> void:
	option_daltonismo.clear()
	option_daltonismo.add_item("Nenhum", 0)
	option_daltonismo.add_item("Protanopia", 1)
	option_daltonismo.add_item("Deuteranopia", 2)
	option_daltonismo.add_item("Tritanopia", 3)

	option_daltonismo.select(GameManager.colorblind_mode)


func _estilizar_option_button_daltonismo() -> void:
	var popup: PopupMenu = option_daltonismo.get_popup()

	popup.add_theme_font_override("font", FONTE_PIXEL)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color(1, 1, 1, 1))


func _on_btn_voltar_jogo_pressed() -> void:
	if transicao_em_andamento:
		return

	fechar_menu()


func _on_btn_salvar_jogo_pressed() -> void:
	if transicao_em_andamento:
		return

	var main: Node = get_tree().root.get_node_or_null("Main")

	if main == null:
		push_error("Main não encontrado.")
		return

	if not main.has_method("salvar_jogo"):
		push_error("Main não possui salvar_jogo().")
		return

	if not main.has_method("pode_salvar_jogo_atual"):
		push_error("Main não possui pode_salvar_jogo_atual().")
		return

	if not main.pode_salvar_jogo_atual():
		atualizar_botao_salvar()
		return

	var salvou: bool = main.salvar_jogo()

	if salvou:
		mostrar_feedback_salvo()

	atualizar_botao_salvar()


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

	esconder_feedback_save_imediato()

	var main: Node = get_tree().root.get_node_or_null("Main")

	if main == null:
		push_error("Main não encontrado.")
		transicao_em_andamento = false
		_set_botoes_habilitados(true)
		return

	if main.has_method("voltar_para_tela_inicial"):
		await main.voltar_para_tela_inicial()
	elif main.has_method("load_scene_with_fade"):
		await main.load_scene_with_fade(CENA_TELA_INICIAL)
	else:
		push_error("Main não possui método de troca para tela inicial.")

	transicao_em_andamento = false
	_set_botoes_habilitados(true)


func _on_btn_sair_pressed() -> void:
	if transicao_em_andamento:
		return

	get_tree().quit()


func _on_option_daltonismo_item_selected(index: int) -> void:
	GameManager.set_colorblind_mode(index)
	aplicar_filtro_daltonismo(index)


func _matar_tween_feedback() -> void:
	if tween_feedback_save != null:
		if tween_feedback_save.is_valid():
			tween_feedback_save.kill()

	tween_feedback_save = null


func _exit_tree() -> void:
	_matar_tween_feedback()
