extends Area2D

@export var nome_fio: String = "3"
@export var par_nome: String = "C"

@export var sprite_normal: Texture2D
@export var sprite_pressionado: Texture2D
@export var sprite_conectado: Texture2D

var conectado = false

@onready var sprite = $Sprite2D

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	definir_normal()

func _input_event(_viewport, event, _shape_idx):
	if conectado:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_parent().get_parent().selecionar_ponto(self)

func definir_normal():
	if sprite_normal != null:
		sprite.texture = sprite_normal

func definir_pressionado():
	if sprite_pressionado != null:
		sprite.texture = sprite_pressionado

func definir_conectado():
	if sprite_conectado != null:
		sprite.texture = sprite_conectado

func _on_mouse_entered():
	if not conectado:
		modulate = Color(1.15, 1.15, 1.15)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)
