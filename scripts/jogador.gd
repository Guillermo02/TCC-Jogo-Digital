extends CharacterBody2D

const WALK_SPEED := 50.0
const RUN_SPEED := 130.0
const JUMP_VELOCITY := -250.0
const CLIMB_SPEED := 80.0
const ATTACK_STOP_SPEED := 0.0
const DAMAGE_KNOCKBACK_X := 120.0
const DAMAGE_KNOCKBACK_Y := -120.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ladder_sprite: AnimatedSprite2D = $AnimatedSprite2D2

var can_climb := false
var is_climbing := false
var is_attacking := false
var is_hurt := false
var pode_mover := true


func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.visible = true
	ladder_sprite.visible = false
	sprite.play("idle")


func set_pode_mover(valor: bool) -> void:
	pode_mover = valor

	if not pode_mover:
		velocity = Vector2.ZERO
		is_attacking = false
		is_climbing = false
		is_hurt = false
		atualizar_animacao(0.0, 0.0, false)


func _physics_process(delta: float) -> void:
	if not pode_mover:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up", "move_down")
	var is_running := Input.is_action_pressed("run") and direction_x != 0.0

	if is_hurt:
		processar_estado_hurt(delta, direction_x, direction_y, is_running)
		return

	if is_attacking:
		processar_estado_ataque(delta)
		return

	if Input.is_action_just_pressed("attack"):
		iniciar_ataque()
		move_and_slide()
		return

	processar_escalada(direction_x, direction_y)

	if is_climbing:
		processar_movimento_escalada(direction_x, direction_y)
	else:
		processar_movimento_chao_ar(delta, direction_x, is_running)

	move_and_slide()
	atualizar_animacao(direction_x, direction_y, is_running)


func processar_estado_hurt(delta: float, direction_x: float, direction_y: float, is_running: bool) -> void:
	if not is_on_floor() and not is_climbing:
		velocity += get_gravity() * delta

	move_and_slide()
	atualizar_animacao(direction_x, direction_y, is_running)


func processar_estado_ataque(delta: float) -> void:
	velocity.x = ATTACK_STOP_SPEED

	if not is_on_floor() and not is_climbing:
		velocity += get_gravity() * delta

	move_and_slide()
	atualizar_animacao(0.0, 0.0, false)


func iniciar_ataque() -> void:
	if is_attacking or is_hurt or not pode_mover:
		return

	is_attacking = true
	is_climbing = false
	velocity.x = 0.0

	mostrar_sprite_normal()
	sprite.play("attack")


func processar_escalada(direction_x: float, direction_y: float) -> void:
	if can_climb and (Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")):
		is_climbing = true

	if not can_climb:
		is_climbing = false

	if is_climbing and Input.is_action_just_pressed("jump"):
		is_climbing = false
		velocity.y = JUMP_VELOCITY


func processar_movimento_escalada(direction_x: float, direction_y: float) -> void:
	velocity.y = direction_y * CLIMB_SPEED
	velocity.x = direction_x * WALK_SPEED * 0.5


func processar_movimento_chao_ar(delta: float, direction_x: float, is_running: bool) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var current_speed := RUN_SPEED if is_running else WALK_SPEED

	if direction_x != 0.0:
		velocity.x = direction_x * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func mostrar_sprite_normal() -> void:
	sprite.visible = true
	ladder_sprite.visible = false


func mostrar_sprite_ladder() -> void:
	sprite.visible = false
	ladder_sprite.visible = true


func atualizar_animacao(direction_x: float, direction_y: float, is_running: bool) -> void:
	if direction_x > 0.0:
		sprite.flip_h = false
		ladder_sprite.flip_h = false
	elif direction_x < 0.0:
		sprite.flip_h = true
		ladder_sprite.flip_h = true

	if is_hurt:
		mostrar_sprite_normal()
		if sprite.animation != "hurt":
			sprite.play("hurt")
		return

	if is_attacking:
		mostrar_sprite_normal()
		if sprite.animation != "attack":
			sprite.play("attack")
		return

	if is_climbing:
		mostrar_sprite_ladder()

		if direction_y != 0.0:
			if ladder_sprite.animation != "ladder":
				ladder_sprite.play("ladder")
			elif not ladder_sprite.is_playing():
				ladder_sprite.play("ladder")
		else:
			ladder_sprite.pause()
		return

	mostrar_sprite_normal()

	if not is_on_floor():
		if sprite.animation != "jump":
			sprite.play("jump")
		return

	if direction_x == 0.0:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		if is_running:
			if sprite.animation != "run":
				sprite.play("run")
		else:
			if sprite.animation != "walk":
				sprite.play("walk")


func take_damage(from_direction: float = 0.0) -> void:
	if is_hurt:
		return

	is_hurt = true
	is_attacking = false
	is_climbing = false

	velocity.x = from_direction * DAMAGE_KNOCKBACK_X
	velocity.y = DAMAGE_KNOCKBACK_Y

	mostrar_sprite_normal()
	sprite.play("hurt")


func _on_sprite_animation_finished() -> void:
	match sprite.animation:
		"attack":
			is_attacking = false
		"hurt":
			is_hurt = false
