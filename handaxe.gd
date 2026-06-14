extends CharacterBody2D


@export var move_speed: float = 220.0

@export var min_rest_time: float = 0.5
@export var max_rest_time: float = 2.0

@export var min_move_time: float = 0.8
@export var max_move_time: float = 1.8

@export var jump_height: float = 80.0
@export var jump_duration: float = 0.3
@export var hop_forward_offset: float = 10.0

@export var required_light_time: float = 5.0

# 벽에 연속으로 부딪힐 때 떨림 방지용
@export var collision_cooldown_time: float = 0.18

enum State { MOVING, RESTING }

var state: State = State.RESTING
var timer: float = 0.0
var duration: float = 0.0
var move_dir: Vector2 = Vector2.ZERO
var jump_t: float = 0.0

var light_time: float = 0.0
var is_removed: bool = false
var collision_cooldown: float = 0.0

var progress_bar_base_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var light_progress_bar: ProgressBar = $LightProgressBar
@onready var light_detect_area: Area2D = $LightDetectArea
@onready var bounce_sound: AudioStreamPlayer2D = $BounceSound
@onready var remove_sound: AudioStreamPlayer2D = $RemoveSound

func play_bounce_sound() -> void:
	if bounce_sound == null:
		return

	bounce_sound.stop()
	bounce_sound.pitch_scale = randf_range(0.85, 1.15)
	bounce_sound.play()

func _ready() -> void:
	randomize()

	progress_bar_base_position = light_progress_bar.position

	light_progress_bar.min_value = 0
	light_progress_bar.max_value = required_light_time
	light_progress_bar.value = 0
	light_progress_bar.visible = false

	light_detect_area.monitoring = true
	light_detect_area.monitorable = true

	# 벽 충돌용 CollisionShape2D는 항상 바닥 위치에 고정
	collision_shape.position = Vector2.ZERO

	_start_random_direction()
	_start_moving()


func _physics_process(delta: float) -> void:
	if is_removed:
		return

	collision_cooldown = max(0.0, collision_cooldown - delta)

	_update_light_progress(delta)

	timer += delta

	match state:
		State.MOVING:
			_process_moving(delta)
		State.RESTING:
			_process_resting(delta)


func _process_moving(delta: float) -> void:
	velocity = move_dir * move_speed
	move_and_slide()

	_handle_collisions()

	_update_jump_motion(delta)

	if timer >= duration:
		_start_resting()


func _handle_collisions() -> void:
	if get_slide_collision_count() <= 0:
		return

	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()

		if collider != null and collider is Node2D:
			var collider_node := collider as Node2D

			if collider_node.is_in_group("Player"):
				# 문 통과 직후 무적 상태면 게임오버 무시
				if collider_node.has_method("can_be_hit"):
					if not collider_node.can_be_hit():
						return

				game_over_by_handaxe()
				return

	# 벽 튕김은 쿨다운이 끝났을 때만 처리
	if collision_cooldown > 0.0:
		return

	var first_collision: KinematicCollision2D = get_slide_collision(0)
	var normal: Vector2 = first_collision.get_normal()

	global_position += normal * 4.0

	move_dir = move_dir.bounce(normal).normalized()
	move_dir = move_dir.rotated(randf_range(-0.25, 0.25)).normalized()

	play_bounce_sound()
	collision_cooldown = collision_cooldown_time


func _update_jump_motion(delta: float) -> void:
	jump_t += delta

	if jump_t > jump_duration:
		jump_t -= jump_duration

	var t: float = jump_t / jump_duration

	# 0 → 1 → 0 형태의 포물선
	var height_arc: float = 4.0 * t * (1.0 - t)

	# 떨어질 때 약간 더 묵직하게 보이게 보정
	if t > 0.5:
		height_arc = pow(height_arc, 0.75)

	var jump_y: float = -jump_height * height_arc

	# 이동 방향으로 살짝 앞으로 나가는 연출
	var forward_arc: float = sin(t * PI)
	var forward_offset: Vector2 = move_dir.normalized() * hop_forward_offset * forward_arc

	var jump_offset: Vector2 = forward_offset + Vector2(0, jump_y)

	_apply_offset(jump_offset)


func _process_resting(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	_apply_offset(Vector2.ZERO)

	if timer >= duration:
		_start_moving()


func _apply_offset(offset: Vector2) -> void:
	# 보이는 이미지만 점프
	sprite.position = offset

	# 실제 벽 충돌용 CollisionShape2D는 고정
	collision_shape.position = Vector2.ZERO

	# 손전등 감지 범위와 진행도 바는 이미지 위치를 따라감
	light_detect_area.position = offset
	light_progress_bar.position = progress_bar_base_position + offset


func _start_random_direction() -> void:
	var angle: float = randf() * TAU
	move_dir = Vector2(cos(angle), sin(angle)).normalized()


func _start_moving() -> void:
	state = State.MOVING
	timer = 0.0
	jump_t = 0.0
	duration = randf_range(min_move_time, max_move_time)

	_start_random_direction()


func _start_resting() -> void:
	state = State.RESTING
	timer = 0.0
	duration = randf_range(min_rest_time, max_rest_time)
	velocity = Vector2.ZERO

	_apply_offset(Vector2.ZERO)


func _update_light_progress(delta: float) -> void:
	var flashlight_detected: bool = false

	for area in light_detect_area.get_overlapping_areas():
		if area.is_in_group("Flashlight") and area.monitoring and area.visible:
			flashlight_detected = true
			break

	if flashlight_detected:
		light_time += delta

		if light_time > required_light_time:
			light_time = required_light_time

		light_progress_bar.visible = true
		light_progress_bar.value = light_time

		if light_time >= required_light_time:
			remove_handaxe()
	else:
		light_progress_bar.visible = light_time > 0.0
		light_progress_bar.value = light_time


func remove_handaxe() -> void:
	if is_removed:
		return

	is_removed = true

	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	# 사라지는 소리 재생
	if remove_sound != null:
		remove_sound.pitch_scale = randf_range(0.9, 1.1)
		remove_sound.play()

	# 화면에서는 바로 사라진 것처럼 보이게 처리
	sprite.hide()
	light_progress_bar.hide()
	light_detect_area.monitoring = false
	light_detect_area.monitorable = false
	collision_shape.set_deferred("disabled", true)

	# 소리가 너무 길어도 게임 흐름이 늦어지지 않게 0.4초만 대기
	await get_tree().create_timer(0.4).timeout

	queue_free()

	# 주먹도끼가 실제 삭제 예약된 뒤 ExhibitManager에게 알림
	if manager != null and manager.has_method("notify_handaxe_removed"):
		manager.call_deferred("notify_handaxe_removed")



func game_over_by_handaxe() -> void:
	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	if manager != null and manager.has_method("game_over_by_handaxe"):
		manager.game_over_by_handaxe()
