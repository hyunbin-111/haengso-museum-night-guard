extends Control

@onready var panel: Panel = $Panel
@onready var resume_button: Button = $Panel/ResumeButton
@onready var quit_button: Button = $Panel/QuitButton
@onready var controls_label: Label = $ControlsLabel

var is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	hide()

	resume_button.pressed.connect(_on_resume_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()


func toggle_pause_menu() -> void:
	var main := get_tree().current_scene

	if main != null and "game_ended" in main and main.game_ended:
		return

	if is_open:
		close_pause_menu()
	else:
		open_pause_menu()


func open_pause_menu() -> void:
	is_open = true
	show()
	get_tree().paused = true


func close_pause_menu() -> void:
	is_open = false
	hide()
	get_tree().paused = false


func _on_resume_button_pressed() -> void:
	close_pause_menu()


func _on_quit_button_pressed() -> void:
	# 중요: 시작 메뉴로 돌아가기 전에 pause를 반드시 해제해야 함
	get_tree().paused = false

	# 네 StartMenu.tscn 실제 경로에 맞게 수정
	get_tree().change_scene_to_file("res://start_menu.tscn")
