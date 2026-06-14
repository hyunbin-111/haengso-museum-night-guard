extends Node2D


var game_started: bool = false
var game_ended: bool = false

@onready var dialogue_ui: Control = $HUD/DialogueUI
@onready var manual: Control = $HUD/Manual
@onready var time_ui: Control = $HUD/Time
@onready var game_over_screen: Control = $HUD/GameOverScreen
@onready var game_clear_screen: Control = $HUD/GameClearScreen
@onready var patrol_event: Node = get_node_or_null("PatrolManager")

@onready var bird_icon_ui: Control = $HUD/BirdIconUI
@onready var flashlight_ui: Control = $HUD/Flashlight

@onready var exhibit_manager: Node = $ExhibitManager


func _ready() -> void:
	start_intro()


func start_intro() -> void:
	game_started = false
	game_ended = false

	get_tree().paused = true



	dialogue_ui.show()
	manual.hide()
	game_over_screen.hide()
	game_clear_screen.hide()

	bird_icon_ui.hide()
	flashlight_ui.hide()

	if dialogue_ui.has_method("start_dialogue"):
		dialogue_ui.start_dialogue()

	if time_ui.has_method("stop_time"):
		time_ui.stop_time()


func on_dialogue_finished() -> void:
	if dialogue_ui != null:
		dialogue_ui.hide()

	if manual != null:
		manual.show()

		if "is_open" in manual:
			manual.is_open = true


func on_manual_closed() -> void:
	if game_ended:
		return

	if not game_started:
		start_game()
		return


func start_game() -> void:
	if game_started:
		return

	if game_ended:
		return

	game_started = true

	if manual != null:
		manual.hide()

		if "is_open" in manual:
			manual.is_open = false

	if bird_icon_ui != null:
		bird_icon_ui.show()

	if flashlight_ui != null:
		flashlight_ui.show()

	get_tree().paused = false

	if time_ui != null and time_ui.has_method("start_time"):
		time_ui.start_time()

	if exhibit_manager != null and exhibit_manager.has_method("start_exhibit_logic"):
		exhibit_manager.start_exhibit_logic()

	if patrol_event != null and patrol_event.has_method("start_patrol_logic"):
		patrol_event.start_patrol_logic()


func game_over(reason: String) -> void:
	if game_ended:
		return

	game_ended = true
	game_started = false

	if time_ui != null and time_ui.has_method("stop_time"):
		time_ui.stop_time()

	if exhibit_manager != null and exhibit_manager.has_method("stop_exhibit_logic"):
		exhibit_manager.stop_exhibit_logic()

	if game_over_screen != null:
		game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS

		if game_over_screen.has_method("show_game_over"):
			game_over_screen.show_game_over(reason)
		else:
			game_over_screen.show()
	if patrol_event != null and patrol_event.has_method("stop_patrol_logic"):
		patrol_event.stop_patrol_logic()

	get_tree().paused = true


func game_clear() -> void:
	game_ended = true
	game_started = false

	if time_ui != null and time_ui.has_method("stop_time"):
		time_ui.stop_time()

	if exhibit_manager != null and exhibit_manager.has_method("stop_exhibit_logic"):
		exhibit_manager.stop_exhibit_logic()

	if patrol_event != null and patrol_event.has_method("stop_patrol_logic"):
		patrol_event.stop_patrol_logic()

	print("game_clear_screen:", game_clear_screen)

	if game_clear_screen != null and game_clear_screen.has_method("show_game_clear"):
		game_clear_screen.show_game_clear()
	else:
		print("GameClearScreen 또는 show_game_clear() 문제")

	get_tree().paused = true

	game_clear_screen.show()


func game_over_by_bell() -> void:
	game_over("종소리를 3번 들어 죽@어버렸습니다.")


func game_over_by_handaxe() -> void:
	game_over("주먹도끼에 찍혀 죽@었습니다.")


func game_over_by_horseman() -> void:
	game_over("기마병에게 붙잡혀 죽@었습니다.")


func game_over_by_bird_count() -> void:
	game_over("06:00이 되었지만 후투티를 20마리 잡지 못했습니다.")


func game_over_by_handaxe_remaining() -> void:
	game_over("06:00이 되었지만 주먹도끼를 모두 진정시키지 못했습니다.")


func game_over_by_patrol() -> void:
	var patrol_result_text: String = ""

	var patrol_manager := patrol_event

	if patrol_manager == null:
		patrol_manager = get_tree().get_first_node_in_group("PatrolEvent")

	if patrol_manager != null and patrol_manager.has_method("get_patrol_result_text"):
		patrol_result_text = patrol_manager.get_patrol_result_text()
	else:
		patrol_result_text = "순찰 성공 횟수가 부족합니다."

	game_over(
		"06:00까지 버텼지만 순찰근무를 충분히 완료하지 못했습니다.\n"
		+ patrol_result_text
	)
