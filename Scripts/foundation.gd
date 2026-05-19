extends Node3D
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var index = get_index()

func shop():
	$CanvasLayer.visible = !$CanvasLayer.visible
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.in_shop = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.in_shop = false
		
func build(building):
	if !is_inside_tree():
		return
	
	shop()
	var building_scene = load(building)
	var new_building = building_scene.instantiate()
	var original_scale = new_building.scale

	get_parent().add_child(new_building)
	new_building.global_transform = global_transform
	new_building.scale = original_scale
	
	if new_building.name != "HalfMine":
		main.close_ground(index)
	else:
		main.shrink_hole(index)

	queue_free()

func _on_black_smith_pressed() -> void:
	build("res://Scenes/half_black_smith.tscn")


func _on_store_pressed() -> void:
	build("res://Scenes/half_store.tscn")


func _on_carpenter_pressed() -> void:
	build("res://Scenes/half_carpenter.tscn")


func _on_barracks_pressed() -> void:
	build("res://Scenes/half_barracks.tscn")


func _on_mine_pressed() -> void:
	build("res://Scenes/half_mine.tscn")


func _on_saloon_pressed() -> void:
	build("res://Scenes/half_saloon.tscn")
