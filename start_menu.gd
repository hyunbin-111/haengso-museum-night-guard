extends Control

@onready var start_button: TextureButton = $StartButton
@onready var settings_button: TextureButton = $SettingsButton

@onready var settings_panel: Panel = $SettingsPanel
@onready var close_button: Button = $SettingsPanel/CloseButton
@onready var volume_label: Label = $SettingsPanel/VolumeLabel
@onready var volume_slider: HSlider = $SettingsPanel/VolumeSlider
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer


func _ready() -> void:
	settings_panel.hide()

	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

	setup_button_effect(start_button)
	setup_button_effect(settings_button)

	setup_volume_slider()

	volume_slider.value_changed.connect(_on_volume_changed)
	play_bgm()

func play_bgm() -> void:
	if bgm_player == null:
		return

	if not bgm_player.playing:
		bgm_player.play()

func _on_start_button_pressed() -> void:
	if bgm_player != null:
		bgm_player.stop()
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_settings_button_pressed() -> void:
	settings_panel.show()


func _on_close_button_pressed() -> void:
	settings_panel.hide()


func setup_volume_slider() -> void:
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01

	var master_index := AudioServer.get_bus_index("Master")

	if master_index == -1:
		print("Master 오디오 버스를 찾지 못함")
		return

	var current_db := AudioServer.get_bus_volume_db(master_index)
	var current_linear := db_to_linear(current_db)

	# Master가 음소거 상태면 슬라이더도 0으로 표시
	if AudioServer.is_bus_mute(master_index):
		volume_slider.value = 0.0
	else:
		volume_slider.value = clamp(current_linear, 0.0, 1.0)

	update_volume_label(volume_slider.value)


func _on_volume_changed(value: float) -> void:
	set_master_volume(value)
	update_volume_label(value)


func set_master_volume(value: float) -> void:
	var master_index := AudioServer.get_bus_index("Master")

	if master_index == -1:
		print("Master 오디오 버스를 찾지 못함")
		return

	value = clamp(value, 0.0, 1.0)

	if value <= 0.0:
		AudioServer.set_bus_mute(master_index, true)
	else:
		AudioServer.set_bus_mute(master_index, false)
		AudioServer.set_bus_volume_db(master_index, linear_to_db(value))


func update_volume_label(value: float) -> void:
	var percent := int(round(value * 100.0))
	volume_label.text = str(percent) + "%"


func setup_button_effect(button: TextureButton) -> void:
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))


func _on_button_mouse_entered(button: TextureButton) -> void:
	button.modulate = Color(1.1, 1.0, 0.85, 1.0)


func _on_button_mouse_exited(button: TextureButton) -> void:
	button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_button_down(button: TextureButton) -> void:
	button.modulate = Color(0.55, 0.5, 0.45, 1.0)


func _on_button_up(button: TextureButton) -> void:
	if button.is_hovered():
		button.modulate = Color(1.1, 1.0, 0.85, 1.0)
	else:
		button.modulate = Color(1.0, 1.0, 1.0, 1.0)
