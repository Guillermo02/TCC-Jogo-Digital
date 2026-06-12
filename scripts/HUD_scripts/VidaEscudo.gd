extends Node2D

const LAYER_WORLD := 1
const LAYER_PLAYER := 2

@export var tempo_troca_icone: float = 1.0
@export var duracao_troca_suave: float = 0.35

@export var duracao_coleta: float = 0.9
@export var escala_coletado: float = 1.18

# Posição aproximada do HUD na tela.
# Ajuste se o ícone estiver indo para um ponto muito longe/perto.
@export var hud_target_screen_position: Vector2 = Vector2(78, 42)

@onready var button_round_border: Node2D = $ButtonRoundBorder
@onready var coracao_cheio: Node2D = $CoracaoCheio
@onready var coracao_cheio_2: Node2D = $CoracaoCheio2
@onready var shield: Node2D = $Shield
@onready var shield_2: Node2D = $Shield2
@onready var area_coleta: Area2D = $AreaColeta
@onready var area_collision: CollisionShape2D = $AreaColeta/CollisionShape2D

var coletado := false
var mostrando_coracao := true
var trocando_visual := false
var alternancia_ativa := false

var escala_inicial: Vector2
var posicao_inicial: Vector2

var tween_movimento: Tween = null
var tween_brilho: Tween = null
var tween_troca_visual: Tween = null
var tween_coleta: Tween = null


func _ready() -> void:
	escala_inicial = scale
	posicao_inicial = position

	modulate.a = 1.0

	configurar_area_coleta()

	criar_shader_brilho()
	animar_movimento_flutuante()
	animar_brilho()

	preparar_visuais_iniciais()
	call_deferred("iniciar_alternancia_visual")


func configurar_area_coleta() -> void:
	if area_coleta == null:
		return

	area_coleta.collision_layer = 0
	area_coleta.collision_mask = LAYER_WORLD | LAYER_PLAYER

	area_coleta.monitoring = true
	area_coleta.monitorable = true

	if area_collision != null:
		area_collision.set_deferred("disabled", false)

	if not area_coleta.body_entered.is_connected(_on_area_coleta_body_entered):
		area_coleta.body_entered.connect(_on_area_coleta_body_entered)


func preparar_visuais_iniciais() -> void:
	mostrando_coracao = true

	coracao_cheio.show()
	coracao_cheio_2.show()
	coracao_cheio.modulate.a = 1.0
	coracao_cheio_2.modulate.a = 1.0

	shield.show()
	shield_2.show()
	shield.modulate.a = 0.0
	shield_2.modulate.a = 0.0


func iniciar_alternancia_visual() -> void:
	if alternancia_ativa:
		return

	alternancia_ativa = true

	while is_inside_tree() and not coletado:
		await get_tree().create_timer(tempo_troca_icone).timeout

		if not is_inside_tree():
			break

		if coletado:
			break

		if trocando_visual:
			continue

		if mostrando_coracao:
			await trocar_para_escudo_suave()
		else:
			await trocar_para_coracao_suave()

	alternancia_ativa = false


func trocar_para_coracao_suave() -> void:
	if coletado or not is_inside_tree():
		return

	trocando_visual = true
	mostrando_coracao = true

	_matar_tween(tween_troca_visual)

	coracao_cheio.show()
	coracao_cheio_2.show()
	shield.show()
	shield_2.show()

	tween_troca_visual = create_tween()
	tween_troca_visual.set_parallel(true)
	tween_troca_visual.set_trans(Tween.TRANS_SINE)
	tween_troca_visual.set_ease(Tween.EASE_IN_OUT)

	tween_troca_visual.tween_property(coracao_cheio, "modulate:a", 1.0, duracao_troca_suave)
	tween_troca_visual.tween_property(coracao_cheio_2, "modulate:a", 1.0, duracao_troca_suave)

	tween_troca_visual.tween_property(shield, "modulate:a", 0.0, duracao_troca_suave)
	tween_troca_visual.tween_property(shield_2, "modulate:a", 0.0, duracao_troca_suave)

	await tween_troca_visual.finished

	tween_troca_visual = null

	if coletado or not is_inside_tree():
		trocando_visual = false
		return

	coracao_cheio.show()
	coracao_cheio_2.show()
	shield.hide()
	shield_2.hide()

	trocando_visual = false


func trocar_para_escudo_suave() -> void:
	if coletado or not is_inside_tree():
		return

	trocando_visual = true
	mostrando_coracao = false

	_matar_tween(tween_troca_visual)

	coracao_cheio.show()
	coracao_cheio_2.show()
	shield.show()
	shield_2.show()

	tween_troca_visual = create_tween()
	tween_troca_visual.set_parallel(true)
	tween_troca_visual.set_trans(Tween.TRANS_SINE)
	tween_troca_visual.set_ease(Tween.EASE_IN_OUT)

	tween_troca_visual.tween_property(coracao_cheio, "modulate:a", 0.0, duracao_troca_suave)
	tween_troca_visual.tween_property(coracao_cheio_2, "modulate:a", 0.0, duracao_troca_suave)

	tween_troca_visual.tween_property(shield, "modulate:a", 1.0, duracao_troca_suave)
	tween_troca_visual.tween_property(shield_2, "modulate:a", 1.0, duracao_troca_suave)

	await tween_troca_visual.finished

	tween_troca_visual = null

	if coletado or not is_inside_tree():
		trocando_visual = false
		return

	coracao_cheio.hide()
	coracao_cheio_2.hide()
	shield.show()
	shield_2.show()

	trocando_visual = false


