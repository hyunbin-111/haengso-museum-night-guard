extends Node2D

@onready var current_map = $Lobby
@onready var door_open_sound: AudioStreamPlayer = $DoorOpenSound

func change_map(new_map: Node2D, spawn_position: Vector2):
	play_door_open_sound()

	current_map = new_map

	var player = get_tree().get_first_node_in_group("Player")
	player.global_position = spawn_position
	await get_tree().process_frame

	update_camera_limit(player)

func update_camera_limit(player):
	var camera = player.get_node("Camera2D")

	var top_left = current_map.get_node("LimitTopLeft").global_position
	var bottom_right = current_map.get_node("LimitBottomRight").global_position

	camera.limit_left = top_left.x
	camera.limit_top = top_left.y
	camera.limit_right = bottom_right.x
	camera.limit_bottom = bottom_right.y
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	update_camera_limit(player)

	
func play_door_open_sound() -> void:
	if door_open_sound == null:
		return

	door_open_sound.stop()
	door_open_sound.pitch_scale = randf_range(0.95, 1.05)
	door_open_sound.play()
