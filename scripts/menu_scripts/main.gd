extends Node

@onready var world: Node = $World

var current_scene: Node = null
var current_scene_path: String = ""

var fade_layer: CanvasLayer
var fade_rect: ColorRect
var transicao_em_andamento: bool = false
var fade_tween: Tween = null

var cenas_sem_hud := [
	"res://scenes/menus/Inicio_jogo.tscn",
	"res://scenes/fases/floresta.tscn",
	"res://scenes/fases/CasaElliot.tscn",
	"res://scenes/fases/CasaElliot2.tscn"
]


func _ready() -> void:
	add_to_group("scene_manager")
	_criar_fade_overlay()
	await load_scene("res://scenes/menus/Inicio_jogo.tscn")


func _criar_fade_overlay() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.name = "FadeLayer"
	fade_layer.layer = 100
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)

	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.process_mode = Node.PROCESS_MODE_ALWAYS
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.modulate.a = 0.0
	fade_layer.add_child(fade_rect)


func load_scene(scene_path: String) -> bool:
	get_tree().paused = false

	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
		await get_tree().process_frame

	var packed_scene := load(scene_path) as PackedScene

	if packed_scene == null:
		push_error("Não foi possível carregar a cena: " + scene_path)
		return false

	current_scene = packed_scene.instantiate()
	current_scene_path = scene_path
	world.add_child(current_scene)

	await get_tree().process_frame

	atualizar_visibilidade_hud(scene_path)
	atualizar_estado_menu_config(scene_path)

	return true


func atualizar_visibilidade_hud(scene_path: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	hud.visible = not cenas_sem_hud.has(scene_path)


func atualizar_estado_menu_config(scene_path: String) -> void:
	var menu_config = get_tree().root.get_node_or_null("Main/UI/MenuConfig")

	if menu_config == null:
		return

	menu_config.permitir_atalho_escape = scene_path != "res://scenes/menus/Inicio_jogo.tscn"


func load_scene_with_fade(scene_path: String, duracao_fade_out: float = 0.35, duracao_fade_in: float = 0.35) -> void:
	if transicao_em_andamento:
		return

	transicao_em_andamento = true
	get_tree().paused = false

	if fade_rect != null:
		fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade_para_preto(duracao_fade_out)

	if not is_inside_tree():
		_finalizar_estado_transicao()
		return

	var carregou := await load_scene(scene_path)

	if not carregou:
		await _fade_do_preto(duracao_fade_in)
		_finalizar_estado_transicao()
		return

	if not is_inside_tree():
		_finalizar_estado_transicao()
		return

	await _fade_do_preto(duracao_fade_in)

	_finalizar_estado_transicao()


func _finalizar_estado_transicao() -> void:
	if fade_rect != null:
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	transicao_em_andamento = false
	get_tree().paused = false


func _fade_para_preto(duracao: float) -> void:
	if fade_rect == null:
		return

	_matar_fade_tween()

	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(fade_rect, "modulate:a", 1.0, duracao)

	await fade_tween.finished
	fade_tween = null


func _fade_do_preto(duracao: float) -> void:
	if fade_rect == null:
		return

	_matar_fade_tween()

	fade_tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(fade_rect, "modulate:a", 0.0, duracao)

	await fade_tween.finished
	fade_tween = null


func _matar_fade_tween() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = null


func novo_jogo() -> void:
	if transicao_em_andamento:
		return

	SaveManager.reset_save_for_new_game()
	await load_scene_with_fade(SaveManager.CENA_NOVO_JOGO, 0.8, 0.8)


func continuar_jogo() -> void:
	if transicao_em_andamento:
		return

	if not SaveManager.has_save():
		push_warning("Nenhum save encontrado para continuar.")
		return

	var scene_path := SaveManager.get_saved_scene_path()

	if scene_path == "":
		push_warning("Save encontrado, mas sem cena válida.")
		return

	await load_scene_with_fade(scene_path, 0.8, 0.8)


func salvar_jogo() -> bool:
	if current_scene_path == "":
		return false

	return SaveManager.save_game(current_scene_path)


func pode_salvar_jogo_atual() -> bool:
	if current_scene_path == "":
		return false

	return SaveManager.pode_salvar_cena(current_scene_path)


func voltar_para_tela_inicial() -> void:
	if transicao_em_andamento:
		return

	await load_scene_with_fade(SaveManager.CENA_INICIO, 0.8, 0.8)


func apagar_save() -> void:
	SaveManager.delete_save()


func _exit_tree() -> void:
	_matar_fade_tween()
	transicao_em_andamento = false
