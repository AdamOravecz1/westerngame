extends Node3D
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var shop_menu = player.get_node("CanvasLayer/ShopMenu")
@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")
@export var building_scene = preload("res://Scenes/barracks.tscn")

@onready var hover_rect: ColorRect = $CanvasLayer/HoverRect

var upgrade_text = "Unlocks access to the sniper tower on the top\nCost: 20"

func _ready() -> void:
	print(name)
	if name == "HalfBarracks":
		upgrade_text = "Produces more soldiers\nCost: 20"
		await get_tree().process_frame
		main.barracks += 1
		main.friend_wave_point = $FriendWavePoint.global_position
		main.friend_counter = 1
	if name == "HalfSaloon":
		upgrade_text = "Restores more health\nCost: 20"
		main.saloon += 1
	if name == "HalfStore":
		upgrade_text = "Gives more ammo and dynamite\nCost: 20"
		main.store += 1
	if name == "HalfMine":
		upgrade_text = "Produces more money\nCost: 20"
		main.mine += 1
	if name == "HalfBlackSmith":
		upgrade_text = "Unlocks sniper\nCost: 20"
		await get_tree().process_frame
		player.unlock_shotgun()
	if name == "HalfCarpenter":
		upgrade_text = "Unlucks exploading barrels and allows more covers\nCost: 20"
		main.carpenter = self
	await get_tree().create_timer(2.0, false).timeout
	if nav_mesh.is_baking():
		await nav_mesh.bake_finished


	nav_mesh.bake_navigation_mesh()
	await nav_mesh.bake_finished
	await get_tree().create_timer(3, false).timeout
	
func _process(_delta: float) -> void:
	if hover_rect and hover_rect.visible:
		hover_rect.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)

func menu():
	$CanvasLayer.visible = !$CanvasLayer.visible
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.in_shop = true

	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.in_shop = false

func _on_upgrade_pressed() -> void:
	if player.money < 20:
		return
	if !is_inside_tree():
		return
	
	player.AddMoney(-20)
		
	var index = get_index()
	$Menu/CollisionShape3D.disabled = true
	if get_node_or_null("Menu2/CollisionShape3D"):
		$Menu2/CollisionShape3D.disabled = true
	
	$CanvasLayer.visible = false
	shop_menu.shop(null)
	$Building.play()
	print(index)
	if index == 6:
		player.teleport(global_position + Vector3(0, 0, 10), global_rotation + Vector3(0, deg_to_rad(270), 0))
	elif index >= 3:
		player.teleport(global_position + Vector3(5, 0, 0), global_rotation + Vector3(0, deg_to_rad(270), 0))
	else:
		player.teleport(global_position + Vector3(-5, 0, 0), global_rotation + Vector3(0, deg_to_rad(270), 0))
	await get_tree().create_timer(.5, false).timeout
	
	var new_building = building_scene.instantiate()
	var original_scale = new_building.scale

	get_parent().add_child(new_building)
	get_parent().move_child(new_building, index + 1)
	new_building.global_transform = global_transform
	new_building.scale = original_scale
	
	if new_building.name == "Mine":
		main.shrink_hole(index, 0.025, 0.019)
		if index >= 3:
			new_building.global_position += Vector3(-0.9, 0, 0) 
		else:
			new_building.global_position += Vector3(0.9, 0, 0) 
	
	visible = false
	await get_tree().create_timer(.5, false).timeout

	queue_free()


func _on_barrier_pressed() -> void:
	if main.barrier_counter < 4:
		var barrier_scene = preload("res://Scenes/barrier.tscn")
		var barrier = barrier_scene.instantiate()
		player.add_child(barrier)
		barrier.position.z -= 3
		barrier.position.y -= 1
		shop_menu.shop(null)
		player.placing_barrier = true
		$CanvasLayer.visible = false


func _on_next_wave_pressed() -> void:
	main.next_wave()
	$CanvasLayer.visible = false
	shop_menu.shop(null)

func update_barriers(num):
	$CanvasLayer/BarrierCounter.text = str(num) + "/4"


func _on_upgrade_mouse_entered() -> void:
	if not hover_rect.visible:
		hover_rect.visible = true
		$CanvasLayer/HoverRect/RichTextLabel.text = upgrade_text


func _on_upgrade_mouse_exited() -> void:
	hover_rect.visible = false
