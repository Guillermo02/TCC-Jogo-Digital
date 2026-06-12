extends Node

const SETTINGS_PATH := "user://settings.json"

var colorblind_mode: int = 0
var puzzles_completos = {}


func _ready() -> void:
	carregar_configuracoes()


func set_colorblind_mode(novo_modo: int) -> void:
	colorblind_mode = clamp(novo_modo, 0, 3)
	salvar_configuracoes()


func salvar_configuracoes() -> void:
	var dados := {
		"colorblind_mode": colorblind_mode
	}

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Não foi possível salvar configurações em: " + SETTINGS_PATH)
		return

	file.store_string(JSON.stringify(dados, "\t"))
	file.close()

	print("Configurações salvas. Modo daltonismo:", colorblind_mode)


func carregar_configuracoes() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		colorblind_mode = 0
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)

	if file == null:
		colorblind_mode = 0
		return

	var texto := file.get_as_text()
	file.close()

	var json := JSON.new()
	var erro := json.parse(texto)

	if erro != OK:
		push_warning("Arquivo de configurações inválido. Usando padrão.")
		colorblind_mode = 0
		return

	var dados = json.data

	if typeof(dados) != TYPE_DICTIONARY:
		colorblind_mode = 0
		return

	if dados.has("colorblind_mode"):
		colorblind_mode = clamp(int(dados["colorblind_mode"]), 0, 3)
	else:
		colorblind_mode = 0
