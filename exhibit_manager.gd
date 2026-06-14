extends Node


# ── 새 설정 ───────────────────────────────────────────────
@export var bird_scene: PackedScene

@export var min_spawn_time: float = 0.0
@export var max_spawn_time: float = 30.0
@export var max_bird_count: int = 3


# ── 주먹도끼 설정 ─────────────────────────────────────────
@export var handaxe_scene: PackedScene
@onready var handaxe_spawn_sound: AudioStreamPlayer2D = $HandaxeSpawnSound
@onready var horseman_spawn_sound: AudioStreamPlayer2D = $HorsemanSpawnSound
@export var horseman_spawn_sound_lead_time: float = 2.0

@export var handaxe_min_time: float = 30.0
@export var handaxe_max_time: float = 60.0

@export var handaxe_clone_time: float = 22.0
@export var min_handaxe_clone_time: float = 10.0

# 주먹도끼 최대 개수
@export var max_handaxe_count: int = 5

# 생성될 때 크기
@export var handaxe_spawn_scale: float = 0.2

# 복제될 때 원본 근처에서 얼마나 떨어질지
@export var handaxe_clone_offset: float = 25.0

# 주먹도끼 직접 지정 스폰 위치
@export var spawn_positions: Array[Vector2] = []


# ── 기마병 설정 ───────────────────────────────────────────
@export var horseman_scene: PackedScene

# 8분 플레이 동안 3~4번 정도 나오도록 설계
# 생성 → 일정 시간 활동 → 사라짐 → 다시 랜덤 시간 뒤 생성
@export var horseman_min_time: float = 70.0
@export var horseman_max_time: float = 120.0

# 생성된 기마병이 유지되는 시간
@export var horseman_active_time: float = 15.0

# 8분 동안 최대 출현 횟수
@export var max_horseman_spawn_count: int = 4

# 생성될 때 크기
@export var horseman_spawn_scale: float = 0.5

# 기마병 직접 지정 스폰 위치
@export var horseman_spawn_positions: Array[Vector2] = []


# ── 상태 변수 ─────────────────────────────────────────────
var game_started: bool = false
var game_ended: bool = false

var caught_bird_count: int = 0

# 5시 이후 주먹도끼 생성/복제 중지용
var handaxe_spawn_stopped: bool = false

# 주먹도끼 생성 예약 중복 방지용
var handaxe_spawn_scheduled: bool = false

# 기마병 생성 예약 중복 방지용
var horseman_spawn_scheduled: bool = false

# 기마병이 현재 존재하는지
var horseman_active: bool = false

# 기마병 총 출현 횟수
var horseman_spawn_count: int = 0


@onready var exhibits_container: Node2D = $Exhibits

@onready var limit_top_left: Node2D = $"../LimitTopLeft"
@onready var limit_bottom_right: Node2D = $"../LimitBottomRight"

@onready var bird_count_label: Label = get_tree().current_scene.get_node_or_null(
	"HUD/BirdIconUI/Label"
)


func _ready() -> void:
	randomize()
	add_to_group("ExhibitManager")

	update_bird_count_ui()


func start_exhibit_logic() -> void:
	if game_started:
		return

	game_started = true
	game_ended = false

	# 게임 재시작 대비 초기화
	horseman_spawn_count = 0
	horseman_active = false
	horseman_spawn_scheduled = false

	_spawn_bird_loop()
	_schedule_handaxe_spawn()
	_schedule_horseman_spawn()


func stop_exhibit_logic() -> void:
	game_started = false
	game_ended = true

	handaxe_spawn_scheduled = false
	horseman_spawn_scheduled = false
	horseman_active = false

	_remove_all_horsemen()



func _spawn_bird_loop() -> void:
	while game_started:
		var wait_time: float = randf_range(min_spawn_time, max_spawn_time)
		await get_tree().create_timer(wait_time).timeout

		if game_ended:
			return

		if not game_started:
			return

		if get_bird_count() < max_bird_count:
			spawn_bird()


