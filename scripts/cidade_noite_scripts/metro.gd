extends Sprite2D

@export var metro_y: float = 190.0
@export var start_offset_x: float = 900.0
@export var end_offset_x: float = -900.0
@export var speed: float = 120.0
@export var interval: float = 4.0

# Quanto menor, mais "ao fundo" ele parece
@export var parallax_factor: float = 1.0

@onready var camera := get_viewport().get_camera_2d()

var metro_x: float
var moving: bool = false

func _ready() -> void:
	_start_loop()

func _process(delta: float) -> void:
	if moving:
		metro_x -= speed * delta
	
	var cam_x = camera.global_position.x
	
	# Aplica só parte do movimento da câmera
	global_position = Vector2(
		metro_x + cam_x * parallax_factor,
		metro_y
	)

func _start_loop() -> void:
	while true:
		moving = false
		visible = false
		
		var cam_x = camera.global_position.x
		metro_x = cam_x + start_offset_x
		
		await get_tree().create_timer(interval).timeout
		
		visible = true
		moving = true
		
		while metro_x > cam_x + end_offset_x:
			await get_tree().process_frame
		
		moving = false
