extends AnimatedSprite2D

@export var velocidade: float = 95.0
var direcao := Vector2(1, -0.35).normalized()

var voando := false
var ja_ativou := false

func _ready():
	play("bird idle")

func _process(delta):
	if voando:
		position += direcao * velocidade * delta

func fugir():
	if ja_ativou:
		return
	
	ja_ativou = true
	voando = true
	play("bird walk")

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		fugir()
