extends CharacterBody2D

signal derrotado(prefeito: Node)

const GRAVITY_MULTIPLIER := 1.0

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PLAYER_ATTACK := 8

@export var speed: float = 90.0
@export var max_hits: int = 10
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var attack_hit_delay: float = 0.25

@export var attack_range_x: float = 46.0
@export var attack_range_y: float = 58.0

@export var zona_morta_player_x: float = 8.0

@export var hurt_knockback_x: float = 18.0
@export var hurt_knockback_y: float = 0.0
@export var hurt_knockback_freio: float = 260.0

# Prefeito segura mais antes do stun longo.
@export var hits_para_stun: int = 3
@export var hit_reaction_duration: float = 0.20
@export var hit_flash_duration: float = 0.08
@export var hit_micro_knockback_x: float = 8.0

# Contra-ataque controlado.
@export var hits_para_contra_ataque: int = 3
@export var contra_ataque_delay: float = 0.60
@export var contra_ataque_cooldown: float = 1.35

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var corpo: CollisionShape2D = $Corpo
@onready var attack_area: Area2D = $AttackArea
@onready var attack_area_collision: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var icone_capanga: Node2D = get_node_or_null("IconeCapanga") as Node2D

var player: Node2D = null

var active := false
var dead := false
var attacking := false
var hurt := false

var hits_taken := 0
var player_in_attack_area := false
var can_attack := true
var facing_direction: float = -1.0

var icone_sumindo := false
var derrota_emitida := false

var contador_hits_para_stun := 0
var contador_hits_para_contra_ataque := 0
var contra_ataque_em_espera := false
var pode_contra_atacar := true

var estado_id: int = 0
var tween_icone: Tween = null
var sprite_modulate_padrao: Color = Color.WHITE


func _ready() -> void:
	add_to_group("prefeito")

	sprite_modulate_padrao = sprite.modulate

	configurar_colisoes()

	if is_instance_valid(icone_capanga):
		icone_capanga.show()
		icone_capanga.modulate.a = 1.0

	if sprite.sprite_frames.has_animation("dead"):
		sprite.sprite_frames.set_animation_loop("dead", false)

	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

	if not sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.connect(_on_sprite_animation_finished)

	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	if not attack_area.body_exited.is_connected(_on_attack_area_body_exited):
		attack_area.body_exited.connect(_on_attack_area_body_exited)

	active = false


func configurar_colisoes() -> void:
	collision_layer = LAYER_ENEMY
	collision_mask = LAYER_WORLD

	attack_area.collision_layer = 0
	attack_area.collision_mask = LAYER_PLAYER
	attack_area.monitoring = true
	attack_area.monitorable = true

	if is_instance_valid(attack_area_collision):
		attack_area_collision.set_deferred("disabled", false)

	hurtbox.collision_layer = LAYER_ENEMY
	hurtbox.collision_mask = LAYER_PLAYER_ATTACK
	hurtbox.monitoring = true
	hurtbox.monitorable = true

	if is_instance_valid(hurtbox_collision):
		hurtbox_collision.set_deferred("disabled", false)


func activate(target: Node2D) -> void:
	if dead:
		return

	if target == null or not is_instance_valid(target):
		return

	estado_id += 1

	player = target
	active = true
	player_in_attack_area = false
	can_attack = true
	attacking = false
	hurt = false

	if speed <= 0.0:
		speed = 105.0

	configurar_colisoes()
	adicionar_excecoes_de_colisao()


func adicionar_excecoes_de_colisao() -> void:
	if player is PhysicsBody2D:
		add_collision_exception_with(player)

	for outro_inimigo in get_tree().get_nodes_in_group("capanga_agressivo"):
		if outro_inimigo == self:
			continue

		if outro_inimigo is PhysicsBody2D:
			add_collision_exception_with(outro_inimigo)
			outro_inimigo.add_collision_exception_with(self)


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	aplicar_gravidade(delta)

	if not active or player == null or not is_instance_valid(player):
		velocity.x = move_toward(velocity.x, 0.0, speed)
		move_and_slide()
		tocar_animacao_idle_se_precisar()
		return

	atualizar_direcao_para_o_jogador()
	atualizar_estado_attack_area()

	if hurt:
		velocity.x = move_toward(velocity.x, 0.0, hurt_knockback_freio * delta)
		move_and_slide()
		return

	if attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	if jogador_no_alcance_de_ataque():
		velocity.x = 0.0
		move_and_slide()

		if can_attack:
			iniciar_ataque()
		else:
			tocar_animacao_idle_se_precisar()

		return

	if jogador_muito_em_cima():
		velocity.x = 0.0
		move_and_slide()

		if can_attack:
			iniciar_ataque()
		else:
			tocar_animacao_idle_se_precisar()

		return

	perseguir_jogador()

	move_and_slide()
	atualizar_animacao_movimento()


