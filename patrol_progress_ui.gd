extends Control

@onready var label: Label = $Label


func _ready() -> void:
	hide()


func update_progress(success_count: int, required_count: int, event_count: int, max_event_count: int) -> void:
	show()

	label.text = "순찰근무\n성공: " + str(success_count) + " / " + str(required_count) \
		+ "\n발생: " + str(event_count) + " / " + str(max_event_count)
