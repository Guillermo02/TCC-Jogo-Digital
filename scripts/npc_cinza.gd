extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var area = $Area2D

@export var dialogo_npc: Array[String] = [
	"Olá!"
]

func _ready() -> void:
	sprite.play("idle")
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("NPC falou:")
		for fala in dialogo_npc:
			print(fala)
