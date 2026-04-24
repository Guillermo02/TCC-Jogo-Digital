extends Node2D

func _ready():
	$AnimatedSprite2D.visible = false
	_loop_particula()

func _loop_particula() -> void:
	while true:
		await get_tree().create_timer(5.0).timeout
		$AnimatedSprite2D.visible = true
		$AnimatedSprite2D.play("particula_refletor2")
		await $AnimatedSprite2D.animation_finished
		$AnimatedSprite2D.visible = false
