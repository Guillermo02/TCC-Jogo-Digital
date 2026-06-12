extends CharacterBody2D

const WALK_SPEED := 50.0
const RUN_SPEED := 130.0
const JUMP_VELOCITY := -250.0
const CLIMB_SPEED := 80.0
const ATTACK_STOP_SPEED := 0.0
const DAMAGE_KNOCKBACK_X := 120.0
const DAMAGE_KNOCKBACK_Y := -120.0

const HURT_DURATION := 0.35
const INVULNERABLE_DURATION := 0.85

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PLAYER_ATTACK := 8

@export var fall_limit_y: float = 1000.0

# Cooldown real entre ataques.
# Evita spam pesado de clique/botão e deixa o combate mais legível.
@export var attack_cooldown: float = 0.22

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ladder_sprite: AnimatedSprite2D = $AnimatedSprite2D2
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D

var can_climb := false
var is_climbing := false
var is_attacking := false
var is_hurt := false
var is_invulnerable := false
var pode_mover := true
var spawn_position: Vector2
var is_respawning := false

var can_attack := true
var attack_cooldown_id: int = 0

var facing_direction := 1.0
var inimigos_acertados_no_ataque: Array[Node] = []


func _ready() -> void:
	spawn_position = global_position

	if not sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.connect(_on_sprite_animation_finished)

	sprite.visible = true
	ladder_sprite.visible = false

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	add_to_group("player")

	if attack_area != null:
		attack_area.collision_layer = LAYER_PLAYER_ATTACK
		attack_area.collision_mask = LAYER_ENEMY
		attack_area.monitoring = false
		attack_area.monitorable = true

		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)

		if not attack_area.area_entered.is_connected(_on_attack_area_area_entered):
			attack_area.area_entered.connect(_on_attack_area_area_entered)


func set_pode_mover(valor: bool) -> void:
	pode_mover = valor

	if not pode_mover:
		if is_attacking:
			iniciar_cooldown_ataque()

		velocity = Vector2.ZERO
		is_climbing = false
		is_attacking = false

		if attack_area != null:
			attack_area.monitoring = false

		if not is_hurt:
			atualizar_animacao(0.0, 0.0, false)


func set_controle_bloqueado(valor: bool) -> void:
	set_pode_mover(not valor)


func set_controles_bloqueados(valor: bool) -> void:
	set_pode_mover(not valor)


func bloquear_controle(valor: bool) -> void:
	set_pode_mover(not valor)


func set_can_move(valor: bool) -> void:
	set_pode_mover(valor)


func _physics_process(delta: float) -> void:
	if is_respawning:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if global_position.y > fall_limit_y:
		cair_no_void()
		return

	if not pode_mover and not is_hurt:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up", "move_down")
	var is_running := Input.is_action_pressed("run") and direction_x != 0.0

	atualizar_direcao(direction_x)

	if is_hurt:
		processar_estado_hurt(delta)
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


func atualizar_direcao(direction_x: float) -> void:
	if direction_x > 0.0:
		facing_direction = 1.0
		sprite.flip_h = false
		ladder_sprite.flip_h = false
		atualizar_lado_attack_area()
	elif direction_x < 0.0:
		facing_direction = -1.0
		sprite.flip_h = true
		ladder_sprite.flip_h = true
		atualizar_lado_attack_area()


func atualizar_lado_attack_area() -> void:
	if attack_area == null:
		return

	attack_area.scale.x = facing_direction


func tocar_attack_botao() -> void:
	if is_attacking or is_hurt or is_respawning or not pode_mover or not can_attack:
		return

	iniciar_ataque()


func cair_no_void() -> void:
	if is_respawning:
		return

	is_respawning = true
	set_pode_mover(false)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("take_damage"):
		hud.take_damage(1)

	await iniciar_fade_e_respawn()

	is_respawning = false
	set_pode_mover(true)


func iniciar_fade_e_respawn() -> void:
	var fade_rect = get_tree().get_first_node_in_group("fade")

	if fade_rect:
		var tween_out := create_tween()
		tween_out.tween_property(fade_rect, "modulate:a", 1.0, 0.45)
		await tween_out.finished

	global_position = spawn_position
	velocity = Vector2.ZERO

	await get_tree().create_timer(0.15).timeout

	if fade_rect:
		var tween_in := create_tween()
		tween_in.tween_property(fade_rect, "modulate:a", 0.0, 0.45)
		await tween_in.finished


