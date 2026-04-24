extends AnimatedSprite2D

@export var speed_x := -35.0
@export var speed_y := 65.0
@export var limite_baixo := 400.0
@export var topo_reset := -34.0
@export var largura_area := 927.0

var tempo := 0.0
var x_inicial := 0.0

func _ready():
	play("default")
	x_inicial = position.x
	randomize()
	tempo = randf_range(0.0, TAU)

func _process(delta):
	tempo += delta
	position.x += speed_x * delta + sin(tempo * 3.0) * 10.0 * delta
	position.y += speed_y * delta
	rotation = sin(tempo * 4.0) * 0.25

	if position.y > limite_baixo:
		position.y = topo_reset
		position.x = randf_range(0.0, largura_area)
		tempo = randf_range(0.0, TAU)
