extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var interaction_area = $Area2D

var player_near: bool = false


func _ready() -> void:
	sprite.play("idle")
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interagir"):
		talk()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false

func talk() -> void:
	print("NPC: Olá! Vamos conversar.")