func aplicar_gravidade(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0


func atualizar_direcao_para_o_jogador() -> void:
	if player == null or not is_instance_valid(player):
		return

	var diferenca_x: float = player.global_position.x - global_position.x

	if absf(diferenca_x) <= zona_morta_player_x:
		return

	facing_direction = signf(diferenca_x)

	sprite.flip_h = facing_direction < 0.0
	attack_area.scale.x = facing_direction


func atualizar_estado_attack_area() -> void:
	if player == null or not is_instance_valid(player):
		player_in_attack_area = false
		return

	player_in_attack_area = false

	for body in attack_area.get_overlapping_bodies():
		if body == player:
			player_in_attack_area = true
			return


func perseguir_jogador() -> void:
	if player == null or not is_instance_valid(player):
		return

	var diferenca_x: float = player.global_position.x - global_position.x

	if absf(diferenca_x) <= zona_morta_player_x:
		velocity.x = 0.0
		return

	facing_direction = signf(diferenca_x)
	velocity.x = facing_direction * speed


func jogador_muito_em_cima() -> bool:
	if player == null or not is_instance_valid(player):
		return false

	var distancia := player.global_position - global_position

	return absf(distancia.x) <= zona_morta_player_x and absf(distancia.y) <= attack_range_y


func jogador_no_alcance_de_ataque() -> bool:
	if player == null or not is_instance_valid(player):
		return false

	var distancia: Vector2 = player.global_position - global_position
	var dentro_do_alcance_por_distancia := absf(distancia.x) <= attack_range_x and absf(distancia.y) <= attack_range_y

	if player_in_attack_area and dentro_do_alcance_por_distancia:
		return true

	if dentro_do_alcance_por_distancia:
		return true

	return false


func iniciar_ataque() -> void:
	if attacking or hurt or dead or not can_attack:
		return

	attacking = true
	can_attack = false
	velocity.x = 0.0

	var estado_local := estado_id

	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

	await get_tree().create_timer(attack_hit_delay).timeout

	if not _estado_valido(estado_local):
		return

	if dead or hurt:
		attacking = false

		if not dead:
			can_attack = true

		return

	causar_dano_se_jogador_ainda_estiver_no_alcance()

	await get_tree().create_timer(attack_cooldown).timeout

	if not _estado_valido(estado_local):
		return

	attacking = false

	if not dead:
		can_attack = true


func causar_dano_se_jogador_ainda_estiver_no_alcance() -> void:
	if player == null or not is_instance_valid(player):
		return

	if not jogador_no_alcance_de_ataque():
		return

	if player.has_method("take_damage"):
		var direcao_do_golpe: float = signf(player.global_position.x - global_position.x)

		if direcao_do_golpe == 0.0:
			direcao_do_golpe = facing_direction

		player.take_damage(direcao_do_golpe)


func aplicar_knockback_de_hit() -> void:
	var direcao_knockback := 0.0

	if player != null and is_instance_valid(player):
		direcao_knockback = signf(global_position.x - player.global_position.x)

	if direcao_knockback == 0.0:
		direcao_knockback = -facing_direction

	velocity.x = direcao_knockback * hurt_knockback_x

	if hurt_knockback_y != 0.0:
		velocity.y = hurt_knockback_y


func calcular_direcao_knockback() -> float:
	var direcao_knockback := 0.0

	if player != null and is_instance_valid(player):
		direcao_knockback = signf(global_position.x - player.global_position.x)

	if direcao_knockback == 0.0:
		direcao_knockback = -facing_direction

	return direcao_knockback


func take_hit(damage: int = 1) -> void:
	if dead:
		return

	estado_id += 1

	hits_taken += damage

	if hits_taken >= max_hits:
		morrer()
		return

	contador_hits_para_stun += 1
	contador_hits_para_contra_ataque += 1

	var limite_stun := maxi(1, hits_para_stun)
	var limite_contra_ataque := maxi(1, hits_para_contra_ataque)

	var deve_stunar := contador_hits_para_stun >= limite_stun
	var deve_contra_atacar := contador_hits_para_contra_ataque >= limite_contra_ataque

	if deve_stunar:
		contador_hits_para_stun = 0

	if deve_contra_atacar:
		contador_hits_para_contra_ataque = 0

	attacking = false
	can_attack = false
	hurt = true
	velocity.x = 0.0

	var estado_local := estado_id
	var direcao_knockback := calcular_direcao_knockback()

	if deve_stunar:
		velocity.x = direcao_knockback * hurt_knockback_x

		if hurt_knockback_y != 0.0:
			velocity.y = hurt_knockback_y
	else:
		velocity.x = direcao_knockback * hit_micro_knockback_x

	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

	sprite.modulate = Color(1.0, 0.55, 0.55, 1.0)

	await get_tree().create_timer(hit_flash_duration).timeout

	if is_instance_valid(sprite):
		sprite.modulate = sprite_modulate_padrao

	if not _estado_valido(estado_local):
		return

	if deve_stunar:
		await get_tree().create_timer(0.35).timeout
	else:
		await get_tree().create_timer(hit_reaction_duration).timeout

	if not _estado_valido(estado_local):
		return

	hurt = false

	if not dead:
		attacking = false
		can_attack = true

	if deve_contra_atacar:
		solicitar_contra_ataque()


func solicitar_contra_ataque() -> void:
	if dead or contra_ataque_em_espera or not pode_contra_atacar:
		return

	if player == null or not is_instance_valid(player):
		return

	contra_ataque_em_espera = true
	pode_contra_atacar = false

	await get_tree().create_timer(contra_ataque_delay).timeout

	contra_ataque_em_espera = false

	if is_inside_tree() and not dead and not hurt and not attacking and can_attack:
		if jogador_no_alcance_de_ataque():
			iniciar_ataque()

	await get_tree().create_timer(contra_ataque_cooldown).timeout

	if is_inside_tree() and not dead:
		pode_contra_atacar = true


func morrer() -> void:
	if dead:
		return

	estado_id += 1

	dead = true
	active = false
	attacking = false
	hurt = false
	can_attack = false
	player_in_attack_area = false
	velocity = Vector2.ZERO

	if is_instance_valid(sprite):
		sprite.modulate = sprite_modulate_padrao

	if sprite.sprite_frames.has_animation("dead"):
		sprite.sprite_frames.set_animation_loop("dead", false)
		sprite.play("dead")
	else:
		travar_no_ultimo_frame_dead()

	if is_instance_valid(corpo):
		corpo.set_deferred("disabled", true)

	if is_instance_valid(attack_area):
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)

	if is_instance_valid(attack_area_collision):
		attack_area_collision.set_deferred("disabled", true)

	if is_instance_valid(hurtbox):
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	if is_instance_valid(hurtbox_collision):
		hurtbox_collision.set_deferred("disabled", true)

	sumir_icone_capanga_suave()

	call_deferred("set_physics_process", false)

	if not derrota_emitida:
		derrota_emitida = true
		derrotado.emit(self)


