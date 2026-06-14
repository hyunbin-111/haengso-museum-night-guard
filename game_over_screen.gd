extends Control

@onready var fade_rect: ColorRect = $ColorRect
@onready var reason_label: Label = $ReasonLabel
@onready var restart_button: Button = $RestartButton
@onready var startmenu_button: Button = $StartMenuButton
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound

@export var fade_duration: float = 1.0
@export var text_delay: float = 0.3
@export var text_fade_duration: float = 0.8

# 다시하기용 Main 씬
@export var restart_scene_path: String = "res://main.tscn"

# 시작메뉴용 씬
@export var start_menu_scene_path: String = "res://Start_Menu.tscn"

func play_game_over_sound() -> void:
	if game_over_sound == null:
		return

	game_over_sound.stop()
	game_over_sound.play()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	hide()

	fade_rect.color = Color(0, 0, 0, 0)
	reason_label.modulate.a = 0.0
	reason_label.text = ""

	restart_button.hide()
	startmenu_button.hide()

	restart_button.pressed.connect(_on_restart_button_pressed)
	startmenu_button.pressed.connect(_on_startmenu_button_pressed)


func show_game_over(reason: String) -> void:
	show()
	
	play_game_over_sound()

	fade_rect.color = Color(0, 0, 0, 0)
	reason_label.modulate.a = 0.0
	reason_label.text = reason

	restart_button.hide()
	startmenu_button.hide()

	var tween := create_tween()

	tween.tween_property(
		fade_rect,
		"color:a",
		1.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(text_delay)

	tween.tween_property(
		reason_label,
		"modulate:a",
		1.0,
		text_fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
