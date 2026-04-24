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


func _ready() -> void:
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
	regen_timer.timeout.connect(_on_regen_timer_timeout)

	damage_indicator_timer.one_shot = true
	damage_indicator_timer.wait_time = damage_indicator_duration
	damage_indicator_timer.timeout.connect(_on_damage_indicator_timer_timeout)


func _cache_textures() -> void:
	heart_full_tex = heart_nodes[0].texture
	heart_cracked_tex = heart_nodes[1].texture
	heart_empty_tex = heart_nodes[2].texture

	shield_full_tex = shield_nodes[0].texture
	shield_broken_tex = shield_nodes[2].texture


func toggle_hud() -> void:
	hud_hidden = not hud_hidden

	var tween := create_tween()
	if hud_hidden:
		tween.tween_property(background_panel, "modulate:a", 0.0, 0.2)
	else:
		tween.tween_property(background_panel, "modulate:a", 1.0, 0.2)


func take_damage(amount: int = 1) -> void:
	for i in range(amount):
		_apply_single_damage()

	update_hearts()
	update_shields()
	_show_damage_indicator()
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

	var shield := shield_nodes[index]
	var tween := create_tween()

	for i in range(4):
		tween.tween_property(shield, "modulate:a", 0.15, shield_blink_duration / 8.0)
		tween.tween_property(shield, "modulate:a", 1.0, shield_blink_duration / 8.0)


func _show_damage_indicator() -> void:
	damage_indicator_timer.stop()
	damage_indicator.visible = true
	damage_indicator.modulate = Color(1, 1, 1, 1.0)

	var base_pos := damage_indicator.position
	var tween := create_tween()
	tween.tween_property(damage_indicator, "position", base_pos + Vector2(3, 0), 0.06)
	tween.tween_property(damage_indicator, "position", base_pos + Vector2(-3, 0), 0.06)
	tween.tween_property(damage_indicator, "position", base_pos + Vector2(3, 0), 0.06)
	tween.tween_property(damage_indicator, "position", base_pos + Vector2(-3, 0), 0.06)
	tween.tween_property(damage_indicator, "position", base_pos, 0.06)

	damage_indicator_timer.start()


func _hide_damage_indicator_immediately() -> void:
	damage_indicator.visible = false
	damage_indicator.modulate = Color(1, 1, 1, 0.0)


func _on_damage_indicator_timer_timeout() -> void:
	var tween := create_tween()
	tween.tween_property(damage_indicator, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): damage_indicator.visible = false)


func _on_regen_timer_timeout() -> void:
	_regen_all_hearts_slowly()


func _regen_all_hearts_slowly() -> void:
	var tween := create_tween()

	while current_hearts < max_hearts or heart_damage_stage == 1:
		tween.tween_interval(0.35)
		tween.tween_callback(_regen_step)


func _regen_step() -> void:
	_restore_one_heart_step()
	update_hearts()


func set_health_and_shields(hearts: int, shields: int, cracked: bool = false) -> void:
	current_hearts = clamp(hearts, 0, max_hearts)
	current_shields = clamp(shields, 0, max_shields)
	heart_damage_stage = 1 if cracked else 0
	update_hearts()
	update_shields()
