extends CharacterBody2D

const SPEED = 250.0

@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer
@onready var flashlight_toggle_sound: AudioStreamPlayer2D = $FlashlightToggleSound

@export var footstep_interval: float = 0.3

var footstep_timer: float = 0.0
var is_invincible: bool = false
var invincible_timer: float = 0.0


func start_invincible(duration: float = 1.5) -> void:
	is_invincible = true
	invincible_timer = duration

	# 무적 중 반투명
	modulate.a = 0.45


func can_be_hit() -> bool:
	return not is_invincible


func end_invincible() -> void:
	is_invincible = false
	invincible_timer = 0.0

	# 원래 투명도 복구
	modulate.a = 1.0

# ── 배터리 설정 ───────────────────────────────────────────
const MAX_BATTERY : float = 100.0
const DRAIN_RATE  : float = 0.4
var battery       : float = MAX_BATTERY
var flashlight_on : bool  = false

signal battery_changed(value: float)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spot_light: PointLight2D = $PointLight2D
@onready var flashlight_area: Area2D = $PointLight2D/Area2D

var last_direction = Vector2.DOWN


func _ready() -> void:
	init_flashlight_off()


func _process(delta: float) -> void:
	
	_handle_flashlight_toggle()
	_update_flashlight_direction()
	_drain_battery(delta)
	if is_invincible:
		invincible_timer -= delta

		if invincible_timer <= 0.0:
			end_invincible()


func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	direction = direction.normalized()

	velocity = direction * SPEED
	move_and_slide()
	update_animation(direction)
	_update_footstep_sound(delta)

func _update_footstep_sound(delta: float) -> void:
	var is_moving := velocity.length() > 10.0

	if is_moving:
		footstep_timer -= delta

		if footstep_timer <= 0.0:
			play_footstep()
			footstep_timer = footstep_interval
	else:
		footstep_timer = 0.0
		
func play_footstep() -> void:
	if footstep_player == null:
		return

	footstep_player.pitch_scale = randf_range(0.9, 1.1)
	footstep_player.play()

# ── F키로 켜고 끄기 ───────────────────────────────────────

func _handle_flashlight_toggle() -> void:
	if Input.is_action_just_pressed("flashlight"):
		if flashlight_on:
			turn_off_flashlight()
		else:
			if battery > 1.0:
				turn_on_flashlight()


func turn_on_flashlight() -> void:
	flashlight_on = true
	play_flashlight_toggle_sound(true)

	spot_light.show()

	# 중요: 손전등 충돌 감지도 켜기
	flashlight_area.visible = true
	flashlight_area.monitoring = true
	flashlight_area.monitorable = true


func turn_off_flashlight() -> void:
	flashlight_on = false
	play_flashlight_toggle_sound(true)

	spot_light.hide()

	# 중요: 손전등 충돌 감지도 끄기
	flashlight_area.visible = false
	flashlight_area.monitoring = false

func play_flashlight_toggle_sound(is_turning_on: bool) -> void:
	if flashlight_toggle_sound == null:
		return

	flashlight_toggle_sound.stop()

	if is_turning_on:
		flashlight_toggle_sound.pitch_scale = 1.1
	else:
		flashlight_toggle_sound.pitch_scale = 0.9

	flashlight_toggle_sound.play()

func init_flashlight_off() -> void:
	flashlight_on = false

	spot_light.hide()

	flashlight_area.visible = false
	flashlight_area.monitoring = false


# ── 손전등 방향, 마우스를 향함 ──────────────────────────

func _update_flashlight_direction() -> void:
	if not flashlight_on:
		return

	var direction = get_global_mouse_position() - global_position
	spot_light.rotation = direction.angle() + PI


# ── 배터리 소모 ───────────────────────────────────────────

func _drain_battery(delta: float) -> void:
	if not flashlight_on:
		return

	battery = max(0.0, battery - DRAIN_RATE * delta)
	emit_signal("battery_changed", battery)

	if battery <= 0.0:
		turn_off_flashlight()


# ── 애니메이션 ────────────────────────────────────────────

func set_idle_frame(anim_name: String) -> void:
	sprite.play(anim_name)
	sprite.frame = 0
	sprite.stop()


func update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		last_direction = direction

		if abs(direction.x) > abs(direction.y):
			sprite.play("walk_right" if direction.x > 0 else "walk_left")
		else:
			sprite.play("walk_down" if direction.y > 0 else "walk_up")
	else:
		if abs(last_direction.x) > abs(last_direction.y):
			set_idle_frame("walk_right" if last_direction.x > 0 else "walk_left")
		else:
			set_idle_frame("walk_down" if last_direction.y > 0 else "walk_up")
