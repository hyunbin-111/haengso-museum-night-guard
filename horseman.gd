extends CharacterBody2D

@export var move_speed: float = 180.0
@export var dash_speed: float = 380.0

@export var chase_time: float = 2.0
@export var dash_time: float = 0.9
@export var rest_time: float = 0.8

@export var hit_distance: float = 45.0

@export var normal_anim_speed: float = 1.0
@export var dash_anim_speed: float = 2.5

enum State { CHASING, DASHING, RESTING }

var state: State = State.CHASING
var timer: float = 0.0

var player_ref: Node2D = null
var dash_dir: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var run_sound: AudioStreamPlayer2D = $RunSound
@onready var disappear_sound: AudioStreamPlayer2D = $DisappearSound

func play_disappear_sound() -> void:
	if disappear_sound == null:
		return

	disappear_sound.stop()
	disappear_sound.pitch_scale = randf_range(0.95, 1.05)
	disappear_sound.play()

func disappear() -> void:
	stop_run_sound()

	play_disappear_sound()

	# 화면에서는 바로 사라진 것처럼 처리
	hide()
	set_physics_process(false)
	set_process(false)

	# 소리가 끝난 뒤 삭제
	if disappear_sound != null:
		await disappear_sound.finished

	queue_free()

func play_run_sound() -> void:
	if run_sound == null:
		return

	if run_sound.playing:
		return

	run_sound.pitch_scale = randf_range(0.95, 1.05)
	run_sound.play()


func stop_run_sound() -> void:
	if run_sound == null:
		return

	if run_sound.playing:
		run_sound.stop()
		
func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("Player")
	_start_chasing()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return

	timer += delta

	match state:
		State.CHASING:
			_process_chasing(delta)

		State.DASHING:
			_process_dashing(delta)

		State.RESTING:
			_process_resting(delta)

	_check_player_hit()


func _process_chasing(delta: float) -> void:
	var direction: Vector2 = global_position.direction_to(player_ref.global_position)

	global_position += direction * move_speed * delta
	_update_animation(direction)

	if timer >= chase_time:
		_start_dashing()


func _process_dashing(delta: float) -> void:
	global_position += dash_dir * dash_speed * delta
	_update_animation(dash_dir)

	if timer >= dash_time:
		_start_resting()


func _process_resting(_delta: float) -> void:
	sprite.stop()

	if timer >= rest_time:
		_start_chasing()


func _start_chasing() -> void:
	state = State.CHASING
	timer = 0.0
	sprite.speed_scale = normal_anim_speed
	play_run_sound()


func _start_dashing() -> void:
	state = State.DASHING
	timer = 0.0
	sprite.speed_scale = dash_anim_speed

	if is_instance_valid(player_ref):
		dash_dir = global_position.direction_to(player_ref.global_position)
	else:
		dash_dir = Vector2.DOWN

	if dash_dir == Vector2.ZERO:
		dash_dir = Vector2.DOWN
	
	play_run_sound()


func _start_resting() -> void:
	state = State.RESTING
	timer = 0.0
	sprite.speed_scale = normal_anim_speed
	
	stop_run_sound()


func _check_player_hit() -> void:
	if not is_instance_valid(player_ref):
		return

	if player_ref.has_method("can_be_hit"):
		if not player_ref.can_be_hit():
			return

	if global_position.distance_to(player_ref.global_position) <= hit_distance:
		game_over_by_horseman()


func game_over_by_horseman() -> void:
	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	if manager != null and manager.has_method("game_over_by_horseman"):
		manager.game_over_by_horseman()
	else:
		print("ExhibitManager에 game_over_by_horseman() 함수가 없음")



func _update_animation(dir: Vector2) -> void:
	if dir.length() < 0.1:
		sprite.stop()
		return

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("right")
		else:
			sprite.play("left")
	else:
		if dir.y > 0:
			sprite.play("down")
		else:
			sprite.play("up")
