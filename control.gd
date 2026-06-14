extends Control

@onready var panel: Panel = $Panel
@onready var label: RichTextLabel = $Panel/RichTextLabel
@onready var next_icon: Label = $Panel/NextIcon
@onready var typing_sound: AudioStreamPlayer = $TypingSound

@export var text_speed: float = 0.035

var dialogues = [
	"오늘부터 일할 박물관이 여기구나",
	"무슨 일을 하길래 월급을 이렇게 많이 준다고 하지?",
	"근무수칙..? 야간 경비원이 할 게 뭐 있다고 이래"
]

var index: int = 0
var is_typing: bool = false
var current_text: String = ""


func _ready() -> void:
	hide()
	next_icon.hide()
	start_next_icon_blink()


func start_dialogue() -> void:
	index = 0
	show()
	show_dialogue()


func show_dialogue() -> void:
	current_text = str(dialogues[index])

	label.text = current_text
	label.visible_characters = 0

	next_icon.hide()

	start_typing()


func start_typing() -> void:
	is_typing = true
	next_icon.hide()

	start_typing_sound()

	for i in range(current_text.length() + 1):
		if not is_typing:
			stop_typing_sound()
			return

		label.visible_characters = i
		await get_tree().create_timer(text_speed).timeout

	is_typing = false
	stop_typing_sound()
	next_icon.show()


func start_typing_sound() -> void:
	if typing_sound == null:
		return

	if typing_sound.playing:
		return

	typing_sound.play()


func stop_typing_sound() -> void:
	if typing_sound == null:
		return

	if typing_sound.playing:
		typing_sound.stop()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed:
		# 대화창은 왼쪽 클릭만 넘기기
		# 우클릭은 Manual에서 쓰기 때문에 무시
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if is_typing:
			finish_typing()
		else:
			next_dialogue()


func finish_typing() -> void:
	is_typing = false
	label.visible_characters = current_text.length()
	stop_typing_sound()
	next_icon.show()


func next_dialogue() -> void:
	next_icon.hide()

	index += 1

	if index < dialogues.size():
		show_dialogue()
	else:
		end_dialogue()


func end_dialogue() -> void:
	stop_typing_sound()

	hide()
	next_icon.hide()

	var main := get_tree().current_scene

	if main != null and main.has_method("on_dialogue_finished"):
		main.on_dialogue_finished()


func start_next_icon_blink() -> void:
	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(next_icon, "modulate:a", 0.25, 0.5)
	tween.tween_property(next_icon, "modulate:a", 1.0, 0.5)
