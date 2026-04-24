extends Node2D

const SHOW_GUIDES: bool = false
const SHOW_PARTICLES: bool = true

const IMPACT_ALPHA: float = 0.42
const IMPACT_INTENSITY: float = 1.55

const DEFAULT_SCALE_MIN: float = 0.37
const DEFAULT_SCALE_MAX: float = 0.57
const DEFAULT_TEXTURE_W: int = 2
const DEFAULT_TEXTURE_H: int = 3

var impactos_config: Array[Dictionary] = [
	{ "nome": "ImpactoPredio1", "x_ratio": 0.11, "y_ratio": 0.78, "width": 80.0, "scale_min": 0.20, "scale_max": 0.40, "texture_w": 2, "texture_h": 3 },
	{ "nome": "ImpactoPredio2", "x_ratio": 0.255, "y_ratio": 0.88, "width": 35.0, "scale_min": 0.29, "scale_max": 0.39, "texture_w": 1, "texture_h": 2 },
	{ "nome": "ImpactoPredio3", "x_ratio": 0.38, "y_ratio": 0.88, "width": 65.0, "scale_min": 0.39, "scale_max": 0.39, "texture_w": 1.5, "texture_h": 2 },
	{ "nome": "ImpactoPredio4", "x_ratio": 0.655, "y_ratio": 0.837, "width": 17.0, "scale_min": 0.29, "scale_max": 0.39, "texture_w": 1, "texture_h": 1.5 },
	{ "nome": "ImpactoPredio5", "x_ratio": 0.689, "y_ratio": 0.814, "width": 20.0, "scale_min": 0.37, "scale_max": 0.57, "texture_w": 1, "texture_h": 1 },
	{ "nome": "ImpactoPredio6", "x_ratio": 0.728, "y_ratio": 0.837, "width": 27.0, "scale_min": 0.29, "scale_max": 0.39, "texture_w": 1, "texture_h": 1 },
	{ "nome": "ImpactoPredio7", "x_ratio": 0.765, "y_ratio": 0.82, "width": 15.0, "scale_min": 0.29, "scale_max": 0.39, "texture_w": 1, "texture_h": 1 },
	{ "nome": "ImpactoPredio8", "x_ratio": 0.813, "y_ratio": 0.78, "width": 32.0, "scale_min": 0.29, "scale_max": 0.39, "texture_w": 1, "texture_h": 1 },
	{ "nome": "ImpactoPredio9", "x_ratio": 0.876, "y_ratio": 0.885, "width": 26.0, "scale_min": 0.29, "scale_max": 0.39, "texture_w": 1, "texture_h": 1 },
	{ "nome": "ImpactoPredio10", "x_ratio": 0.954, "y_ratio": 0.923, "width": 23.0, "scale_min": 0.29, "scale_max": 0.39, "texture_w": 1, "texture_h": 1 },
	{ "nome": "ImpactoPredio11", "x_ratio": 0.997, "y_ratio": 0.49, "width": 42.0, "scale_min": 0.37, "scale_max": 0.57, "texture_w": 2, "texture_h": 3 },
	{ "nome": "ImpactoPredio12", "x_ratio": 0.997, "y_ratio": 0.14, "width": 48.0, "scale_min": 0.37, "scale_max": 0.57, "texture_w": 2, "texture_h": 3 }
]

func _ready() -> void:
	position = Vector2.ZERO
	rotation = 0.0
	scale = Vector2.ONE
	top_level = true
	z_index = 9999

	_limpar_filhos()
	_criar_impactos()

func _limpar_filhos() -> void:
	for child: Node in get_children():
		child.queue_free()

