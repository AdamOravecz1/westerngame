extends Node3D

@onready var player = get_tree().get_first_node_in_group("Player")

var barrier_scene = preload("res://Scenes/barrier.tscn")
var enemy_scene = preload("res://Scenes/revolver_enemy.tscn")
var friend_scene = preload("res://Scenes/revolver_friend.tscn")

var friend_counter := 0
var friend_wave_point := Vector3.ZERO

var saloon := 0
var store := 0
var mine := 0
var barracks := 0

var rng := RandomNumberGenerator.new()


func _ready():
	rng.randomize()

	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug"):
		next_wave()

func next_wave():
	var enemy = enemy_scene.instantiate()
	$Enemies.add_child(enemy)
	enemy.global_position = $EnemyWavePoint.global_position
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
	for i in friend_counter:
		var friend = friend_scene.instantiate()
		$Enemies.add_child(friend)
		friend.global_position = friend_wave_point
		await get_tree().create_timer(1, false).timeout
		

	
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
	
