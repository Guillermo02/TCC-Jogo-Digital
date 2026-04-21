extends Node2D

var primeiro_ponto = null
var segundo_ponto = null

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
	for no in get_children():
		if no is Area2D:
			if not no.conectado:
				return
	
	print("PUZZLE COMPLETO!")
