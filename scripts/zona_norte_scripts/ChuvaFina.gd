extends Node2D

@export var largura_tela_extra: float = 300.0
@export var altura_tela_extra: float = 200.0

# Controle geral da chuva fina
@export var intensidade: float = 1.0
@export var vento_horizontal: float = -0.06

var textura_chuva_distante: Texture2D
var textura_chuva_media: Texture2D
var textura_chuva_proxima: Texture2D

var reconstruindo_chuva := false


func _ready() -> void:
	z_index = 5

	textura_chuva_distante = criar_textura_gota(1, 8, Color(0.78, 0.86, 1.0, 0.12))
	textura_chuva_media = criar_textura_gota(1, 9, Color(0.82, 0.90, 1.0, 0.17))
	textura_chuva_proxima = criar_textura_gota(1, 10, Color(0.88, 0.94, 1.0, 0.22))

	_criar_chuva_fina()

	var viewport := get_viewport()
	if viewport != null:
		if not viewport.size_changed.is_connected(_reconstruir_chuva):
			viewport.size_changed.connect(_reconstruir_chuva)


func _reconstruir_chuva() -> void:
	if reconstruindo_chuva:
		return

	reconstruindo_chuva = true

	await get_tree().process_frame

	for child in get_children():
		child.queue_free()

	await get_tree().process_frame

	if is_inside_tree():
		_criar_chuva_fina()

	reconstruindo_chuva = false


func _criar_chuva_fina() -> void:
	var tamanho_tela := get_viewport_rect().size
	var intensidade_segura := maxf(intensidade, 0.0)

	_criar_camada_chuva(
		"ChuvaFinaDistante",
		tamanho_tela,
		textura_chuva_distante,
		int(28 * intensidade_segura),
		3.4,
		Vector2(vento_horizontal, 1.0),
		85.0,
		135.0,
		0.55,
		0.80,
		10.0,
		1,
		65.0
	)

	_criar_camada_chuva(
		"ChuvaFinaMedia",
		tamanho_tela,
		textura_chuva_media,
		int(16 * intensidade_segura),
		2.8,
		Vector2(vento_horizontal - 0.03, 1.0),
		120.0,
		190.0,
		0.70,
		1.00,
		8.0,
		2,
		85.0
	)

	_criar_camada_chuva(
		"ChuvaFinaProxima",
		tamanho_tela,
		textura_chuva_proxima,
		int(6 * intensidade_segura),
		2.2,
		Vector2(vento_horizontal - 0.05, 1.0),
		175.0,
		255.0,
		0.95,
		1.30,
		6.0,
		3,
		105.0
	)


func _criar_camada_chuva(
	nome: String,
	tamanho_tela: Vector2,
	textura: Texture2D,
	amount: int,
	lifetime: float,
	direcao_2d: Vector2,
	velocidade_min: float,
	velocidade_max: float,
	escala_min: float,
	escala_max: float,
	spread: float,
	z_local: int,
	altura_emissao: float
) -> void:
	var particles := GPUParticles2D.new()
	particles.name = nome

	particles.amount = max(amount, 1)
	particles.lifetime = maxf(lifetime, 0.1)
	particles.preprocess = particles.lifetime
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.randomness = 0.75
	particles.local_coords = false
	particles.texture = textura
	particles.emitting = true
	particles.z_index = z_local

	particles.visibility_rect = Rect2(
		-largura_tela_extra,
		-altura_tela_extra,
		tamanho_tela.x + largura_tela_extra * 2.0,
		tamanho_tela.y + altura_tela_extra * 2.0
	)

	particles.position = Vector2(tamanho_tela.x * 0.5, -60.0)

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(
		(tamanho_tela.x + largura_tela_extra * 2.0) * 0.5,
		altura_emissao,
		0.0
	)

	material.direction = Vector3(direcao_2d.x, direcao_2d.y, 0.0)
	material.spread = spread
	material.initial_velocity_min = velocidade_min
	material.initial_velocity_max = velocidade_max
	material.gravity = Vector3(0.0, 260.0, 0.0)
	material.scale_min = escala_min
	material.scale_max = escala_max
	material.particle_flag_align_y = true
	material.color = Color(1.0, 1.0, 1.0, 1.0)

	particles.process_material = material

	add_child(particles)


func criar_textura_gota(largura: int, altura: int, cor: Color) -> Texture2D:
	var img := Image.create_empty(largura, altura, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(altura):
		var alpha := cor.a

		if y == 0 or y == altura - 1:
			alpha *= 0.20
		elif y == 1 or y == altura - 2:
			alpha *= 0.50

		for x in range(largura):
			img.set_pixel(x, y, Color(cor.r, cor.g, cor.b, alpha))

	return ImageTexture.create_from_image(img)


func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport != null:
		if viewport.size_changed.is_connected(_reconstruir_chuva):
			viewport.size_changed.disconnect(_reconstruir_chuva)
