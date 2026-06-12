extends Node3D
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var shop_menu = player.get_node("CanvasLayer/ShopMenu")
@onready var index = get_index()
		
func build(building):
	if !is_inside_tree():
		return
	
	player.AddMoney(-10)
	$Foundation/CollisionShape3D.disabled = true
	shop_menu.shop(null)
	$Building.play()

	if index >= 3:
		player.teleport(global_position + Vector3(5, 0, 0), global_rotation + Vector3(0, deg_to_rad(270), 0))
	else:
		player.teleport(global_position + Vector3(-5, 0, 0), global_rotation + Vector3(0, deg_to_rad(270), 0))
	await get_tree().create_timer(.5, false).timeout
	
	var building_scene = load(building)
	var new_building = building_scene.instantiate()
	var original_scale = new_building.scale

	get_parent().add_child(new_building)
	get_parent().move_child(new_building, index + 1)
	new_building.global_transform = global_transform
	new_building.scale = original_scale
	
	if new_building.name != "HalfMine":
		main.close_ground(index)
	else:
		main.shrink_hole(index, 0.018, 0.018)
	visible = false
	await get_tree().create_timer(.5, false).timeout

	queue_free()
