extends Node3D

var barrier_scene = preload("res://Scenes/barrier.tscn")
var enemy_scene = preload("res://Scenes/revolver_enemy.tscn")


const MIN_BARRIERS := 10
const MAX_BARRIERS := 20
const MIN_DISTANCE := 3.0

const X_MIN := -9.0
const X_MAX := 9.0
const Z_MIN := -25.0
const Z_MAX := 0.0

var wave_number := 0
var barrier_points: Array[Vector3] = []
var enemy_points: Array[Vector3] = []

var rng := RandomNumberGenerator.new()

func _ready():
	rng.randomize()

	
func next_wave():
	spawn_barriers()
	spawn_enemy_wave()

func spawn_barriers():
	clear_barriers()
	barrier_points.clear()

	var target_count = rng.randi_range(MIN_BARRIERS, MAX_BARRIERS)
	barrier_points = generate_valid_points(target_count, [])

	for point in barrier_points:
		var barrier = barrier_scene.instantiate()
		barrier.position = point
		barrier.rotation.y = rng.randf_range(0.0, TAU)
		$NavigationRegion3D.add_child(barrier)

	print("Spawned barriers:", barrier_points)

	await get_tree().create_timer(1).timeout
	$NavigationRegion3D.bake_navigation_mesh()

func clear_barriers():
	for child in $NavigationRegion3D.get_children():
		if child.is_in_group("barrier"):
			child.queue_free()

func spawn_enemy_wave():
	wave_number += 1
	enemy_points.clear()

	# Enemies must avoid barriers + other enemies
	var forbidden = barrier_points.duplicate()

	enemy_points = generate_valid_points(wave_number, forbidden)

	for point in enemy_points:
		var enemy = enemy_scene.instantiate()
		enemy.position = point
		$Enemies.add_child(enemy)

	print("Wave", wave_number, "spawned:", enemy_points.size(), "enemies")

func generate_valid_points(count: int, forbidden: Array) -> Array:
	var result: Array[Vector3] = []

	var max_attempts := 3000
	var attempts := 0

	while result.size() < count and attempts < max_attempts:
		attempts += 1

		var candidate = random_point()

		if is_far_enough(candidate, forbidden) and is_far_enough(candidate, result):
			result.append(candidate)

	if attempts >= max_attempts:
		push_warning("Point generation stopped early.")

	return result

func random_point() -> Vector3:
	return Vector3(
		rng.randf_range(X_MIN, X_MAX),
		0.0,
		rng.randf_range(Z_MIN, Z_MAX)
	)

func is_far_enough(point: Vector3, existing: Array) -> bool:
	for p in existing:
		if point.distance_to(p) < MIN_DISTANCE:
			return false
	return true
