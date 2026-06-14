extends Control

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label

@export var fade_duration: float = 0.3
@export var result_show_duration: float = 3.0

var message_tween: Tween = null


func _ready() -> void:
	hide()
	modulate.a = 0.0


func show_persistent_message(text: String) -> void:
	_kill_message_tween()

	label.text = text
	show()

	if modulate.a < 1.0:
		message_tween = create_tween()
		message_tween.tween_property(
			self,
			"modulate:a",
			1.0,
			fade_duration
		)
	else:
		modulate.a = 1.0


func update_persistent_message(text: String) -> void:
	label.text = text

	if not visible:
		show()
		modulate.a = 1.0


func hide_persistent_message() -> void:
	_kill_message_tween()

	hide()
	modulate.a = 0.0


func show_result_message(text: String, duration: float = -1.0) -> void:
	_kill_message_tween()

	if duration < 0.0:
		duration = result_show_duration

	label.text = text
	show()
	modulate.a = 0.0

	message_tween = create_tween()

	message_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		fade_duration
	)

	message_tween.tween_interval(duration)

	message_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_duration
	)

	message_tween.finished.connect(_on_result_message_finished)


func _on_result_message_finished() -> void:
	hide()
	modulate.a = 0.0
	message_tween = null


func hide_all() -> void:
	_kill_message_tween()

	hide()
	modulate.a = 0.0
	label.text = ""


func _kill_message_tween() -> void:
	if message_tween != null:
		if message_tween.is_valid():
			message_tween.kill()

	message_tween = null
