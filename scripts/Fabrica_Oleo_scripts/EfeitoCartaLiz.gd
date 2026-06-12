extends Sprite2D

var posicao_inicial: Vector2
var sumindo := false
var tween_movimento: Tween
var tween_brilho: Tween


func _ready() -> void:
	posicao_inicial = position
	criar_shader_brilho()
	animar()
	animar_brilho()


func animar() -> void:
	tween_movimento = create_tween()
	tween_movimento.set_loops()

	tween_movimento.set_trans(Tween.TRANS_SINE)
	tween_movimento.set_ease(Tween.EASE_IN_OUT)

	tween_movimento.tween_property(self, "position", posicao_inicial + Vector2(0, -2), 1.0)
	tween_movimento.tween_property(self, "position", posicao_inicial, 1.0)


func criar_shader_brilho() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float brilho_posicao = -1.0;
uniform float largura_brilho = 0.20;
uniform float intensidade_brilho = 0.45;

void fragment() {
	vec4 cor_textura = texture(TEXTURE, UV);

	float diagonal = UV.x + UV.y;
	float faixa = smoothstep(largura_brilho, 0.0, abs(diagonal - brilho_posicao));

	cor_textura.rgb += faixa * intensidade_brilho * cor_textura.a;

	COLOR = cor_textura * COLOR;
}
"""

	var mat := ShaderMaterial.new()
	mat.shader = shader
	material = mat


func animar_brilho() -> void:
	tween_brilho = create_tween()
	tween_brilho.set_loops()

	tween_brilho.tween_method(
		func(valor):
			if material:
				material.set_shader_parameter("brilho_posicao", valor),
		-0.5,
		2.5,
		1.3
	)

	tween_brilho.tween_interval(2.2)


func aparecer() -> void:
	if sumindo:
		return

	modulate.a = 1.0
	show()


func sumir_suave() -> void:
	if sumindo:
		return

	if not visible:
		return

	sumindo = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)

	await tween.finished

	hide()
	modulate.a = 1.0
	sumindo = false
