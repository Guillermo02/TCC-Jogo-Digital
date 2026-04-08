extends Node2D

var fio_selecionado = null
var entrada_selecionada = null

func selecionar_fio(fio):
	fio_selecionado = fio
	fio.scale = Vector2(1.1, 1.1)
	print("Selecionado:", fio.id)

func selecionar_entrada(entrada):
	entrada_selecionada = entrada
	entrada.scale = Vector2(1.1, 1.1)
	print("Selecionado:", entrada.id)

func tentar_conectar(entrada):
	if fio_selecionado == null:
		return
	if entrada.ocupado:
		return
	if fio_selecionado.id == entrada.id:
		conectar(fio_selecionado, entrada)
	else:
		print("errado!")
	fio_selecionado = null

func criar_linha(fio, entrada):
	var linha = Line2D.new()
	linha.width = 120
	linha.add_point(fio.global_position)
	linha.add_point(entrada.global_position)
	linha.texture = preload("res://assets/fios.png")
	linha.texture_mode = Line2D.LINE_TEXTURE_TILE
	linha.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	# estilo baseado no tipo
	#match fio.id:
		#"1":
			#linha.default_color = Color.RED
		#"2":
			#linha.default_color = Color.GREEN
		#"3":
			#linha.default_color = Color.BLUE
	add_child(linha)

func conectar(fio, entrada):
	print("conectado!")

	fio.conectado = true
	entrada.ocupado = true

	criar_linha(fio, entrada)
	verificar_vitoria()

func verificar_vitoria():
	for entrada in $entradas.get_children():
		if not entrada.ocupado:
			return
	print("PUZZLE COMPLETO!")
