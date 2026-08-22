extends Node3D

var next_pressed := 0

@onready var player = get_tree().get_first_node_in_group("Player")

var barrier_scene = preload("res://Scenes/barrier.tscn")
var enemy_scene = preload("res://Scenes/revolver_enemy.tscn")
var dog_scene = preload("res://Scenes/dog.tscn")
var boss_scene = preload("res://Scenes/boss.tscn")
var friend_scene = preload("res://Scenes/revolver_friend.tscn")

var friend_counter := 0
var friend_wave_point := Vector3.ZERO

var saloon := 0
var store := 0
var mine := 0
var barracks := 0

var carpenter = null
var barrier_counter := 0
var barrel_counter := 0

var rng := RandomNumberGenerator.new()

var wave_counter := 0
var wave_loading := false
var in_combat := false
var enemie_order := [
	[enemy_scene],
	[enemy_scene, dog_scene],
	[enemy_scene, enemy_scene],
	[enemy_scene, dog_scene, dog_scene],
	[enemy_scene, enemy_scene, dog_scene],
	[enemy_scene, enemy_scene, enemy_scene],
	[enemy_scene, enemy_scene, dog_scene, dog_scene],
	[enemy_scene, enemy_scene, enemy_scene, dog_scene, dog_scene],
	[enemy_scene, enemy_scene, enemy_scene, enemy_scene],
	[enemy_scene, enemy_scene, enemy_scene, dog_scene, dog_scene, dog_scene],
	[enemy_scene, enemy_scene, enemy_scene, enemy_scene, enemy_scene, dog_scene, dog_scene],
	[boss_scene]
]

func _ready():
	rng.randomize()
	
func _process(delta: float) -> void:
	if len(get_tree().get_nodes_in_group("enemy")) == 0 and in_combat and not wave_loading:
		in_combat = false
		
	
func next_wave():
	if wave_counter == len(enemie_order):
		win()
		return
	in_combat = true
	wave_loading = true
	for i in get_tree().get_nodes_in_group("barrel"):
		if not i.placed:
			i.cancel_placing()
	for i in get_tree().get_nodes_in_group("barrier"):
		if not i.placed:
			i.cancel_placing()
	if mine == 1:
		player.AddMoney(10)
	elif mine == 2:
		player.AddMoney(20)
	if saloon == 1:
		player.AddHealth(10)
	elif saloon == 2:
		player.AddHealth(20)
	if store == 1:
		player.AddBullets(1)
	if store == 2:
		player.AddBullets(2)
		player.AddDynamite()
	
	var wave_length = len(enemie_order[wave_counter])
	var enemies_spawned = 0
	for i in enemie_order[wave_counter]:
		var enemy = i.instantiate()
		$Enemies.add_child(enemy)
		$Path3D/PathFollow3D.progress_ratio = randf()
		enemy.global_position = $Path3D/PathFollow3D.global_position
		await get_tree().create_timer(1, false).timeout
		enemies_spawned += 1
		if enemies_spawned >= wave_length:
			wave_loading = false
	for i in friend_counter:
		var friend = friend_scene.instantiate()
		$Enemies.add_child(friend)
		friend.global_position = friend_wave_point
		await get_tree().create_timer(1, false).timeout
		
	wave_counter += 1

	
func close_ground(num):
	var mat = $Ground.material_override as ShaderMaterial

	var sizes = mat.get_shader_parameter("hole_sizes")
	sizes[num] = Vector2(0.0, 0.0)

	mat.set_shader_parameter("hole_sizes", sizes)
	
func shrink_hole(num, x, y):
	var mat = $Ground.material_override as ShaderMaterial

	var sizes = mat.get_shader_parameter("hole_sizes")
	sizes[num] = Vector2(x, y)

	mat.set_shader_parameter("hole_sizes", sizes)
	
func add_barrier(num):
	barrier_counter += num
	carpenter.update_barriers(barrier_counter)
	
func add_barrel(num):
	barrel_counter += num
	carpenter.update_barrels(barrel_counter)


func _on_start_pressed() -> void:
	$CanvasLayer/VBoxContainer.visible = false
	var tween = get_tree().create_tween()
	tween.tween_property($CameraPath/PathFollow3D, "progress_ratio", 0, 2)
	await tween.finished
	player.start()


func _on_settings_pressed() -> void:
	$CanvasLayer/VBoxContainer.visible = false
	$CanvasLayer/Pause.visible = true
	
func back():
	$CanvasLayer/VBoxContainer.visible = true
	$CanvasLayer/Pause.visible = false
	
func win():
	player.in_shop = true
	$CanvasLayer/Restart.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_property($CanvasLayer/Victory, "modulate", Color(1,1,1,1), 0.5)
	tween.tween_property($CanvasLayer/Restart, "modulate", Color(1,1,1,1), 0.5)
	await tween.finished
	player.get_node("CanvasLayer/Pain").material.set_shader_parameter("intensity", 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.in_shop = true


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_tutorial_pressed() -> void:
	$CanvasLayer/VBoxContainer.visible = false
	$CanvasLayer/Tutorial.visible = true
	$CanvasLayer/Next.visible = true


func _on_next_pressed() -> void:
	next_pressed += 1
	if next_pressed == 1:
		$CanvasLayer/Tutorial/TextureRect.visible = false
		$CanvasLayer/Tutorial/TextureRect2.visible = true
	if next_pressed == 2:
		$CanvasLayer/Tutorial/TextureRect2.visible = false
		$CanvasLayer/Tutorial/TextureRect3.visible = true
	if next_pressed == 3:
		$CanvasLayer/Tutorial.visible = false
		$CanvasLayer/Next.visible = false
		$CanvasLayer/VBoxContainer.visible = true
		next_pressed == 0
