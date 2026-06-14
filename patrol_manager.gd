extends Node



@export var patrol_start_times: Array[float] = [75.0, 165.0, 255.0, 345.0, 420.0]
@export var required_success_count: int = 4

@onready var left_route: Node = $"../MapContainer/museum_left/PatrolRoute_Left"
@onready var right_route: Node = $"../MapContainer/museum_right/PatrolRoute_Right"
@onready var patrol_start_sound: AudioStreamPlayer = $PatrolStartSound
@onready var patrol_complete_sound: AudioStreamPlayer = $PatrolCompleteSound
@onready var patrol_fail_sound: AudioStreamPlayer = $PatrolFailSound

var game_started: bool = false
var game_finished: bool = false

var game_time: float = 0.0
var current_event_index: int = 0

var patrol_event_count: int = 0
var patrol_success_count: int = 0
var patrol_fail_count: int = 0

var event_active: bool = false
var event_failed: bool = false

var left_completed: bool = false
var right_completed: bool = false

func play_patrol_start_sound() -> void:
	if patrol_start_sound == null:
		return

	patrol_start_sound.stop()
	patrol_start_sound.pitch_scale = randf_range(0.95, 1.05)
	patrol_start_sound.play()


func play_patrol_complete_sound() -> void:
	if patrol_complete_sound == null:
		return

	patrol_complete_sound.stop()
	patrol_complete_sound.pitch_scale = randf_range(0.95, 1.05)
	patrol_complete_sound.play()
	
func play_patrol_fail_sound() -> void:
	if patrol_fail_sound == null:
		return

	patrol_fail_sound.stop()
	patrol_fail_sound.pitch_scale = randf_range(0.95, 1.05)
	patrol_fail_sound.play()
	
func _ready() -> void:
	add_to_group("PatrolEvent")

	if left_route == null:
		return

	if right_route == null:
		return

	if left_route.has_signal("patrol_completed"):
		left_route.connect("patrol_completed", _on_left_patrol_completed)

	if left_route.has_signal("patrol_failed"):
		left_route.connect("patrol_failed", _on_left_patrol_failed)

	if right_route.has_signal("patrol_completed"):
		right_route.connect("patrol_completed", _on_right_patrol_completed)

	if right_route.has_signal("patrol_failed"):
		right_route.connect("patrol_failed", _on_right_patrol_failed)

	if left_route.has_method("stop_patrol"):
		left_route.stop_patrol()

	if right_route.has_method("stop_patrol"):
		right_route.stop_patrol()


func start_patrol_logic() -> void:
	game_started = true
	game_finished = false

	game_time = 0.0
	current_event_index = 0

	patrol_event_count = 0
	patrol_success_count = 0
	patrol_fail_count = 0

	event_active = false
	event_failed = false

	left_completed = false
	right_completed = false

	if left_route != null and left_route.has_method("stop_patrol"):
		left_route.stop_patrol()

	if right_route != null and right_route.has_method("stop_patrol"):
		right_route.stop_patrol()

	hide_patrol_notice()
	update_patrol_progress_ui()


func stop_patrol_logic() -> void:
	game_started = false
	game_finished = true
	event_active = false
	event_failed = false

	if left_route != null and left_route.has_method("stop_patrol"):
		left_route.stop_patrol()

	if right_route != null and right_route.has_method("stop_patrol"):
		right_route.stop_patrol()

	hide_patrol_notice()
	hide_patrol_message_ui()
	
func hide_patrol_message_ui() -> void:
	var message_ui := get_tree().current_scene.get_node_or_null("HUD/PatrolMessageUI")

	if message_ui != null:
		if message_ui.has_method("hide_all"):
			message_ui.hide_all()
		else:
			message_ui.hide()


func _process(delta: float) -> void:
	if not game_started:
		return

	if game_finished:
		return

	game_time += delta

	if event_active:
		update_active_patrol_notice()
		return

	check_event_start_time()


func check_event_start_time() -> void:
	if current_event_index >= patrol_start_times.size():
		return

	var next_time: float = patrol_start_times[current_event_index]

	if game_time >= next_time:
		start_next_patrol_event()


func start_next_patrol_event() -> void:
	if left_route == null or right_route == null:
		return

	event_active = true
	event_failed = false

	left_completed = false
	right_completed = false

	patrol_event_count += 1
	current_event_index += 1
	
	play_patrol_start_sound()

	if left_route.has_method("start_patrol"):
		left_route.start_patrol()

	if right_route.has_method("start_patrol"):
		right_route.start_patrol()

	update_patrol_progress_ui()

	show_patrol_notice(
		"순찰근무 진행 중\n"
		+ "1전시실과 2전시실을 모두 순찰하십시오.\n"
		+ "남은 시간: " + str(get_current_time_left()) + "초"
	)

	print("순찰 이벤트 시작: ", patrol_event_count, "회차")


func update_active_patrol_notice() -> void:
	var need_text: String = ""

	if not left_completed and not right_completed:
		need_text = "1전시실과 2전시실을 모두 순찰하십시오."
	elif left_completed and not right_completed:
		need_text = "1전시실 순찰 완료!\n2전시실도 순찰해주세요."
	elif right_completed and not left_completed:
		need_text = "2전시실 순찰 완료!\n1전시실도 순찰해주세요."
	else:
		need_text = "순찰 완료 처리 중..."

	update_patrol_notice(
		"순찰근무 진행 중\n"
		+ need_text
		+ "\n남은 시간: "
		+ str(get_current_time_left())
		+ "초"
	)