func _criar_impactos() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	for config: Dictionary in impactos_config:
		var nome: String = String(config["nome"])
		var x_ratio: float = float(config["x_ratio"])
		var y_ratio: float = float(config["y_ratio"])
		var largura: float = float(config["width"])

		var scale_min: float = DEFAULT_SCALE_MIN
		var scale_max: float = DEFAULT_SCALE_MAX
		var texture_w: int = DEFAULT_TEXTURE_W
		var texture_h: int = DEFAULT_TEXTURE_H

		if config.has("scale_min"):
			scale_min = float(config["scale_min"])
		if config.has("scale_max"):
			scale_max = float(config["scale_max"])
		if config.has("texture_w"):
			texture_w = int(config["texture_w"])
		if config.has("texture_h"):
			texture_h = int(config["texture_h"])

		var pos: Vector2 = Vector2(viewport_size.x * x_ratio, viewport_size.y * y_ratio)

		if SHOW_GUIDES:
			_criar_guia(nome, pos, largura)

		if SHOW_PARTICLES:
			_criar_faixa_impacto(nome, pos, largura, scale_min, scale_max, texture_w, texture_h)

func _criar_guia(nome: String, pos: Vector2, largura: float) -> void:
	_criar_barra_horizontal(nome + "_Barra", pos, largura, Color(1.0, 0.35, 0.0, 0.95))
	_criar_marcador_centro(nome + "_Centro", pos, Color(0.0, 1.0, 0.0, 0.95))

func _criar_barra_horizontal(nome: String, pos: Vector2, largura: float, cor: Color) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.name = nome
	poly.color = cor
	poly.z_index = 9999
	poly.position = pos
	poly.polygon = PackedVector2Array([
		Vector2(-largura * 0.5, -2.0),
		Vector2(largura * 0.5, -2.0),
		Vector2(largura * 0.5, 2.0),
		Vector2(-largura * 0.5, 2.0)
	])
	add_child(poly)

func _criar_marcador_centro(nome: String, pos: Vector2, cor: Color) -> void:
	var poly: Polygon2D = Polygon2D.new()
	poly.name = nome
	poly.color = cor
	poly.z_index = 9999
	poly.position = pos
	poly.polygon = PackedVector2Array([
		Vector2(-2.0, -10.0),
		Vector2(2.0, -10.0),
		Vector2(2.0, 10.0),
		Vector2(-2.0, 10.0)
	])
	add_child(poly)

func _criar_faixa_impacto(nome: String, pos: Vector2, largura: float, scale_min: float, scale_max: float, texture_w: int, texture_h: int) -> void:
	var particles: GPUParticles2D = GPUParticles2D.new()
	particles.name = nome
	particles.position = pos
	particles.top_level = true
	particles.z_index = 9999

	var amount: int = maxi(14, int((largura / 15.0) * IMPACT_INTENSITY))

	particles.amount = amount
	particles.lifetime = 0.34
	particles.preprocess = 0.34
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.randomness = 0.30
	particles.local_coords = false
	particles.emitting = true
	particles.texture = _criar_textura_splash(texture_w, texture_h, Color(0.92, 0.96, 1.0, IMPACT_ALPHA))

	particles.visibility_rect = Rect2(-largura * 0.5 - 20.0, -45.0, largura + 40.0, 90.0)

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(largura * 0.5, 1.0, 0.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 20.0
	material.initial_velocity_min = 18.0
	material.initial_velocity_max = 34.0
	material.gravity = Vector3(0.0, 110.0, 0.0)
	material.scale_min = scale_min
	material.scale_max = scale_max
	material.color = Color(1.0, 1.0, 1.0, 1.0)

	particles.process_material = material
	add_child(particles)

func _criar_textura_splash(largura: int, altura: int, cor: Color) -> Texture2D:
	var img: Image = Image.create_empty(largura, altura, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y: int in range(altura):
		for x: int in range(largura):
			var alpha: float = cor.a
			if y == 0:
				alpha *= 0.95
			elif y == altura - 1:
				alpha *= 0.65
			img.set_pixel(x, y, Color(cor.r, cor.g, cor.b, alpha))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	return tex
