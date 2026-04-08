extends Node2D

@export var id = 2
var ocupado = false

func _input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		get_tree().current_scene.tentar_conectar(self)

func conectar(_fio):
	print("conectado!")
