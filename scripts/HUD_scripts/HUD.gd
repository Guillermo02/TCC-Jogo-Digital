extends CanvasLayer

@export_range(1, 3) var max_hearts: int = 3
@export_range(1, 3) var max_shields: int = 3
@export var health_regen_delay: float = 10.0
@export var damage_indicator_duration: float = 1.5
@export var shield_blink_duration: float = 1.0
@export var hud_toggle_action: StringName = &"toggle_hud"

@onready var background_panel: Panel = $BackgroundPanel

@onready var heart_nodes: Array[TextureRect] = [
	$BackgroundPanel/HeartsRow/Heart1,
	$BackgroundPanel/HeartsRow/Heart2,
	$BackgroundPanel/HeartsRow/Heart3
]

@onready var shield_nodes: Array[TextureRect] = [
	$BackgroundPanel/ShieldsRow/Shield1,
	$BackgroundPanel/ShieldsRow/Shield2,
	$BackgroundPanel/ShieldsRow/Shield3
]

@onready var damage_indicator: TextureRect = $BackgroundPanel/DamageIndicator
@onready var regen_timer: Timer = $RegenTimer
@onready var damage_indicator_timer: Timer = $DamageIndicatorTimer

var current_hearts: int = 3
var current_shields: int = 3
var heart_damage_stage: int = 0
var hud_hidden := false

var heart_full_tex: Texture2D
var heart_cracked_tex: Texture2D
var heart_empty_tex: Texture2D

var shield_full_tex: Texture2D
var shield_broken_tex: Texture2D

var hud_tween: Tween = null
var damage_indicator_tween: Tween = null
var damage_indicator_fade_tween: Tween = null
var regen_tween: Tween = null
var shield_blink_tweens := {}


func _ready() -> void:
	add_to_group("hud")

	_setup_input_action()
	_setup_panel_style()
	_setup_nodes()
	_setup_timers()
	_cache_textures()

	current_hearts = max_hearts
	current_shields = max_shields
	heart_damage_stage = 0

	update_hearts()
	update_shields()
	_hide_damage_indicator_immediately()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(hud_toggle_action):
		toggle_hud()


func _setup_input_action() -> void:
	if not InputMap.has_action(hud_toggle_action):
		InputMap.add_action(hud_toggle_action)

		var key_event := InputEventKey.new()
		key_event.physical_keycode = KEY_O
		InputMap.action_add_event(hud_toggle_action, key_event)


func _setup_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22

	background_panel.add_theme_stylebox_override("panel", style)
	background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_nodes() -> void:
	for heart in heart_nodes:
		heart.custom_minimum_size = Vector2(24, 24)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	for shield in shield_nodes:
		shield.custom_minimum_size = Vector2(24, 24)
		shield.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shield.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	damage_indicator.custom_minimum_size = Vector2(28, 28)
	damage_indicator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	damage_indicator.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _setup_timers() -> void:
	regen_timer.one_shot = true
	regen_timer.wait_time = health_regen_delay

	if not regen_timer.timeout.is_connected(_on_regen_timer_timeout):
		regen_timer.timeout.connect(_on_regen_timer_timeout)

	damage_indicator_timer.one_shot = true
	damage_indicator_timer.wait_time = damage_indicator_duration

	if not damage_indicator_timer.timeout.is_connected(_on_damage_indicator_timer_timeout):
		damage_indicator_timer.timeout.connect(_on_damage_indicator_timer_timeout)


func _cache_textures() -> void:
	heart_full_tex = heart_nodes[0].texture
	heart_cracked_tex = heart_nodes[1].texture
	heart_empty_tex = heart_nodes[2].texture

	shield_full_tex = shield_nodes[0].texture
	shield_broken_tex = shield_nodes[2].texture


func toggle_hud() -> void:
	hud_hidden = not hud_hidden

	_kill_tween(hud_tween)

	hud_tween = create_tween()

	if hud_hidden:
		hud_tween.tween_property(background_panel, "modulate:a", 0.0, 0.2)
	else:
		hud_tween.tween_property(background_panel, "modulate:a", 1.0, 0.2)

	hud_tween.tween_callback(func():
		hud_tween = null
	)


