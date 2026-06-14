extends Camera2D

var shake_strength: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

var base_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	base_offset = offset
	add_to_group("GameCamera")


func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta

		var power := shake_timer / shake_duration

		offset = base_offset + Vector2(
			randf_range(-shake_strength, shake_strength) * power,
			randf_range(-shake_strength, shake_strength) * power
		)
	else:
		offset = base_offset


func shake(strength: float = 10.0, duration: float = 0.3) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_timer = duration
