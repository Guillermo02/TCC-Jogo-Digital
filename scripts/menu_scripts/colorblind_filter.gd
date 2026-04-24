extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	print("ColorblindFilter ready. Modo inicial:", GameManager.colorblind_mode)
	aplicar_modo(GameManager.colorblind_mode)

func aplicar_modo(mode: int) -> void:
	print("Aplicando modo no filtro:", mode)

	GameManager.colorblind_mode = mode

	if color_rect.material == null:
		push_error("ColorRect sem material no ColorblindFilter.")
		return

	color_rect.material.set_shader_parameter("mode", mode)
	color_rect.queue_redraw()