func take_damage(amount: int = 1) -> void:
	_kill_regen_tween()

	for i in range(amount):
		_apply_single_damage()

	update_hearts()
	update_shields()
	_show_damage_indicator()

	regen_timer.stop()
	regen_timer.start()

	if current_hearts <= 0:
		_on_player_death()


func _apply_single_damage() -> void:
	if current_shields > 0:
		var damaged_shield_index := current_shields - 1
		current_shields -= 1
		update_shields()
		_blink_shield(damaged_shield_index)
		return

	if current_hearts <= 0:
		return

	if heart_damage_stage == 0:
		heart_damage_stage = 1
	else:
		heart_damage_stage = 0
		current_hearts -= 1


func heal_shield(amount: int = 1) -> void:
	current_shields = clamp(current_shields + amount, 0, max_shields)
	update_shields()


func full_restore_shields() -> void:
	current_shields = max_shields
	update_shields()


func heal_heart_unit(amount: int = 1) -> void:
	for i in range(amount):
		_restore_one_heart_step()

	update_hearts()


func full_restore_health() -> void:
	current_hearts = max_hearts
	heart_damage_stage = 0
	update_hearts()


func restaurar_um_coracao_ou_um_escudo() -> void:
	regen_timer.stop()
	_kill_regen_tween()

	if vida_nao_esta_cheia():
		restaurar_um_coracao_inteiro()
		update_hearts()
		return

	if current_shields < max_shields:
		current_shields += 1
		update_shields()


func vida_nao_esta_cheia() -> bool:
	if current_hearts < max_hearts:
		return true

	if heart_damage_stage == 1:
		return true

	return false


func restaurar_um_coracao_inteiro() -> void:
	if current_hearts <= 0:
		current_hearts = 1
		heart_damage_stage = 0
		return

	if heart_damage_stage == 1:
		heart_damage_stage = 0

		if current_hearts < max_hearts:
			current_hearts += 1

		return

	if current_hearts < max_hearts:
		current_hearts += 1
		heart_damage_stage = 0


func restaurar_vida_e_escudo_total() -> void:
	regen_timer.stop()
	_kill_regen_tween()

	current_hearts = max_hearts
	current_shields = max_shields
	heart_damage_stage = 0

	update_hearts()
	update_shields()


func _restore_one_heart_step() -> void:
	if current_hearts <= 0:
		current_hearts = 1
		heart_damage_stage = 1
		return

	if heart_damage_stage == 1:
		heart_damage_stage = 0
		return

	if current_hearts < max_hearts:
		current_hearts += 1
		heart_damage_stage = 0


func _on_player_death() -> void:
	regen_timer.stop()
	_kill_regen_tween()

	current_hearts = max_hearts
	current_shields = 0
	heart_damage_stage = 0

	update_hearts()
	update_shields()


func update_hearts() -> void:
	for i in range(max_hearts):
		var node := heart_nodes[i]

		if i < current_hearts - 1:
			node.texture = heart_full_tex
			node.modulate = Color(1, 1, 1, 1.0)
		elif i == current_hearts - 1 and current_hearts > 0:
			if heart_damage_stage == 0:
				node.texture = heart_full_tex
				node.modulate = Color(1, 1, 1, 1.0)
			else:
				node.texture = heart_cracked_tex
				node.modulate = Color(1, 1, 1, 1.0)
		else:
			node.texture = heart_empty_tex
			node.modulate = Color(1, 1, 1, 0.35)


func update_shields() -> void:
	for i in range(max_shields):
		var node := shield_nodes[i]

		if i < current_shields:
			node.texture = shield_full_tex
			node.modulate = Color(1, 1, 1, 1.0)
		else:
			node.texture = shield_broken_tex
			node.modulate = Color(1, 1, 1, 0.45)


