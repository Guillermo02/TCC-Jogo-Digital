extends Node2D

@onready var sprite = $AnimatedSprite2D
@onready var area = $Area2D
@onready var label = $Label

@export var dialogo_npc: Array[String] = []

var jogador_perto := false

func _ready() -> void:
	sprite.play("idle")
	label.visible = false
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta):
	if jogador_perto and Input.is_action_just_pressed("interagir"):
		mostrar_dialogo()

func _on_body_entered(body):
	if body.is_in_group("player"):
		jogador_perto = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		jogador_perto = false
		label.visible = false

func mostrar_dialogo():
	if dialogo_npc.size() > 0:
		label.text = dialogo_npc[0]
		label.visible = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
