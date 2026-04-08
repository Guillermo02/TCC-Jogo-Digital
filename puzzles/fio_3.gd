extends Node2D

@export var id = 3
var conectado = false

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		conectado = true
		get_tree().current_scene.selecionar_fio(self)
		print("clicou no fio")

func _on_mouse_entered():
	if not conectado:
		modulate = Color(1.3, 1.3, 1.3)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)