func processar_estado_hurt(delta: float) -> void:
	if not is_on_floor() and not is_climbing:
		velocity += get_gravity() * delta

	velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 2.0 * delta)

	move_and_slide()

	mostrar_sprite_normal()

	if sprite.sprite_frames.has_animation("hurt") and sprite.animation != "hurt":
		sprite.play("hurt")


func processar_estado_ataque(delta: float) -> void:
	velocity.x = ATTACK_STOP_SPEED

	if not is_on_floor() and not is_climbing:
		velocity += get_gravity() * delta

	move_and_slide()
	atualizar_animacao(0.0, 0.0, false)


func iniciar_ataque() -> void:
	if is_attacking or is_hurt or not pode_mover or not can_attack:
		return

	can_attack = false
	is_attacking = true
	is_climbing = false
	velocity.x = 0.0
	inimigos_acertados_no_ataque.clear()

	mostrar_sprite_normal()
	atualizar_lado_attack_area()

	if attack_area != null:
		attack_area.monitoring = true
		checar_alvos_sobrepostos_no_ataque()

	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	else:
		await get_tree().create_timer(0.25).timeout
		finalizar_ataque()


func checar_alvos_sobrepostos_no_ataque() -> void:
	await get_tree().physics_frame

	if not is_attacking:
		return

	if attack_area == null:
		return

	for body in attack_area.get_overlapping_bodies():
		tentar_acertar_alvo(body)

	for area in attack_area.get_overlapping_areas():
		var alvo := area.get_parent()
		tentar_acertar_alvo(alvo)


func finalizar_ataque() -> void:
	if not is_attacking:
		return

	is_attacking = false

	if attack_area != null:
		attack_area.monitoring = false

	if not is_hurt and not is_respawning:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

	iniciar_cooldown_ataque()


func iniciar_cooldown_ataque() -> void:
	attack_cooldown_id += 1
	var cooldown_local := attack_cooldown_id

	await get_tree().create_timer(attack_cooldown).timeout

	if cooldown_local != attack_cooldown_id:
		return

	if not is_respawning:
		can_attack = true


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
	if is_hurt:
		mostrar_sprite_normal()
		if sprite.sprite_frames.has_animation("hurt") and sprite.animation != "hurt":
			sprite.play("hurt")
		return

	if is_attacking:
		mostrar_sprite_normal()
		if sprite.sprite_frames.has_animation("attack") and sprite.animation != "attack":
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
		if sprite.sprite_frames.has_animation("jump") and sprite.animation != "jump":
			sprite.play("jump")
		return

	if direction_x == 0.0:
		if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
			sprite.play("idle")
	else:
		if is_running:
			if sprite.sprite_frames.has_animation("run") and sprite.animation != "run":
				sprite.play("run")
		else:
			if sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
				sprite.play("walk")


func take_damage(from_direction: float = 0.0) -> void:
	if is_invulnerable or is_respawning:
		return

	if is_attacking:
		is_attacking = false
		iniciar_cooldown_ataque()

	is_invulnerable = true
	is_hurt = true
	is_climbing = false

	if attack_area != null:
		attack_area.monitoring = false

	var direcao_knockback := from_direction

	if direcao_knockback == 0.0:
		direcao_knockback = -facing_direction

	velocity.x = direcao_knockback * DAMAGE_KNOCKBACK_X
	velocity.y = DAMAGE_KNOCKBACK_Y

	mostrar_sprite_normal()

	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("take_damage"):
		hud.take_damage(1)

	await get_tree().create_timer(HURT_DURATION).timeout

	is_hurt = false

	await get_tree().create_timer(INVULNERABLE_DURATION - HURT_DURATION).timeout

	is_invulnerable = false


func tentar_acertar_alvo(alvo: Node) -> void:
	if not is_attacking:
		return

	if alvo == null:
		return

	if inimigos_acertados_no_ataque.has(alvo):
		return

	if alvo.has_method("take_hit"):
		inimigos_acertados_no_ataque.append(alvo)
		alvo.take_hit(1)


func _on_attack_area_body_entered(body: Node2D) -> void:
	tentar_acertar_alvo(body)


func _on_attack_area_area_entered(area: Area2D) -> void:
	var alvo := area.get_parent()
	tentar_acertar_alvo(alvo)


func _on_sprite_animation_finished() -> void:
	match sprite.animation:
		"attack":
			finalizar_ataque()
		"hurt":
			pass
