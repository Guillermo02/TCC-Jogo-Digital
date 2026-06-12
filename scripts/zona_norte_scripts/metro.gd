extends Sprite2D

@export var metro_y: float = 205.0
@export var start_offset_x: float = 900.0
@export var end_offset_x: float = -900.0
@export var speed: float = 120.0
@export var interval: float = 4.0

# 1.0 = acompanha a câmera normalmente no início da passagem
# menor que 1.0 = parece mais ao fundo
@export var parallax_factor: float = 1.0

var camera: Camera2D = null

var moving: bool = false
var wait_time: float = 0.0

var metro_world_x: float = 0.0
var metro_end_world_x: float = 0.0


func _ready() -> void:
	visible = false
	wait_time = maxf(interval, 0.0)
	camera = get_viewport().get_camera_2d()


func _process(delta: float) -> void:
	if not moving:
		wait_time -= delta

		if wait_time <= 0.0:
			_start_pass()

		return

	metro_world_x -= maxf(speed, 0.0) * delta
	global_position = Vector2(metro_world_x, metro_y)

	if metro_world_x <= metro_end_world_x:
		_end_pass()


func _start_pass() -> void:
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()

	var camera_x := 0.0

	if camera != null:
		camera_x = camera.global_position.x * parallax_factor

	metro_world_x = camera_x + start_offset_x
	metro_end_world_x = camera_x + end_offset_x

	moving = true
	visible = true

	global_position = Vector2(metro_world_x, metro_y)


func _end_pass() -> void:
	moving = false
	visible = false
	wait_time = maxf(interval, 0.0)
