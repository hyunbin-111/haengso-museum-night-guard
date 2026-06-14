extends Area2D

var current_map
@export var spawn_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_map = get_parent().get_parent().get_node("Lobby")




func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var manager = get_tree().get_first_node_in_group("map_manager")
		manager.change_map(current_map, spawn_position)
