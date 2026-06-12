extends CharacterBody2D

signal chegou_ao_destino
signal saiu_da_tela

const GRAVITY_MULTIPLIER := 1.0

@export var speed: float = 95.0
@export var distancia_para_chegar: float = 4.0
@export var margem_sair_tela: float = 80.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var corpo: CollisionShape2D = $Corpo

var active := false
var indo_para_destino := false
var saindo_da_tela := false

var destino: Vector2
var facing_direction: float = -1.0


func _ready() -> void:
	active = false
	indo_para_destino = false
	saindo_da_tela = false

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _physics_process(delta: float) -> void:
	aplicar_gravidade(delta)

	if saindo_da_tela:
		correr_para_esquerda(delta)
		move_and_slide()

		if saiu_da_camera_pela_esquerda():
			saindo_da_tela = false
			velocity.x = 0.0
			saiu_da_tela.emit()

		return

	if indo_para_destino:
		mover_ate_destino()
		move_and_slide()
		return

	velocity.x = move_toward(velocity.x, 0.0, speed)
	move_and_slide()
	tocar_idle()


func aplicar_gravidade(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0


func ir_para_posicao(posicao_destino: Vector2) -> void:
	destino = posicao_destino
	active = true
	indo_para_destino = true
	saindo_da_tela = false


func mover_ate_destino() -> void:
	var diferenca_x := destino.x - global_position.x

	if absf(diferenca_x) <= distancia_para_chegar:
		velocity.x = 0.0
		indo_para_destino = false
		tocar_idle()
		chegou_ao_destino.emit()
		return

	facing_direction = signf(diferenca_x)
	sprite.flip_h = facing_direction < 0.0

	velocity.x = facing_direction * speed
	tocar_walk()


func sair_correndo_para_esquerda() -> void:
	active = true
	indo_para_destino = false
	saindo_da_tela = true
	facing_direction = -1.0
	sprite.flip_h = true
	tocar_walk()


func correr_para_esquerda(_delta: float) -> void:
	velocity.x = -speed
	sprite.flip_h = true
	tocar_walk()


func saiu_da_camera_pela_esquerda() -> bool:
	var camera := get_viewport().get_camera_2d()

	if camera == null:
		return global_position.x < -margem_sair_tela

	var centro_camera := camera.get_screen_center_position()
	var tamanho_tela := get_viewport_rect().size
	var metade_largura := tamanho_tela.x * camera.zoom.x * 0.5
	var limite_esquerdo := centro_camera.x - metade_largura - margem_sair_tela

	return global_position.x < limite_esquerdo


func tocar_idle() -> void:
	if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
		sprite.play("idle")


func tocar_walk() -> void:
	if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
		sprite.play("walk")
	elif sprite.sprite_frames.has_animation("run") and sprite.animation != "run":
		sprite.play("run")

func parar_movimento() -> void:
	active = false
	indo_para_destino = false
	saindo_da_tela = false
	velocity = Vector2.ZERO
	tocar_idle()
