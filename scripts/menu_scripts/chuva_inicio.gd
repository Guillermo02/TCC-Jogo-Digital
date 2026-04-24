extends Node2D

@export var largura_tela_extra: float = 300.0
@export var altura_tela_extra: float = 200.0

func _ready() -> void:
	z_index = 5
	_criar_chuva()

	if get_viewport() != null:
		get_viewport().size_changed.connect(_reconstruir_chuva)


func _reconstruir_chuva() -> void:
	for child in get_children():
		child.queue_free()

	call_deferred("_criar_chuva")


func _criar_chuva() -> void:
	var tamanho_tela := get_viewport_rect().size

	# FUNDO
	# Agora cai mais devagar e as gotas estão um pouco maiores que antes
	_criar_camada_chuva(
		"RainFar",
		tamanho_tela,
		criar_textura_gota(1, 8, Color(0.78, 0.86, 1.0, 0.18)),
		1500,
		2.2,
		Vector2(-0.08, 1.0),
		120.0,
		10.0,
		0.55,
		0.80,
		5.0,
		1
	)

	# MEIO
	_criar_camada_chuva(
		"RainMid",
		tamanho_tela,
		criar_textura_gota(1, 9, Color(0.82, 0.90, 1.0, 0.28)),
		190,
		1.7,
		Vector2(-0.12, 1.0),
		230.0,
		310.0,
		0.70,
		0.95,
		4.0,
		2
	)

	# FRENTE
	# Agora menor do que antes para não chamar tanto atenção
	_criar_camada_chuva(
		"RainNear",
		tamanho_tela,
		criar_textura_gota(1, 10, Color(0.88, 0.94, 1.0, 0.36)),
		110,
		1.3,
		Vector2(-0.15, 1.0),
		360.0,
		470.0,
		1.0,
		1.45,
		3.0,
		3
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
	z_local: int
) -> void:
	var particles := GPUParticles2D.new()
	particles.name = nome

	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.randomness = 0.30
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

	particles.position = Vector2(tamanho_tela.x * 0.5, -40.0)

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(
		(tamanho_tela.x + largura_tela_extra * 2.0) * 0.5,
		20.0,
		0.0
	)

	material.direction = Vector3(direcao_2d.x, direcao_2d.y, 0.0)
	material.spread = spread
	material.initial_velocity_min = velocidade_min
	material.initial_velocity_max = velocidade_max
	material.gravity = Vector3(0.0, 500.0, 0.0)

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
			alpha *= 0.25
		elif y == 1 or y == altura - 2:
			alpha *= 0.55

		for x in range(largura):
			img.set_pixel(x, y, Color(cor.r, cor.g, cor.b, alpha))

	return ImageTexture.create_from_image(img)