func get_current_time_left() -> int:
	var times: Array[float] = []

	# 1전시실이 아직 완료되지 않았을 때만 시간 계산에 포함
	if not left_completed:
		if left_route != null and left_route.has_method("get_time_left"):
			times.append(left_route.get_time_left())

	# 2전시실이 아직 완료되지 않았을 때만 시간 계산에 포함
	if not right_completed:
		if right_route != null and right_route.has_method("get_time_left"):
			times.append(right_route.get_time_left())

	# 둘 다 완료된 상태면 0초
	if times.is_empty():
		return 0

	# 남아있는 전시실 중 가장 큰 시간을 표시
	return int(ceil(times.max()))


func _on_left_patrol_completed() -> void:
	if not event_active:
		return

	if left_completed:
		return

	left_completed = true
	play_patrol_complete_sound()

	print("1전시실 순찰 완료")

	if right_completed:
		complete_full_patrol_event()
	else:
		update_active_patrol_notice()


func _on_left_patrol_failed() -> void:
	if not event_active:
		return

	if left_completed:
		return
	
	fail_full_patrol_event("1전시실 순찰 시간이 초과되었습니다.")
	play_patrol_fail_sound()


func _on_right_patrol_completed() -> void:
	if not event_active:
		return

	if right_completed:
		return

	right_completed = true
	play_patrol_complete_sound()

	print("2전시실 순찰 완료")

	if left_completed:
		complete_full_patrol_event()
	else:
		update_active_patrol_notice()


func _on_right_patrol_failed() -> void:
	if not event_active:
		return

	if right_completed:
		return

	fail_full_patrol_event("2전시실 순찰 시간이 초과되었습니다.")
	play_patrol_fail_sound()


func complete_full_patrol_event() -> void:
	if not event_active:
		return

	event_active = false
	event_failed = false

	patrol_success_count += 1
	play_patrol_complete_sound()

	if left_route != null and left_route.has_method("stop_patrol"):
		left_route.stop_patrol()

	if right_route != null and right_route.has_method("stop_patrol"):
		right_route.stop_patrol()

	update_patrol_progress_ui()
	hide_patrol_notice()

	show_result_message(
		"순찰근무 완료!\n현재 순찰 성공: "
		+ str(patrol_success_count)
		+ " / "
		+ str(required_success_count),
		3.0
	)

	print("전체 순찰 완료")
	print("순찰 성공:", patrol_success_count, "/", required_success_count)


func fail_full_patrol_event(reason: String) -> void:
	if not event_active:
		return

	if event_failed:
		return

	event_failed = true
	event_active = false

	patrol_fail_count += 1
	play_patrol_fail_sound()

	if left_route != null and left_route.has_method("stop_patrol"):
		left_route.stop_patrol()

	if right_route != null and right_route.has_method("stop_patrol"):
		right_route.stop_patrol()

	update_patrol_progress_ui()
	hide_patrol_notice()

	show_result_message(
		"순찰근무 실패.\n"
		+ reason
		+ "\n06:00까지 "
		+ str(required_success_count)
		+ "회 이상 완료해야 합니다.",
		3.0
	)

	print("전체 순찰 실패:", reason)


func show_patrol_notice(text: String) -> void:
	var message_ui := get_tree().current_scene.get_node_or_null("HUD/PatrolMessageUI")

	if message_ui != null and message_ui.has_method("show_persistent_message"):
		message_ui.show_persistent_message(text)
	else:
		print(text)


func update_patrol_notice(text: String) -> void:
	var message_ui := get_tree().current_scene.get_node_or_null("HUD/PatrolMessageUI")

	if message_ui != null and message_ui.has_method("update_persistent_message"):
		message_ui.update_persistent_message(text)
	else:
		print(text)


func hide_patrol_notice() -> void:
	var message_ui := get_tree().current_scene.get_node_or_null("HUD/PatrolMessageUI")

	if message_ui != null and message_ui.has_method("hide_persistent_message"):
		message_ui.hide_persistent_message()


func show_result_message(text: String, duration: float = 3.0) -> void:
	var message_ui := get_tree().current_scene.get_node_or_null("HUD/PatrolMessageUI")

	if message_ui != null and message_ui.has_method("show_result_message"):
		message_ui.show_result_message(text, duration)
	else:
		print(text)


func update_patrol_progress_ui() -> void:
	var progress_ui := get_tree().current_scene.get_node_or_null("HUD/PatrolProgressUI")

	if progress_ui != null and progress_ui.has_method("update_progress"):
		progress_ui.update_progress(
			patrol_success_count,
			required_success_count,
			patrol_event_count,
			patrol_start_times.size()
		)


func is_patrol_success_enough() -> bool:
	return patrol_success_count >= required_success_count


func get_patrol_result_text() -> String:
	return "순찰 성공 " + str(patrol_success_count) + " / " + str(required_success_count)
