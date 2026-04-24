extends Node2D

var atraso_inicial: float = 2.0
var intervalo_entre_claroes: float = 11.5
var comecar_com_duplo: bool = true

var flash_1_multiplicador: float = 1.35
var flash_2_multiplicador: float = 0.72

var tempo_subida_1: float = 0.03
var tempo_descida_1: float = 0.075
var pausa_entre_flashes: float = 0.13
var tempo_subida_2: float = 0.12
var tempo_descida_2: float = 1.2

var flashes: Array[Polygon2D] = []
var alpha_pico_por_nome: Dictionary = {}
var proximo_eh_duplo: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_aplicar_preset_por_nome()
	_coletar_flashes()
	_guardar_alpha_pico_do_editor()
	_esconder_todos()
	_configurar_primeiro_padrao()
	_loop_claroes()

func _aplicar_preset_por_nome() -> void:
	if name == "ClarãoRaio":
		atraso_inicial = 2.0
		intervalo_entre_claroes = 11.5
		comecar_com_duplo = true

		flash_1_multiplicador = 1.35
		flash_2_multiplicador = 0.72

		tempo_subida_1 = 0.03
		tempo_descida_1 = 0.075
		pausa_entre_flashes = 0.13
		tempo_subida_2 = 0.12
		tempo_descida_2 = 1.2

	elif name == "ClarãoRaio2":
		atraso_inicial = 6.0
		intervalo_entre_claroes = 11.5
		comecar_com_duplo = false

		flash_1_multiplicador = 1.35
		flash_2_multiplicador = 0.72

		tempo_subida_1 = 0.03
		tempo_descida_1 = 0.075
		pausa_entre_flashes = 0.13
		tempo_subida_2 = 0.12
		tempo_descida_2 = 1.2

func _coletar_flashes() -> void:
	flashes.clear()

	for child: Node in get_children():
		if child is Polygon2D:
			flashes.append(child as Polygon2D)

func _guardar_alpha_pico_do_editor() -> void:
	alpha_pico_por_nome.clear()

	for flash: Polygon2D in flashes:
		alpha_pico_por_nome[flash.name] = flash.modulate.a

func _esconder_todos() -> void:
	for flash: Polygon2D in flashes:
		flash.modulate.a = 0.0

func _configurar_primeiro_padrao() -> void:
	proximo_eh_duplo = not comecar_com_duplo

func _loop_claroes() -> void:
	await get_tree().create_timer(atraso_inicial).timeout

	if comecar_com_duplo:
		await _executar_clarao_duplo()
	else:
		await _executar_clarao_simples()

	while true:
		await get_tree().create_timer(intervalo_entre_claroes).timeout

		if proximo_eh_duplo:
			await _executar_clarao_duplo()
		else:
			await _executar_clarao_simples()

		proximo_eh_duplo = not proximo_eh_duplo

func _executar_clarao_duplo() -> void:
	await _flash(flash_1_multiplicador, tempo_subida_1, tempo_descida_1)
	await get_tree().create_timer(pausa_entre_flashes).timeout
	await _flash(flash_2_multiplicador, tempo_subida_2, tempo_descida_2)

func _executar_clarao_simples() -> void:
	await _flash(flash_2_multiplicador, tempo_subida_2, tempo_descida_2)

func _flash(multiplicador: float, tempo_subida: float, tempo_descida: float) -> void:
	var tween_in: Tween = create_tween()

	for flash: Polygon2D in flashes:
		var alpha_pico: float = float(alpha_pico_por_nome[flash.name]) * multiplicador
		alpha_pico = clamp(alpha_pico, 0.0, 1.0)
		tween_in.parallel().tween_property(flash, "modulate:a", alpha_pico, tempo_subida)

	await tween_in.finished

	var tween_out: Tween = create_tween()

	for flash: Polygon2D in flashes:
		tween_out.parallel().tween_property(flash, "modulate:a", 0.0, tempo_descida)

	await tween_out.finished
