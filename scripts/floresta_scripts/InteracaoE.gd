extends Sprite2D

var posicao_inicial: Vector2

func _ready() -> void:
	posicao_inicial = position
	animar()

func animar() -> void:
	var tween := create_tween()
	tween.set_loops()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position", posicao_inicial + Vector2(0, -1), 1.0)
	tween.tween_property(self, "position", posicao_inicial, 1.0)
