extends Node3D

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

var rng := RandomNumberGenerator.new()

var wave_counter := 0
var in_combat := false
var enemie_order := [
	[enemy_scene],
	[enemy_scene, enemy_scene],
	[dog_scene, dog_scene, dog_scene],
	[enemy_scene, dog_scene, dog_scene],
	[enemy_scene, enemy_scene, dog_scene],
	[enemy_scene, enemy_scene, enemy_scene, dog_scene, dog_scene],
	[boss_scene]
]

func _ready():
	rng.randomize()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		next_wave()
	if len(get_tree().get_nodes_in_group("enemy")) == 0 and in_combat:
		in_combat = false
		
	
func next_wave():
	in_combat = true
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
	
	for i in enemie_order[wave_counter]:
		var enemy = i.instantiate()
		$Enemies.add_child(enemy)
		$Path3D/PathFollow3D.progress_ratio = randf()
		enemy.global_position = $Path3D/PathFollow3D.global_position
		await get_tree().create_timer(1, false).timeout
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
	