func spawn_bird() -> void:
	if not game_started:
		return

	if game_ended:
		return

	if bird_scene == null:
		return

	if get_bird_count() >= max_bird_count:
		return

	var bird: Node2D = bird_scene.instantiate() as Node2D
	exhibits_container.add_child(bird)

	bird.add_to_group("Bird")
	bird.global_position = get_random_position_in_map()

	if bird.has_method("setup_limits"):
		bird.setup_limits(limit_top_left, limit_bottom_right)


func get_bird_count() -> int:
	var count: int = 0

	for child in exhibits_container.get_children():
		if child.is_in_group("Bird"):
			count += 1

	return count


func catch_bird() -> void:
	if game_ended:
		return

	caught_bird_count += 1
	update_bird_count_ui()

	print("잡은 새:", caught_bird_count)


func update_bird_count_ui() -> void:
	if bird_count_label == null:
		print("BirdCountLabel을 찾지 못함")
		return

	bird_count_label.text = str(caught_bird_count) + "/20"


func _schedule_handaxe_spawn() -> void:
	if not game_started:
		return

	if game_ended:
		return

	if handaxe_spawn_stopped:
		return

	if handaxe_spawn_scheduled:
		return

	if not is_inside_tree():
		return

	# 이미 주먹도끼가 있으면 생성기 작동 안 함
	if get_handaxe_count() > 0:
		return

	var tree := get_tree()
	if tree == null:
		return

	handaxe_spawn_scheduled = true

	var wait_time: float = randf_range(handaxe_min_time, handaxe_max_time)
	await tree.create_timer(wait_time).timeout

	handaxe_spawn_scheduled = false

	if not game_started:
		return

	if game_ended:
		return

	if handaxe_spawn_stopped:
		return

	if not is_inside_tree():
		return

	# 기다리는 동안 주먹도끼가 생겼으면 생성하지 않음
	if get_handaxe_count() > 0:
		return

	spawn_handaxe(Vector2.INF, false)


func spawn_handaxe(spawn_position: Vector2 = Vector2.INF, is_clone: bool = false) -> void:
	if not game_started:
		return

	if game_ended:
		return

	if handaxe_scene == null:
		return

	# 5시 이후에는 일반 생성과 복제 둘 다 막음
	if handaxe_spawn_stopped:
		return

	if get_handaxe_count() >= max_handaxe_count:
		return
	if not is_clone and get_handaxe_count() > 0:
		return

	var handaxe: Node2D = handaxe_scene.instantiate() as Node2D
	exhibits_container.add_child(handaxe)

	handaxe.add_to_group("HandAxe")
	handaxe.scale = Vector2.ONE * handaxe_spawn_scale

	if spawn_position == Vector2.INF:
		handaxe.global_position = get_handaxe_spawn_position()
	else:
		handaxe.global_position = clamp_position_in_map(spawn_position)
		
	play_handaxe_spawn_sound(handaxe.global_position)

	_start_handaxe_clone_timer(handaxe)

func play_handaxe_spawn_sound(sound_position: Vector2) -> void:
	if handaxe_spawn_sound == null:
		return

	handaxe_spawn_sound.global_position = sound_position
	handaxe_spawn_sound.stop()
	handaxe_spawn_sound.pitch_scale = randf_range(0.9, 1.1)
	handaxe_spawn_sound.play()
# handaxe.gd의 remove_handaxe()에서 호출
func notify_handaxe_removed() -> void:
	if game_ended:
		return

	if handaxe_spawn_stopped:
		return

	if not is_inside_tree():
		return

	await get_tree().process_frame

	if game_ended:
		return

	if handaxe_spawn_stopped:
		return

	if not is_inside_tree():
		return

	# 아직 주먹도끼가 남아 있으면 생성기 작동 안 함
	if get_handaxe_count() > 0:
		return

	# 모든 주먹도끼가 사라졌을 때만 다시 랜덤 생성 예약
	_schedule_handaxe_spawn()


