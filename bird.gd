extends CharacterBody2D

@export var move_speed : float = 160.0
@export var arrive_distance : float = 20.0

var target_position : Vector2
var smooth_velocity : Vector2 = Vector2.ZERO
var player_near : bool = false

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var wander_timer : Timer = $WanderTimer
@onready var interact_area : Area2D = $InteractArea
@onready var interact_label : Label = $Label
@onready var catch_sound: AudioStreamPlayer2D = $CatchSound

@onready var limit_top_left: Node2D = get_tree().current_scene.get_node("LimitTopLeft")
@onready var limit_bottom_right: Node2D = get_tree().current_scene.get_node("LimitBottomRight")


func _ready() -> void:
	randomize()

	interact_label.visible = false
	interact_label.text = "[E] 잡기"


	wander_timer.wait_time = randf_range(2.0, 5.0)
	wander_timer.timeout.connect(_pick_new_target)
	wander_timer.start()

	_pick_new_target()


func _physics_process(delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interact"):
		remove_bird()
		return

	var distance := global_position.distance_to(target_position)

	if distance <= arrive_distance:
		smooth_velocity = smooth_velocity.lerp(Vector2.ZERO, 0.1)
		global_position += smooth_velocity * delta
		update_animation(smooth_velocity)
		return

	var direction := global_position.direction_to(target_position)
	var desired_velocity := direction * move_speed

	smooth_velocity = smooth_velocity.lerp(desired_velocity, 0.12)

	global_position += smooth_velocity * delta

	update_animation(smooth_velocity)


func remove_bird() -> void:
	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	if manager != null and manager.has_method("catch_bird"):
		manager.catch_bird()
	
	if catch_sound != null:
		catch_sound.play()

	# 잡힌 후에는 안 보이고 충돌도 안 되게 처리
	hide()
	set_physics_process(false)
	set_process(false)

	# 소리가 끝난 뒤 삭제
	if catch_sound != null:
		await catch_sound.finished

	queue_free()


func _pick_new_target() -> void:
	var min_x := limit_top_left.global_position.x
	var min_y := limit_top_left.global_position.y
	var max_x := limit_bottom_right.global_position.x
	var max_y := limit_bottom_right.global_position.y

	target_position = Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)

	wander_timer.wait_time = randf_range(2.0, 5.0)


func update_animation(direction: Vector2) -> void:
	if direction.length() < 1.0:
		sprite.stop()
		return

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			if sprite.animation != "right":
				sprite.play("right")
		else:
			if sprite.animation != "left":
				sprite.play("left")
	else:
		if direction.y > 0:
			if sprite.animation != "down":
				sprite.play("down")
		else:
			if sprite.animation != "up":
				sprite.play("up")


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_near = true
		interact_label.visible = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_near = false
		interact_label.visible = false
