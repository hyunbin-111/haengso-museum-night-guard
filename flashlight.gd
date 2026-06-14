extends Control
 
 
@onready var progress_bar : ProgressBar = $ProgressBar
 
func _ready() -> void:
	self.hide()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value     = 100.0
 
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.battery_changed.connect(_on_battery_changed)
 
func _on_battery_changed(value: float) -> void:
	progress_bar.value = value
 
	if value > 50.0:
		progress_bar.modulate = Color(0.3, 1.0, 0.5)
	elif value > 25.0:
		progress_bar.modulate = Color(1.0, 0.85, 0.2)
	else:
		progress_bar.modulate = Color(1.0, 0.25, 0.25)
		_blink()
 
var _blinking : bool = false
func _blink() -> void:
	if _blinking:
		return
	_blinking = true
	for i in 3:
		progress_bar.visible = false
		await get_tree().create_timer(0.15).timeout
		progress_bar.visible = true
		await get_tree().create_timer(0.15).timeout
	_blinking = false
