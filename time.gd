extends Control

@onready var time_label = $Label

var hour = 22
var minute = 0
var second = 0.0

var time_speed = 60
var game_ended: bool = false
var time_started: bool = false
var handaxe_spawn_stopped_called: bool = false


func _ready() -> void:
	update_time_label()


func _process(delta: float) -> void:
	if not time_started:
		return

	if game_ended:
		return

	update_time(delta)
	update_time_label()


func start_time() -> void:
	time_started = true


func stop_time() -> void:
	time_started = false


func update_time(delta: float) -> void:
	second += delta * time_speed

	if second >= 60:
		second -= 60
		minute += 1

	if minute >= 60:
		minute -= 60
		hour += 1

	if hour >= 24:
		hour = 0

	if hour == 5 and minute == 0 and not handaxe_spawn_stopped_called:
		handaxe_spawn_stopped_called = true
		stop_handaxe_spawn()

	if hour == 6 and minute == 0:
		game_ended = true
		set_process(false)
		call_work_time_finished()


func update_time_label() -> void:
	time_label.text = "%02d:%02d" % [hour, minute]


func stop_handaxe_spawn() -> void:
	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	if manager != null and manager.has_method("stop_handaxe_spawning"):
		manager.stop_handaxe_spawning()


func call_work_time_finished() -> void:
	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	if manager != null and manager.has_method("on_work_time_finished"):
		manager.on_work_time_finished()
