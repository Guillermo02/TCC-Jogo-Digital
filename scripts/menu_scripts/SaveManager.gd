extends Node

const SAVE_PATH := "user://save_game.json"

const CENA_INICIO := "res://scenes/menus/Inicio_jogo.tscn"
const CENA_NOVO_JOGO := "res://scenes/fases/floresta.tscn"

var cenas_salvaveis := [
	"res://scenes/fases/floresta.tscn",
	"res://scenes/fases/CasaElliot.tscn",
	"res://scenes/fases/cidade.tscn",
	"res://scenes/fases/Fabrica_Oleo.tscn",
	"res://scenes/fases/ZonaNorte.tscn",
	"res://scenes/fases/CasaElliot2.tscn"
]


func pode_salvar_cena(scene_path: String) -> bool:
	return cenas_salvaveis.has(scene_path)


func save_game(scene_path: String) -> bool:
	if not pode_salvar_cena(scene_path):
		push_warning("Cena não pode ser salva: " + scene_path)
		return false

	var dados := {
		"scene_path": scene_path,
		"version": 1
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Não foi possível criar arquivo de save em: " + SAVE_PATH)
		return false

	file.store_string(JSON.stringify(dados, "\t"))
	file.close()

	print("Jogo salvo em: ", scene_path)

	return true


func has_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var scene_path := get_saved_scene_path()

	if scene_path == "":
		return false

	if not ResourceLoader.exists(scene_path):
		return false

	return true


func get_saved_scene_path() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		return ""

	var texto := file.get_as_text()
	file.close()

	var json := JSON.new()
	var erro := json.parse(texto)

	if erro != OK:
		push_warning("Save inválido ou corrompido.")
		return ""

	var dados = json.data

	if typeof(dados) != TYPE_DICTIONARY:
		return ""

	if not dados.has("scene_path"):
		return ""

	var scene_path: String = str(dados["scene_path"])

	if not pode_salvar_cena(scene_path):
		return ""

	return scene_path


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save apagado.")


func reset_save_for_new_game() -> void:
	delete_save()


func salvar_novo_checkpoint(scene_path: String) -> bool:
	return save_game(scene_path)