func _start_handaxe_clone_timer(handaxe: Node2D) -> void:
	if not game_started:
		return

	if game_ended:
		return

	if not is_inside_tree():
		return

	var tree := get_tree()
	if tree == null:
		return

	var wait_time: float = max(handaxe_clone_time, min_handaxe_clone_time)
	await tree.create_timer(wait_time).timeout

	if not game_started:
		return

	if game_ended:
		return

	if handaxe_spawn_stopped:
		return

	if not is_inside_tree():
		return

	# 이미 손전등으로 삭제된 주먹도끼면 복제하지 않음
	if not is_instance_valid(handaxe):
		return

	if get_handaxe_count() >= max_handaxe_count:
		return

	var random_dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
	var random_dist: float = randf_range(12.0, handaxe_clone_offset)
	var clone_position: Vector2 = handaxe.global_position + random_dir * random_dist

	spawn_handaxe(clone_position, true)


func get_handaxe_count() -> int:
	var count: int = 0

	for child in exhibits_container.get_children():
		if child.is_in_group("HandAxe"):
			if "is_removed" in child and child.is_removed:
				continue

			count += 1

	return count


func get_handaxe_spawn_position() -> Vector2:
	if spawn_positions.size() > 0:
		return spawn_positions[randi() % spawn_positions.size()]

	return get_random_position_in_map()


func _schedule_horseman_spawn() -> void:
	
	if not game_started:
		return

	if game_ended:
		return

	if horseman_spawn_scheduled:
		return

	if horseman_active:
		return

	if horseman_spawn_count >= max_horseman_spawn_count:
		return

	if not is_inside_tree():
		return

	var tree := get_tree()
	if tree == null:
		return

	horseman_spawn_scheduled = true

	var wait_time: float = randf_range(horseman_min_time, horseman_max_time)
	await tree.create_timer(wait_time).timeout
	
	play_horseman_spawn_sound()

	await tree.create_timer(horseman_spawn_sound_lead_time).timeout
	horseman_spawn_scheduled = false

	if not game_started:
		return

	if game_ended:
		return

	if horseman_active:
		return

	if horseman_spawn_count >= max_horseman_spawn_count:
		return

	if not is_inside_tree():
		return

	spawn_horseman()


func spawn_horseman() -> void:
	if not game_started:
		return

	if game_ended:
		return

	if horseman_scene == null:
		return

	if horseman_active:
		return

	if get_horseman_count() > 0:
		horseman_active = true
		return

	if horseman_spawn_count >= max_horseman_spawn_count:
		return

	var horseman: Node2D = horseman_scene.instantiate() as Node2D
	exhibits_container.add_child(horseman)

	horseman.add_to_group("Horseman")
	horseman.scale = Vector2.ONE * horseman_spawn_scale
	horseman.global_position = get_horseman_spawn_position()

	horseman_active = true
	horseman_spawn_count += 1

	print("기마병 생성:", horseman_spawn_count, "/", max_horseman_spawn_count)

	_start_horseman_lifetime_timer(horseman)
	
func play_horseman_spawn_sound() -> void:
	if horseman_spawn_sound == null:
		return

	horseman_spawn_sound.stop()
	horseman_spawn_sound.pitch_scale = randf_range(0.95, 1.05)
	horseman_spawn_sound.play()


func _start_horseman_lifetime_timer(horseman: Node2D) -> void:
	if not game_started:
		return

	if game_ended:
		return

	if not is_inside_tree():
		return

	var tree := get_tree()
	if tree == null:
		return

	await tree.create_timer(horseman_active_time).timeout

	if not is_inside_tree():
		return

	if game_ended:
		return

	# 이미 다른 이유로 사라졌다면 상태만 갱신
	if not is_instance_valid(horseman):
		_on_horseman_removed()
		return

	if horseman.has_method("disappear"):
		horseman.disappear()
	else:
		horseman.queue_free()

	await get_tree().process_frame

	_on_horseman_removed()


