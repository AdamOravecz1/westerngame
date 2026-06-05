extends Node3D

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var shop_menu = player.get_node("CanvasLayer/ShopMenu")
@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")
var index = get_index()

func _ready() -> void:
	if name == "Barracks":
		await get_tree().process_frame
		main.friend_wave_point = $FriendWavePoint.global_position
		$CanvasLayer/FriendCounter.text = str(main.friend_counter)
	if name == "BlackSmith":
		await get_tree().process_frame
		player.unlock_sniper()
	
	await get_tree().create_timer(2.0, false).timeout
	if nav_mesh.is_baking():
		await nav_mesh.bake_finished

	nav_mesh.bake_navigation_mesh()
	await nav_mesh.bake_finished
	await get_tree().create_timer(3, false).timeout

func _on_barrier_pressed() -> void:
	var barrier_scene = preload("res://Scenes/barrier.tscn")
	var barrier = barrier_scene.instantiate()
	player.add_child(barrier)
	barrier.position.z -= 3
	barrier.position.y -= 1
	shop_menu.shop(null)
	player.placing_barrier = true
	$CanvasLayer.visible = false
	
func menu():
	$CanvasLayer.visible = !$CanvasLayer.visible
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.in_shop = true

	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.in_shop = false


func _on_barrel_pressed() -> void:
	var barrel_scene = preload("res://Scenes/barrel.tscn")
	var barrel = barrel_scene.instantiate()
	player.add_child(barrel)
	barrel.position.z -= 3
	barrel.position.y -= 1
	shop_menu.shop(null)
	player.placing_barrier = true
	$CanvasLayer.visible = false
	
func _on_friend_pressed() -> void:
	if main.friend_counter < 4:
		main.friend_counter += 1
		
		$CanvasLayer/FriendCounter.text = str(main.friend_counter)
