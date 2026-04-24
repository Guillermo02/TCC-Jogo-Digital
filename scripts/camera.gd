extends Camera2D

@export var player_group: String = "player"
@export var follow_speed: float = 8.0

var player: Node2D = null


func _ready() -> void:
	var players := get_tree().get_nodes_in_group(player_group)
	
	if players.size() > 0:
		player = players[0] as Node2D
	else:
		push_warning("Nenhum nó encontrado no grupo '%s'." % player_group)


func _process(delta: float) -> void:
	if player == null:
		return
	
	var target_pos: Vector2 = player.global_position
	
	# Metade da área visível da câmera, considerando o zoom
	var half_screen: Vector2 = (get_viewport_rect().size * 0.5) * zoom
	
	# Impede a câmera de mostrar fora dos limites da fase
	target_pos.x = clamp(target_pos.x, limit_left + half_screen.x, limit_right - half_screen.x)
	target_pos.y = clamp(target_pos.y, limit_top + half_screen.y, limit_bottom - half_screen.y)
	
	# Suaviza o movimento da câmera
	global_position = global_position.lerp(target_pos, follow_speed * delta)
