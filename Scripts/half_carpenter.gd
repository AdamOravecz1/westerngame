extends Node3D
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var shop_menu = player.get_node("CanvasLayer/ShopMenu")
var index = get_index()

func menu():
	$CanvasLayer.visible = !$CanvasLayer.visible
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.in_shop = true

	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.in_shop = false

func _on_upgrade_pressed() -> void:
	if !is_inside_tree():
		return
		
	var index = get_index()
	
	$CanvasLayer.visible = false
	shop_menu.shop(null)
	$Building.play()
	if index >= 3:
		player.teleport(global_position + Vector3(5, 0, 0), global_rotation + Vector3(0, deg_to_rad(270), 0))
	else:
		player.teleport(global_position + Vector3(-5, 0, 0), global_rotation + Vector3(0, deg_to_rad(270), 0))
	await get_tree().create_timer(.5, false).timeout
	
	var building_scene = load("res://Scenes/carpenter.tscn")
	var new_building = building_scene.instantiate()
	var original_scale = new_building.scale

	get_parent().add_child(new_building)
	new_building.global_transform = global_transform
	new_building.scale = original_scale
	
	visible = false
	await get_tree().create_timer(.5, false).timeout

	queue_free()
