extends Area2D

var jogador_perto = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		jogador_perto = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		jogador_perto = false

func _input(event):
	if jogador_perto and event.is_action_pressed("interagir"):
		abrir_puzzle()

func abrir_puzzle():
	var puzzle = preload("res://scenes/puzzles/puzzle_fios3.tscn").instantiate()
	get_tree().current_scene.add_child(puzzle)
	get_tree().paused = true
