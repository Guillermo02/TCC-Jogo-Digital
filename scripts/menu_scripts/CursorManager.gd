extends Node

const CURSOR_NORMAL_TEXTURE := preload("res://UI/HUD_Mono/SetaMouse.png")
const CURSOR_HOVER_TEXTURE := preload("res://UI/HUD_Mono/MouseHover.png")
const CURSOR_CLICK_TEXTURE := preload("res://UI/HUD_Mono/MouseClick.png")

@export var escala_cursor: int = 2

var cursor_normal: ImageTexture
var cursor_hover: ImageTexture
var cursor_click: ImageTexture

var esta_em_hover_manual := false
var esta_em_hover_control := false
var esta_clicando := false

var estado_cursor_atual := ""

# Ajuste se a ponta do mouse ficar desalinhada.
var hotspot := Vector2.ZERO


func _ready() -> void:
	# Garante que o CursorManager funcione também em pause menus.
	process_mode = Node.PROCESS_MODE_ALWAYS

	cursor_normal = criar_cursor_aumentado(CURSOR_NORMAL_TEXTURE)
	cursor_hover = criar_cursor_aumentado(CURSOR_HOVER_TEXTURE)
	cursor_click = criar_cursor_aumentado(CURSOR_CLICK_TEXTURE)

	atualizar_cursor(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		esta_clicando = false
		esta_em_hover_control = false
		atualizar_cursor(true)

	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		esta_clicando = false
		atualizar_cursor(true)


func _process(_delta: float) -> void:
	esta_em_hover_control = mouse_sobre_control_clicavel()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		esta_clicando = false

	atualizar_cursor()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			esta_clicando = event.pressed
			atualizar_cursor(true)


func usar_cursor_normal() -> void:
	esta_em_hover_manual = false
	atualizar_cursor(true)


func usar_cursor_hover() -> void:
	esta_em_hover_manual = true
	atualizar_cursor(true)


func usar_cursor_click() -> void:
	esta_clicando = true
	atualizar_cursor(true)


func atualizar_cursor(forcar: bool = false) -> void:
	var novo_estado := "normal"

	if esta_clicando:
		novo_estado = "click"
	elif esta_em_hover_manual or esta_em_hover_control:
		novo_estado = "hover"

	if not forcar and novo_estado == estado_cursor_atual:
		return

	estado_cursor_atual = novo_estado

	if novo_estado == "click":
		aplicar_cursor_em_todos_os_tipos(cursor_click)
	elif novo_estado == "hover":
		aplicar_cursor_em_todos_os_tipos(cursor_hover)
	else:
		aplicar_cursor_em_todos_os_tipos(cursor_normal)


func mouse_sobre_control_clicavel() -> bool:
	var control := get_viewport().gui_get_hovered_control()

	while control != null:
		if not is_instance_valid(control):
			return false

		if not control.visible:
			control = control.get_parent_control()
			continue

		if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			control = control.get_parent_control()
			continue

		if control is BaseButton:
			return not control.disabled

		if control.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND:
			return true

		control = control.get_parent_control()

	return false


func aplicar_cursor_em_todos_os_tipos(textura: Texture2D) -> void:
	if textura == null:
		return

	Input.set_custom_mouse_cursor(textura, Input.CURSOR_ARROW, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_POINTING_HAND, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_IBEAM, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_CROSS, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_WAIT, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_BUSY, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_DRAG, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_CAN_DROP, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_FORBIDDEN, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_VSIZE, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_HSIZE, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_BDIAGSIZE, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_FDIAGSIZE, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_MOVE, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_VSPLIT, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_HSPLIT, hotspot)
	Input.set_custom_mouse_cursor(textura, Input.CURSOR_HELP, hotspot)


func criar_cursor_aumentado(textura: Texture2D) -> ImageTexture:
	var imagem := textura.get_image()
	var novo_tamanho := imagem.get_size() * escala_cursor

	imagem.resize(novo_tamanho.x, novo_tamanho.y, Image.INTERPOLATE_NEAREST)

	return ImageTexture.create_from_image(imagem)