func criar_shader_brilho() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float brilho_posicao = -1.0;
uniform float largura_brilho = 0.20;
uniform float intensidade_brilho = 0.50;

void fragment() {
	vec4 cor_textura = texture(TEXTURE, UV);

	float diagonal = UV.x + UV.y;
	float faixa = smoothstep(largura_brilho, 0.0, abs(diagonal - brilho_posicao));

	cor_textura.rgb += faixa * intensidade_brilho * cor_textura.a;

	COLOR = cor_textura * COLOR;
}
"""

	aplicar_shader_em_no(button_round_border, shader)
	aplicar_shader_em_no(coracao_cheio, shader)
	aplicar_shader_em_no(coracao_cheio_2, shader)
	aplicar_shader_em_no(shield, shader)
	aplicar_shader_em_no(shield_2, shader)


func aplicar_shader_em_no(no: Node, shader: Shader) -> void:
	if not is_instance_valid(no):
		return

	if no is CanvasItem:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		no.material = mat


func animar_movimento_flutuante() -> void:
	_matar_tween(tween_movimento)

	tween_movimento = create_tween()
	tween_movimento.set_loops()
	tween_movimento.set_trans(Tween.TRANS_SINE)
	tween_movimento.set_ease(Tween.EASE_IN_OUT)

	tween_movimento.tween_property(self, "position", posicao_inicial + Vector2(0, -1), 1.0)
	tween_movimento.tween_property(self, "position", posicao_inicial, 1.0)


func animar_brilho() -> void:
	_matar_tween(tween_brilho)

	tween_brilho = create_tween()
	tween_brilho.set_loops()

	tween_brilho.tween_method(
		func(valor: float) -> void:
			atualizar_brilho(valor),
		-0.5,
		2.5,
		1.3
	)

	tween_brilho.tween_interval(2.3)


func atualizar_brilho(valor: float) -> void:
	atualizar_brilho_do_no(button_round_border, valor)
	atualizar_brilho_do_no(coracao_cheio, valor)
	atualizar_brilho_do_no(coracao_cheio_2, valor)
	atualizar_brilho_do_no(shield, valor)
	atualizar_brilho_do_no(shield_2, valor)


func atualizar_brilho_do_no(no: Node, valor: float) -> void:
	if not is_instance_valid(no):
		return

	if no is CanvasItem and no.material:
		no.material.set_shader_parameter("brilho_posicao", valor)


func _on_area_coleta_body_entered(body: Node2D) -> void:
	if coletado:
		return

	if not body.is_in_group("player"):
		return

	coletar()


func coletar() -> void:
	if coletado:
		return

	coletado = true
	trocando_visual = false
	alternancia_ativa = false

	if is_instance_valid(area_coleta):
		area_coleta.set_deferred("monitoring", false)
		area_coleta.set_deferred("monitorable", false)

	if is_instance_valid(area_collision):
		area_collision.set_deferred("disabled", true)

	_matar_tweens_ativos()

	regenerar_jogador()

	await animar_coletado()

	queue_free()


func regenerar_jogador() -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("restaurar_um_coracao_ou_um_escudo"):
		hud.restaurar_um_coracao_ou_um_escudo()
		return

	if hud.has_method("heal_heart_unit"):
		hud.heal_heart_unit(1)


func animar_coletado() -> void:
	var posicao_hud_no_mundo := obter_posicao_hud_no_mundo()

	_matar_tween(tween_coleta)

	tween_coleta = create_tween()
	tween_coleta.set_parallel(true)
	tween_coleta.set_trans(Tween.TRANS_SINE)
	tween_coleta.set_ease(Tween.EASE_IN_OUT)

	tween_coleta.tween_property(self, "global_position", posicao_hud_no_mundo, duracao_coleta)

	tween_coleta.tween_property(self, "scale", escala_inicial * escala_coletado, duracao_coleta * 0.22)
	tween_coleta.tween_property(self, "scale", escala_inicial * 0.85, duracao_coleta * 0.35).set_delay(duracao_coleta * 0.22)

	tween_coleta.tween_property(self, "modulate:a", 0.0, duracao_coleta * 0.45).set_delay(duracao_coleta * 0.35)

	await tween_coleta.finished

	tween_coleta = null


func obter_posicao_hud_no_mundo() -> Vector2:
	var canvas_transform := get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * hud_target_screen_position


func _matar_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _matar_tweens_ativos() -> void:
	_matar_tween(tween_movimento)
	_matar_tween(tween_brilho)
	_matar_tween(tween_troca_visual)

	tween_movimento = null
	tween_brilho = null
	tween_troca_visual = null


func _exit_tree() -> void:
	coletado = true
	alternancia_ativa = false
	trocando_visual = false

	_matar_tweens_ativos()
	_matar_tween(tween_coleta)
	tween_coleta = null
