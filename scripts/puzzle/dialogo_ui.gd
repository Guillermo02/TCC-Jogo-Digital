extends Control

@onready var panel = $Panel
@onready var label = $Panel/Label

var dialogo = []
var index = 0

func iniciar_dialogo(novo_dialogo):
	dialogo = novo_dialogo
	panel.visible = true
	
	var texto_completo = ""
	
	for linha in dialogo:
		texto_completo += linha + "\n\n"
	
	label.text = texto_completo

func mostrar_proxima():
	while index < dialogo.size():
		label.text = dialogo[index]
		index += 1
	await get_tree().create_timer(1.5).timeout
	
	fechar_dialogo()

func _input(event):
	if panel.visible and event.is_action_pressed("ui_accept"):
		mostrar_proxima()

func fechar_dialogo():
	panel.visible = false
