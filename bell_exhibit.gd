extends Node2D

@export var max_time: float = 80
@export var min_time: float = 45

@export var wave_repeat_count: int = 3
@export var wave_repeat_interval: float = 0.2

@export var start_scale: float = 0.3
@export var end_scale: float = 1.8
@export var wave_duration: float = 1.0

@export var camera_shake_strength: float = 8.0
@export var camera_shake_duration: float = 0.25

var current_time: float = 0.0
var player_near: bool = false
var is_ringing: bool = false

@onready var sound_effect: Node2D = $SoundEffect
@onready var time_label: Label = $Label
@onready var interact_area: Area2D = $InteractArea
@onready var bell_ring_sound: AudioStreamPlayer2D = $BellRingSound
@onready var bell_reset_sound: AudioStreamPlayer2D = $BellResetSound

@export var max_ring_count: int = 3

var ring_count: int = 0


func _ready() -> void:
	randomize()

	current_time = max_time

	sound_effect.visible = false


	_update_label()


func _process(delta: float) -> void:
	if is_ringing:
		return

	current_time -= delta

	if current_time <= 0.0:
		current_time = 0.0
		_update_label()
		ring()
		return

	if player_near and Input.is_action_just_pressed("interact"):
		reset_bell_timer()
		play_bell_reset_sound()

	_update_label()


func reset_bell_timer() -> void:
	var reduce_time: float = randf_range(3.0, 5.0)

	# E키로 진정시킬 때마다 다음 제한시간이 3~5초씩 감소
	max_time -= reduce_time

	# 너무 짧아지는 것을 방지
	if max_time < min_time:
		max_time = min_time

	# 줄어든 제한시간으로 다시 초기화
	current_time = max_time
	_update_label()


func ring() -> void:
	if is_ringing:
		return

	is_ringing = true
	ring_count += 1
	play_bell_ring_sound()

	print("종 울림 횟수: ", ring_count)

	shake_camera()

	for i in range(wave_repeat_count):
		_spawn_wave()
		await get_tree().create_timer(wave_repeat_interval).timeout

	if ring_count >= max_ring_count:
		notify_game_over()
		return

	# 종이 울린 뒤 다시 현재 max_time으로 타이머 시작
	current_time = max_time
	is_ringing = false
	_update_label()

func play_bell_ring_sound() -> void:
	if bell_ring_sound == null:
		return

	bell_ring_sound.stop()
	bell_ring_sound.pitch_scale = randf_range(0.95, 1.05)
	bell_ring_sound.play()
	
func play_bell_reset_sound() -> void:
	if bell_reset_sound == null:
		return

	bell_reset_sound.stop()
	bell_reset_sound.pitch_scale = randf_range(0.95, 1.05)
	bell_reset_sound.play()

func _spawn_wave() -> void:
	var wave: Node2D = sound_effect.duplicate() as Node2D
	get_tree().current_scene.add_child(wave)

	wave.visible = true
	wave.global_position = sound_effect.global_position
	wave.scale = Vector2.ONE * start_scale
	wave.modulate.a = 1.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		wave,
		"scale",
		Vector2.ONE * end_scale,
		wave_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		wave,
		"modulate:a",
		0.0,
		wave_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.finished.connect(wave.queue_free)


func _update_label() -> void:
	var time_left: int = ceil(current_time)

	if player_near:
		time_label.text = "종 울림까지: " + str(time_left) + "\n울림 횟수: " + str(ring_count) + " / " + str(max_ring_count) + "\n[E] 진정시키기"
	else:
		time_label.text = "종 울림까지: " + str(time_left) + "\n울림 횟수: " + str(ring_count) + " / " + str(max_ring_count)


func shake_camera() -> void:
	var player := get_tree().get_first_node_in_group("Player")

	if player == null:
		return

	var camera := player.get_node_or_null("Camera2D")

	if camera == null:
		return

	if camera.has_method("shake"):
		camera.shake(camera_shake_strength, camera_shake_duration)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_near = true
		_update_label()


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_near = false
		_update_label()
		
func notify_game_over() -> void:
	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	if manager == null:
		print("ExhibitManager 그룹을 찾지 못함")
		return

	if manager.has_method("game_over_by_bell"):
		manager.game_over_by_bell()
	else:
		print("ExhibitManager에 game_over_by_bell() 함수가 없음")
