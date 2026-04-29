extends Control

var primeiro_ponto = null
var segundo_ponto = null
var puzzle_completo = false
var numero_do_puzzle = 1

var dialogos = {
	1: [
		"Prefeito: Atualização da situação",
		"Capanga 1: Já subornamos mais da metade dos votos.",
		"Prefeito: Ótimo, se certifique de cobrir bem os rastros.",
		"Capanga 1: Entendido!"
	],
	
	2: [
		"Capanga 2: Deixamos aquela garota naquele lugar que você pediu seu prefeito.",
		"Prefeito: Perfeito. Se certifiquem que ela não possa escapar,
		e encontrem aquele maldito celular!",
		"Capanga 2: Vamos encontrar, senhor!"
	]
}

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if GameState.puzzles_completos.get(numero_do_puzzle, false):
		abrir_dialogo()

func _input(event):
	if event.is_action_pressed("sair"):
		sair_do_puzzle()

func selecionar_ponto(ponto):
	if ponto.conectado:
		return
	
	if primeiro_ponto == ponto:
		return
	
	if primeiro_ponto == null:
		primeiro_ponto = ponto
		ponto.definir_pressionado()
		print("Primeiro selecionado:", ponto.nome_fio)
		return
	
	if segundo_ponto == null:
		segundo_ponto = ponto
		ponto.definir_pressionado()
		print("Segundo selecionado:", ponto.nome_fio)
		validar_conexao()

func validar_conexao():
	if primeiro_ponto == null or segundo_ponto == null:
		return
	
	if primeiro_ponto == segundo_ponto:
		resetar_selecao()
		return
	
	if combinacao_correta(primeiro_ponto, segundo_ponto):
		conectar_pontos(primeiro_ponto, segundo_ponto)
	else:
		print("Combinação errada!")
		await get_tree().create_timer(0.25).timeout
		resetar_selecao()

func combinacao_correta(ponto1, ponto2) -> bool:
	return ponto1.par_nome == ponto2.nome_fio and ponto2.par_nome == ponto1.nome_fio

func conectar_pontos(ponto1, ponto2):
	print("Conectado corretamente!")
	
	ponto1.conectado = true
	ponto2.conectado = true
	
	ponto1.definir_conectado()
	ponto2.definir_conectado()
	
	primeiro_ponto = null
	segundo_ponto = null
	
	verificar_vitoria()

func resetar_selecao():
	if primeiro_ponto != null and not primeiro_ponto.conectado:
		primeiro_ponto.definir_normal()
	
	if segundo_ponto != null and not segundo_ponto.conectado:
		segundo_ponto.definir_normal()
	
	primeiro_ponto = null
	segundo_ponto = null

func verificar_vitoria():
	for no in $fios.get_children():
		if no is Area2D and not no.conectado:
			return
	
	print("PUZZLE COMPLETO!")
	GameState.puzzles_completos[numero_do_puzzle] = true
	puzzle_completo = true
	abrir_dialogo()

func abrir_dialogo():
	var dialogo_ui = $dialogoUI
	dialogo_ui.iniciar_dialogo(dialogos[numero_do_puzzle])

func sair_do_puzzle():
	get_tree().paused = false  # se você pausou o jogo
	queue_free()
