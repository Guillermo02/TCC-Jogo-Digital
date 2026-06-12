extends Node2D

const LAYER_WORLD := 1
const LAYER_PLAYER := 2

@export var iniciar_ativo: bool = false

@export var pausa_luz_apagada: float = 3.0
@export var duracao_luz_ativa: float = 1.4

@export var duracao_fadein_luz: float = 0.08
@export var duracao_fadeout_luz: float = 0.65
@export var alpha_luz_acesa: float = 0.45

@export var matar_ao_encostar: bool = true

@onready var luz_area: Area2D = get_node_or_null("LuzArea") as Area2D
@onready var luz_visual: Polygon2D = get_node_or_null("LuzArea/LuzVisual") as Polygon2D
@onready var colisao_luz: CollisionPolygon2D = get_node_or_null("LuzArea/CollisionPolygon2D") as CollisionPolygon2D
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

var luz_ativa := false
var jogador_atingido := false
var loop_luz_rodando := false
var drone_ativo := false

var tween_luz: Tween = null
var loop_id: int = 0


func _ready() -> void:
	configurar_animacao_drone()
	configurar_luz()

	if iniciar_ativo:
		ativar_drone()
	else:
		desativar_drone()


func configurar_animacao_drone() -> void:
	if anim_sprite == null:
		return

	if anim_sprite.sprite_frames == null:
		return

	if anim_sprite.sprite_frames.has_animation("idle"):
		anim_sprite.play("idle")
	elif anim_sprite.sprite_frames.has_animation("default"):
		anim_sprite.play("default")
	else:
		anim_sprite.play()


func configurar_luz() -> void:
	if luz_area == null:
		push_warning("Drone: LuzArea não encontrada. Crie um Area2D chamado LuzArea.")
		return

	if luz_visual == null:
		push_warning("Drone: LuzVisual não encontrada. Coloque o Polygon2D dentro de LuzArea e renomeie para LuzVisual.")
		return

	if colisao_luz == null:
		push_warning("Drone: CollisionPolygon2D não encontrado dentro de LuzArea.")
		return

	luz_area.collision_layer = 0
	luz_area.collision_mask = LAYER_WORLD | LAYER_PLAYER
	luz_area.monitorable = false
	luz_area.monitoring = false

	if not luz_area.body_entered.is_connected(_on_luz_area_body_entered):
		luz_area.body_entered.connect(_on_luz_area_body_entered)

	luz_visual.visible = false
	luz_visual.modulate.a = 0.0

	colisao_luz.disabled = true
	luz_ativa = false
	jogador_atingido = false


func ativar_drone() -> void:
	if drone_ativo:
		return

	drone_ativo = true
	loop_id += 1
	visible = true

	if anim_sprite != null:
		anim_sprite.play()

	call_deferred("iniciar_loop_luz")


func desativar_drone() -> void:
	drone_ativo = false
	loop_luz_rodando = false
	luz_ativa = false
	jogador_atingido = false
	loop_id += 1

	_matar_tween_luz()

	if luz_visual != null:
		luz_visual.visible = false
		luz_visual.modulate.a = 0.0

	if colisao_luz != null:
		colisao_luz.set_deferred("disabled", true)

	if luz_area != null:
		luz_area.set_deferred("monitoring", false)


func iniciar_loop_luz() -> void:
	if loop_luz_rodando:
		return

	if not drone_ativo:
		return

	loop_luz_rodando = true
	var loop_local: int = loop_id

	while _loop_valido(loop_local):
		await get_tree().create_timer(pausa_luz_apagada).timeout

		if not _loop_valido(loop_local):
			break

		await acender_luz(loop_local)

		if not _loop_valido(loop_local):
			break

		await get_tree().create_timer(duracao_luz_ativa).timeout

		if not _loop_valido(loop_local):
			break

		await apagar_luz(loop_local)

	loop_luz_rodando = false


func acender_luz(loop_local: int) -> void:
	if not _loop_valido(loop_local):
		return

	if luz_visual == null or colisao_luz == null or luz_area == null:
		return

	luz_ativa = true
	jogador_atingido = false

	_matar_tween_luz()

	luz_visual.visible = true
	luz_visual.modulate.a = 0.0

	colisao_luz.set_deferred("disabled", false)
	luz_area.set_deferred("monitoring", true)

	tween_luz = create_tween()
	tween_luz.set_trans(Tween.TRANS_SINE)
	tween_luz.set_ease(Tween.EASE_OUT)
	tween_luz.tween_property(luz_visual, "modulate:a", alpha_luz_acesa, duracao_fadein_luz)

	await get_tree().create_timer(duracao_fadein_luz).timeout

	if not _loop_valido(loop_local):
		return

	_matar_tween_luz()

	if luz_visual != null:
		luz_visual.modulate.a = alpha_luz_acesa

	await checar_jogador_ja_dentro_da_luz()


func apagar_luz(loop_local: int) -> void:
	if not _loop_valido(loop_local):
		return

	if luz_visual == null or colisao_luz == null or luz_area == null:
		return

	_matar_tween_luz()

	tween_luz = create_tween()
	tween_luz.set_trans(Tween.TRANS_SINE)
	tween_luz.set_ease(Tween.EASE_IN)
	tween_luz.tween_property(luz_visual, "modulate:a", 0.0, duracao_fadeout_luz)

	await get_tree().create_timer(duracao_fadeout_luz).timeout

	if not _loop_valido(loop_local):
		return

	_matar_tween_luz()

	luz_visual.visible = false
	luz_visual.modulate.a = 0.0

	colisao_luz.set_deferred("disabled", true)
	luz_area.set_deferred("monitoring", false)

	luz_ativa = false
	jogador_atingido = false


func checar_jogador_ja_dentro_da_luz() -> void:
	await get_tree().physics_frame

	if not luz_ativa:
		return

	if luz_area == null:
		return

	for body in luz_area.get_overlapping_bodies():
		if body != null and body.is_in_group("player"):
			matar_jogador(body)
			return


func _on_luz_area_body_entered(body: Node2D) -> void:
	if not luz_ativa:
		return

	if jogador_atingido:
		return

	if not body.is_in_group("player"):
		return

	matar_jogador(body)


func matar_jogador(player: Node2D) -> void:
	if jogador_atingido:
		return

	jogador_atingido = true

	if player == null:
		jogador_atingido = false
		return

	if matar_ao_encostar:
		if player.has_method("cair_no_void"):
			player.cair_no_void()
		elif player.has_method("take_damage"):
			player.take_damage(999)
	else:
		if player.has_method("take_damage"):
			player.take_damage(1)

	await get_tree().create_timer(0.35).timeout

	if is_inside_tree():
		jogador_atingido = false


func _loop_valido(loop_local: int) -> bool:
	if not is_inside_tree():
		return false

	if not drone_ativo:
		return false

	if loop_local != loop_id:
		return false

	return true


func _matar_tween_luz() -> void:
	if tween_luz != null:
		if tween_luz.is_valid():
			tween_luz.kill()

	tween_luz = null


func _exit_tree() -> void:
	loop_luz_rodando = false
	drone_ativo = false
	luz_ativa = false
	jogador_atingido = false
	loop_id += 1

	_matar_tween_luz()