func travar_no_ultimo_frame_dead() -> void:
	if not sprite.sprite_frames.has_animation("dead"):
		return

	var total_frames := sprite.sprite_frames.get_frame_count("dead")

	if total_frames <= 0:
		return

	sprite.animation = "dead"
	sprite.frame = total_frames - 1
	sprite.pause()


func sumir_icone_capanga_suave() -> void:
	if icone_sumindo:
		return

	if not is_instance_valid(icone_capanga):
		return

	if not icone_capanga.visible:
		return

	icone_sumindo = true

	_matar_tween_icone()

	tween_icone = create_tween()
	tween_icone.set_trans(Tween.TRANS_SINE)
	tween_icone.set_ease(Tween.EASE_IN_OUT)
	tween_icone.tween_property(icone_capanga, "modulate:a", 0.0, 0.75)

	await get_tree().create_timer(0.75).timeout

	_matar_tween_icone()

	if is_instance_valid(icone_capanga):
		icone_capanga.hide()
		icone_capanga.modulate.a = 1.0

	icone_sumindo = false


func tocar_animacao_idle_se_precisar() -> void:
	if sprite.sprite_frames.has_animation("idle") and sprite.animation != "idle":
		sprite.play("idle")


func atualizar_animacao_movimento() -> void:
	if dead or attacking or hurt:
		return

	if absf(velocity.x) > 1.0:
		if sprite.sprite_frames.has_animation("run") and sprite.animation != "run":
			sprite.play("run")
		elif sprite.sprite_frames.has_animation("walk") and sprite.animation != "walk":
			sprite.play("walk")
	else:
		tocar_animacao_idle_se_precisar()


func _estado_valido(estado_local: int) -> bool:
	if not is_inside_tree():
		return false

	if dead:
		return false

	if estado_local != estado_id:
		return false

	return true


func _matar_tween_icone() -> void:
	if tween_icone != null:
		if tween_icone.is_valid():
			tween_icone.kill()

	tween_icone = null


func _on_sprite_animation_finished() -> void:
	if dead and sprite.animation == "dead":
		travar_no_ultimo_frame_dead()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = true
		player = body


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = false


func _exit_tree() -> void:
	estado_id += 1
	_matar_tween_icone()
