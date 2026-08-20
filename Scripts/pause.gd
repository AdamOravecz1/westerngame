extends Control

@onready var music = $NinePatchRect/VBoxContainer/Music
@onready var sfx = $NinePatchRect/VBoxContainer/Sound
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")

var health_bar = true

var full_screen = false

func _unhandled_input(event):
	if event.is_action_pressed("pause") and not player.in_shop:
		player.pause()
		

func _ready():
	music.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sfx.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	

func _on_sound_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

func _on_music_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)


func _on_full_screen_pressed() -> void:
	if full_screen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		full_screen = false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		full_screen = true

func _on_quit_pressed() -> void:

	get_tree().quit()


func _on_return_pressed() -> void:
	if player.speed != 0:
		player.pause()
	else:
		main.back()

func _on_input_pressed() -> void:
	$NinePatchRect.visible = false
	$InputSettings.visible = true
	
func close_input_settings():
	$InputSettings.hide()
	$NinePatchRect.show()

	var node = $NinePatchRect

	while node:
		print(node.name, " visible = ", node.visible)
		node = node.get_parent()
