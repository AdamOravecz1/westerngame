extends Control

@onready var music = $NinePatchRect/VBoxContainer/Music
@onready var sfx = $NinePatchRect/VBoxContainer/Sound

var health_bar = true

var full_screen = false

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
