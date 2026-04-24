extends Node

@onready var world: Node = $World

var current_scene: Node = null

var fade_layer: CanvasLayer
var fade_rect: ColorRect
var transicao_em_andamento: bool = false

func _ready() -> void:
	_criar_fade_overlay()
	load_scene("res://scenes/menus/Inicio_jogo.tscn")

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
	fade_rect.offset_left = 0
	fade_rect.offset_top = 0
	fade_rect.offset_right = 0
	fade_rect.offset_bottom = 0
	fade_rect.modulate.a = 0.0
	fade_layer.add_child(fade_rect)

func load_scene(scene_path: String) -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null

	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Não foi possível carregar a cena: " + scene_path)
		return

	current_scene = packed_scene.instantiate()
	world.add_child(current_scene)

func load_scene_with_fade(scene_path: String, duracao_fade_out: float = 0.35, duracao_fade_in: float = 0.35) -> void:
	if transicao_em_andamento:
		return

	transicao_em_andamento = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade_para_preto(duracao_fade_out)
	load_scene(scene_path)
	await get_tree().process_frame
	await _fade_do_preto(duracao_fade_in)

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transicao_em_andamento = false

func _fade_para_preto(duracao: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 1.0, duracao)
	await tween.finished

func _fade_do_preto(duracao: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 0.0, duracao)
	await tween.finished
