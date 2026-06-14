extends Node2D


signal patrol_completed
signal patrol_failed

@export var patrol_limit_time: float = 40.0

var event_active: bool = false
var time_left: float = 0.0

var visited_count: int = 0
var visited_checkpoints: Array[Area2D] = []

var glow_tween: Tween = null

@onready var path_core_line: Line2D = $PathCoreLine
@onready var path_lights: Node2D = $PathLights
@onready var checkpoints_parent: Node2D = $Checkpoints

var checkpoints: Array[Area2D] = []


func _ready() -> void:
	setup_checkpoints()
	turn_off_patrol_path()


func _process(delta: float) -> void:
	if not event_active:
		return

	time_left -= delta

	if time_left <= 0.0:
		fail_patrol()


func start_patrol() -> void:
	if event_active:
		return

	if checkpoints.is_empty():
		print(name, " 체크포인트가 없음")
		return

	event_active = true
	time_left = patrol_limit_time

	visited_count = 0
	visited_checkpoints.clear()

	turn_on_patrol_path()
	activate_all_checkpoints()

	print(name, " 순찰 시작")


func stop_patrol() -> void:
	event_active = false
	turn_off_patrol_path()


func get_time_left() -> float:
	if not event_active:
		return 0.0

	return time_left


# ============================================================
# 체크포인트 자동 등록
# ============================================================

func setup_checkpoints() -> void:
	checkpoints.clear()

	for child in checkpoints_parent.get_children():
		if child is Area2D:
			checkpoints.append(child)

	checkpoints.sort_custom(_sort_checkpoints_by_number)

	for checkpoint in checkpoints:
		if not checkpoint.body_entered.is_connected(_on_checkpoint_body_entered):
			checkpoint.body_entered.connect(
				_on_checkpoint_body_entered.bind(checkpoint)
			)

		checkpoint.visible = false
		checkpoint.set_deferred("monitoring", false)
		checkpoint.monitorable = true


func _sort_checkpoints_by_number(a: Area2D, b: Area2D) -> bool:
	return get_checkpoint_number(a.name) < get_checkpoint_number(b.name)


func get_checkpoint_number(checkpoint_name: String) -> int:
	var number_text: String = ""

	for i in range(checkpoint_name.length()):
		var ch: String = checkpoint_name[i]

		if ch >= "0" and ch <= "9":
			number_text += ch

	if number_text == "":
		return 0

	return int(number_text)


# ============================================================
# 길 / 빛 켜기 끄기
# ============================================================

func turn_on_patrol_path() -> void:
	if path_core_line != null:
		path_core_line.show()

	for light in path_lights.get_children():
		if light is PointLight2D:
			light.enabled = true
			light.visible = true

	for checkpoint in checkpoints:
		checkpoint.visible = true
		checkpoint.set_deferred("monitoring", true)

	start_light_blink()


func turn_off_patrol_path() -> void:
	if path_core_line != null:
		path_core_line.hide()

	if glow_tween != null:
		glow_tween.kill()
		glow_tween = null

	for light in path_lights.get_children():
		if light is PointLight2D:
			light.enabled = false
			light.visible = false

	for checkpoint in checkpoints:
		checkpoint.visible = false
		checkpoint.set_deferred("monitoring", false)


func start_light_blink() -> void:
	if glow_tween != null:
		glow_tween.kill()

	glow_tween = create_tween()
	glow_tween.set_loops()

	for light in path_lights.get_children():
		if light is PointLight2D:
			light.energy = 0.8

			glow_tween.parallel().tween_property(
				light,
				"energy",
				0.25,
				0.8
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	glow_tween.tween_interval(0.05)

	for light in path_lights.get_children():
		if light is PointLight2D:
			glow_tween.parallel().tween_property(
				light,
				"energy",
				1.0,
				0.8
			).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ============================================================
# 체크포인트 처리
# 순서 상관없이 전부 밟으면 완료
# ============================================================

func activate_all_checkpoints() -> void:
	for checkpoint in checkpoints:
		checkpoint.visible = true
		checkpoint.set_deferred("monitoring", true)

	print(name, " 체크포인트 전체 활성화:", checkpoints.size())


func _on_checkpoint_body_entered(body: Node2D, checkpoint: Area2D) -> void:
	if not event_active:
		return

	if not body.is_in_group("Player"):
		return

	if visited_checkpoints.has(checkpoint):
		return

	visited_checkpoints.append(checkpoint)
	visited_count += 1

	print(name, " 체크포인트 통과:", checkpoint.name, " ", visited_count, "/", checkpoints.size())

	# 이미 밟은 체크포인트는 꺼서 중복 판정 방지
	checkpoint.set_deferred("monitoring", false)
	checkpoint.hide()

	if visited_count >= checkpoints.size():
		complete_patrol()


# ============================================================
# 성공 / 실패
# ============================================================

func complete_patrol() -> void:
	if not event_active:
		return

	event_active = false
	turn_off_patrol_path()

	print(name, " 순찰 완료")
	emit_signal("patrol_completed")


func fail_patrol() -> void:
	if not event_active:
		return

	event_active = false
	turn_off_patrol_path()

	print(name, " 순찰 실패")
	emit_signal("patrol_failed")
