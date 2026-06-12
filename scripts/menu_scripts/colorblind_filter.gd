extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var modo_atual: int = -1


func _ready() -> void:
	aplicar_modo(GameManager.colorblind_mode)


func aplicar_modo(mode: int) -> void:
	var novo_modo: int = clampi(mode, 0, 3)

	if modo_atual == novo_modo:
		return

	modo_atual = novo_modo
	GameManager.colorblind_mode = novo_modo

	if color_rect == null:
		return

	if color_rect.material == null:
		push_warning("ColorRect sem material no ColorblindFilter.")
		return

	color_rect.material.set_shader_parameter("mode", novo_modo)
	color_rect.queue_redraw()
