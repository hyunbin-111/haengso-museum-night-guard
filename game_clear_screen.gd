extends Control

@onready var clear_label: Label = $ClearLabel
@onready var restart_button: Button = $RestartButton
@onready var startmenu_button: Button = $StartMenuButton
@onready var game_clear_sound: AudioStreamPlayer = $GameClearSound

func play_game_clear_sound() -> void:
	if game_clear_sound == null:
		return

	game_clear_sound.stop()
	game_clear_sound.play()

# Main에 있는 CanvasModulate 경로
@export var canvas_modulate_path: NodePath = NodePath("../../CanvasModulate")

# 다시 시작할 게임 씬
@export var restart_scene_path: String = "res://main.tscn"

# 시작화면 씬
@export var start_menu_scene_path: String = "res://start_menu.tscn"

# 불 켜지는 시간
@export var light_on_duration: float = 2.0

# 메시지 등장 시간
@export var message_fade_duration: float = 0.8

# 불 켜졌을 때 색
@export var light_on_color: Color = Color(1, 1, 1, 1)

var canvas_modulate: CanvasModulate = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	canvas_modulate = get_node_or_null(canvas_modulate_path)

	hide()

	clear_label.modulate.a = 0.0
	restart_button.hide()
	startmenu_button.hide()

	restart_button.pressed.connect(_on_restart_button_pressed)
	startmenu_button.pressed.connect(_on_startmenu_button_pressed)


func show_game_clear() -> void:
	show()
	
	play_game_clear_sound()

	clear_label.text = "근무 완료!\n\n06:00이 되었습니다.\n행소박물관의 밤을 무사히 넘겼습니다."
	clear_label.modulate.a = 0.0

	restart_button.hide()
	startmenu_button.hide()

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# 1. 박물관 불 켜짐
	if canvas_modulate != null:
		tween.tween_property(
			canvas_modulate,
			"color",
			light_on_color,
			light_on_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. 근무 완료 메시지 등장
	tween.tween_property(
		clear_label,
		"modulate:a",
		1.0,
		message_fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 3. 버튼 표시
	tween.tween_callback(show_buttons)


func show_buttons() -> void:
	restart_button.show()
	startmenu_button.show()


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(restart_scene_path)


func _on_startmenu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(start_menu_scene_path)
