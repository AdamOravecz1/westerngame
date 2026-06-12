extends Node3D
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var shop_menu = player.get_node("CanvasLayer/ShopMenu")
@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")
@export var building_scene = preload("res://Scenes/barracks.tscn")

func _ready() -> void:
	print(name)
	if name == "HalfBarracks":
		await get_tree().process_frame
		main.barracks += 1
		main.friend_wave_point = $FriendWavePoint.global_position
	if name == "HalfSaloon":
		main.saloon += 1
	if name == "HalfStore":
		main.store += 1
	if name == "HalfMine":
		main.mine += 1
	await get_tree().create_timer(2.0, false).timeout
	if nav_mesh.is_baking():
		await nav_mesh.bake_finished
	if name == "HalfBlackSmith":
		await get_tree().process_frame
		player.unlock_shotgun()

	nav_mesh.bake_navigation_mesh()
	await nav_mesh.bake_finished
	await get_tree().create_timer(3, false).timeout

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
	var barrier_scene = preload("res://Scenes/barrier.tscn")
	var barrier = barrier_scene.instantiate()
	player.add_child(barrier)
	barrier.position.z -= 3
	barrier.position.y -= 1
	shop_menu.shop(null)
	player.placing_barrier = true
	$CanvasLayer.visible = false

	


func _on_friend_pressed() -> void:
	if main.friend_counter < 2:
		main.friend_counter += 1
		$CanvasLayer/FriendCounter.text = str(main.friend_counter)
		


func _on_next_wave_pressed() -> void:
	main.next_wave()
	$CanvasLayer.visible = false
	shop_menu.shop(null)
