extends Area2D

var right_map
@export var spawn_position: Vector2
@export var invincible_time: float = 1.5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	right_map = get_parent().get_parent().get_node("museum_right")



func _on_body_entered(body):
	if body.is_in_group("Player"):
		var manager = get_tree().get_first_node_in_group("map_manager")
		manager.change_map(right_map, spawn_position)
		
		if body.has_method("start_invincible"):
			body.start_invincible(invincible_time)
		
