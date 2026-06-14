extends Control

@onready var label = $Label

func show_location(name: String):
	label.text = "tlqkf"
	visible = true
	
	await get_tree().create_timer(2.0).timeout
	
	visible = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