func _blink_shield(index: int) -> void:
	if index < 0 or index >= shield_nodes.size():
		return

	if shield_blink_tweens.has(index):
		var old_tween: Tween = shield_blink_tweens[index]
		_kill_tween(old_tween)
		shield_blink_tweens.erase(index)

	var shield := shield_nodes[index]
	shield.modulate.a = 1.0

	var tween := create_tween()
	shield_blink_tweens[index] = tween

	for i in range(4):
		tween.tween_property(shield, "modulate:a", 0.15, shield_blink_duration / 8.0)
		tween.tween_property(shield, "modulate:a", 1.0, shield_blink_duration / 8.0)

	tween.tween_callback(func():
		if is_instance_valid(shield):
			shield.modulate.a = 1.0

		shield_blink_tweens.erase(index)
	)


func _show_damage_indicator() -> void:
	damage_indicator_timer.stop()

	_kill_tween(damage_indicator_tween)
	_kill_tween(damage_indicator_fade_tween)

	damage_indicator.position = damage_indicator.position
	damage_indicator.visible = true
	damage_indicator.modulate = Color(1, 1, 1, 1.0)

	var base_pos := damage_indicator.position

	damage_indicator_tween = create_tween()
	damage_indicator_tween.tween_property(damage_indicator, "position", base_pos + Vector2(3, 0), 0.06)
	damage_indicator_tween.tween_property(damage_indicator, "position", base_pos + Vector2(-3, 0), 0.06)
	damage_indicator_tween.tween_property(damage_indicator, "position", base_pos + Vector2(3, 0), 0.06)
	damage_indicator_tween.tween_property(damage_indicator, "position", base_pos + Vector2(-3, 0), 0.06)
	damage_indicator_tween.tween_property(damage_indicator, "position", base_pos, 0.06)
	damage_indicator_tween.tween_callback(func():
		damage_indicator_tween = null
	)

	damage_indicator_timer.start()


func _hide_damage_indicator_immediately() -> void:
	damage_indicator.visible = false
	damage_indicator.modulate = Color(1, 1, 1, 0.0)


func _on_damage_indicator_timer_timeout() -> void:
	_kill_tween(damage_indicator_fade_tween)

	damage_indicator_fade_tween = create_tween()
	damage_indicator_fade_tween.tween_property(damage_indicator, "modulate:a", 0.0, 0.25)
	damage_indicator_fade_tween.tween_callback(func():
		if is_instance_valid(damage_indicator):
			damage_indicator.visible = false

		damage_indicator_fade_tween = null
	)


func _on_regen_timer_timeout() -> void:
	_regen_all_hearts_slowly()


func _regen_all_hearts_slowly() -> void:
	_kill_regen_tween()

	if not vida_nao_esta_cheia():
		return

	regen_tween = create_tween()

	while current_hearts < max_hearts or heart_damage_stage == 1:
		regen_tween.tween_interval(0.35)
		regen_tween.tween_callback(_regen_step)

		if current_hearts >= max_hearts and heart_damage_stage == 0:
			break

	regen_tween.tween_callback(func():
		regen_tween = null
	)


func _regen_step() -> void:
	if not is_inside_tree():
		return

	_restore_one_heart_step()
	update_hearts()


func set_health_and_shields(hearts: int, shields: int, cracked: bool = false) -> void:
	current_hearts = clamp(hearts, 0, max_hearts)
	current_shields = clamp(shields, 0, max_shields)
	heart_damage_stage = 1 if cracked else 0

	update_hearts()
	update_shields()


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _kill_regen_tween() -> void:
	_kill_tween(regen_tween)
	regen_tween = null


func _exit_tree() -> void:
	regen_timer.stop()
	damage_indicator_timer.stop()

	_kill_tween(hud_tween)
	_kill_tween(damage_indicator_tween)
	_kill_tween(damage_indicator_fade_tween)
	_kill_regen_tween()

	for key in shield_blink_tweens.keys():
		var tween: Tween = shield_blink_tweens[key]
		_kill_tween(tween)

	shield_blink_tweens.clear()
