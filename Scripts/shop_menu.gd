extends Control

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var shop_menu = player.get_node("CanvasLayer/ShopMenu")
var foundation = null

func shop(found):
	foundation = found
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.in_shop = true
		shop_menu.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.in_shop = false
		shop_menu.visible = false


func _on_black_smith_pressed() -> void:
	foundation.build("res://Scenes/half_black_smith.tscn")
	$VBoxContainer/BlackSmith.queue_free()


func _on_store_pressed() -> void:
	foundation.build("res://Scenes/half_store.tscn")
	$VBoxContainer/Store.queue_free()

func _on_carpenter_pressed() -> void:
	foundation.build("res://Scenes/half_carpenter.tscn")
	$VBoxContainer/Carpenter.queue_free()


func _on_barracks_pressed() -> void:
	foundation.build("res://Scenes/half_barracks.tscn")
	$VBoxContainer/Barracks.queue_free()


func _on_mine_pressed() -> void:
	foundation.build("res://Scenes/half_mine.tscn")
	$VBoxContainer/Mine.queue_free()


func _on_saloon_pressed() -> void:
	foundation.build("res://Scenes/half_saloon.tscn")
	$VBoxContainer/Saloon.queue_free()