func _on_horseman_removed() -> void:
	horseman_active = false

	if not game_started:
		return

	if game_ended:
		return

	if horseman_spawn_count >= max_horseman_spawn_count:
		return

	_schedule_horseman_spawn()


# horseman.gd에서 기마병이 직접 사라질 때 호출 가능
func notify_horseman_removed() -> void:
	if game_ended:
		return

	if not is_inside_tree():
		return

	await get_tree().process_frame

	_on_horseman_removed()


func get_horseman_count() -> int:
	var count: int = 0

	for child in exhibits_container.get_children():
		if child.is_in_group("Horseman"):
			count += 1

	return count


func get_horseman_spawn_position() -> Vector2:
	# 지정 좌표가 있으면 그 좌표 중 하나를 랜덤 선택
	if horseman_spawn_positions.size() > 0:
		return horseman_spawn_positions[randi() % horseman_spawn_positions.size()]

	# 지정 좌표가 없으면 맵 안 랜덤 위치
	return get_random_position_in_map()


func _remove_all_horsemen() -> void:
	for child in exhibits_container.get_children():
		if child.is_in_group("Horseman"):
			child.queue_free()


func get_random_position_in_map() -> Vector2:
	var min_x: float = limit_top_left.global_position.x
	var min_y: float = limit_top_left.global_position.y
	var max_x: float = limit_bottom_right.global_position.x
	var max_y: float = limit_bottom_right.global_position.y

	var margin: float = 60.0

	return Vector2(
		randf_range(min_x + margin, max_x - margin),
		randf_range(min_y + margin, max_y - margin)
	)


func clamp_position_in_map(pos: Vector2) -> Vector2:
	var min_x: float = limit_top_left.global_position.x
	var min_y: float = limit_top_left.global_position.y
	var max_x: float = limit_bottom_right.global_position.x
	var max_y: float = limit_bottom_right.global_position.y

	var margin: float = 60.0

	return Vector2(
		clamp(pos.x, min_x + margin, max_x - margin),
		clamp(pos.y, min_y + margin, max_y - margin)
	)


func game_over_by_bell() -> void:
	request_game_over("bell")


func game_over_by_handaxe() -> void:
	request_game_over("handaxe")


func game_over_by_horseman() -> void:
	request_game_over("horseman")


func request_game_over(reason_type: String) -> void:
	if game_ended:
		return

	game_ended = true
	game_started = false

	var main := get_tree().current_scene

	if main == null:
		return

	match reason_type:
		"bell":
			if main.has_method("game_over_by_bell"):
				main.game_over_by_bell()

		"handaxe":
			if main.has_method("game_over_by_handaxe"):
				main.game_over_by_handaxe()

		"horseman":
			if main.has_method("game_over_by_horseman"):
				main.game_over_by_horseman()

		_:
			if main.has_method("game_over"):
				main.game_over("알 수 없는 이유로 근무를 계속할 수 없습니다.")



func on_work_time_finished() -> void:
	if game_ended:
		return

	var main := get_tree().current_scene

	if main == null:
		return

	game_ended = true
	game_started = false

	if caught_bird_count < 20:
		if main.has_method("game_over_by_bird_count"):
			main.game_over_by_bird_count()
		return

	if get_handaxe_count() > 0:
		if main.has_method("game_over_by_handaxe_remaining"):
			main.game_over_by_handaxe_remaining()
		return

	var patrol_event := get_tree().get_first_node_in_group("PatrolEvent")

	if patrol_event != null and patrol_event.has_method("is_patrol_success_enough"):
		if not patrol_event.is_patrol_success_enough():
			if main.has_method("game_over_by_patrol"):
				main.game_over_by_patrol()
			else:
				main.game_over("06:00까지 버텼지만 순찰근무를 충분히 완료하지 못했습니다.")
			return

	if main.has_method("game_clear"):
		main.game_clear()


func stop_handaxe_spawning() -> void:
	handaxe_spawn_stopped = true
	handaxe_spawn_scheduled = false
	print("주먹도끼 생성/복제 중지")
