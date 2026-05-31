extends Node3D

@export var broken_model:PackedScene
@export var min_barrier_distance := 3.0

@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var player = get_tree().get_first_node_in_group("Player")

@onready var valid_barrier_checker_scene = preload("res://Scenes/valid_barrier_checker.tscn")

var friends_cache = []

var checker1_rays = []
var checker2_rays = []

var hide_area_valid := true
var hide_area2_valid := true
var can_place_down := true

var full := true
var placed := false

func _ready():
	add_to_group("barrier")

	create_friend_checkers()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ok") and not placed:
		if can_place_barrier():
			place()

	if Input.is_action_pressed("rotate_left") and not placed:
		rotate_y(deg_to_rad(90 * delta))

	if Input.is_action_pressed("rotate_right") and not placed:
		rotate_y(deg_to_rad(-90 * delta))

	if !placed:
		return

	var hide_area1_enabled = true
	var hide_area2_enabled = true

	# -------------------------
	# SIDE 1 (ALL must hit)
	# -------------------------
	for data in checker1_rays:
		var ray = data["ray"]
		var friend = data["friend"]

		if !is_instance_valid(friend):
			hide_area1_enabled = false
			break

		ray.look_at(friend.global_position, Vector3.UP)
		

		if ray.get_collider() != $Barrier:
			hide_area1_enabled = false


		if Vector2($HideArea.global_position.x, $HideArea.global_position.z).distance_to(
			Vector2(player.global_position.x, player.global_position.z)
		) < 3:
			hide_area1_enabled = false


	# -------------------------
	# SIDE 2 (ALL must hit)
	# -------------------------
	for data in checker2_rays:
		var ray = data["ray"]
		var friend = data["friend"]

		if !is_instance_valid(friend):
			hide_area2_enabled = false
			break

		ray.look_at(friend.global_position, Vector3.UP)
		

		if ray.get_collider() != $Barrier:
			hide_area2_enabled = false
			
		

		if Vector2($HideArea2.global_position.x, $HideArea2.global_position.z).distance_to(
			Vector2(player.global_position.x, player.global_position.z)
		) < 3:
			hide_area2_enabled = false

	$HideArea/CollisionShape3D.disabled = !hide_area1_enabled
	$HideArea2/CollisionShape3D.disabled = !hide_area2_enabled
	
func destroy(from_position: Vector3, force: float = 5.0):
	if full:
		full = false

		var old_parent = get_parent()
		old_parent.remove_child(self)
		main.add_child(self)

		var broken_model_inst: Node3D = broken_model.instantiate()
		get_parent().add_child(broken_model_inst)
		broken_model_inst.transform = self.transform

		# Apply force to all rigid bodies inside the broken model
		for body in broken_model_inst.get_children():
			if body is RigidBody3D:
				var direction = (body.global_position - from_position).normalized()
				body.apply_impulse(direction * force)

		queue_free()

func place():
	$CanvasLayer.visible = false
	$Barrier/CollisionShape3D.disabled = false
	placed = true
	player.placing_barrier = false
	
	$OverlapChecker.queue_free()

	var global_transform_backup = global_transform
	var old_parent = get_parent()
	old_parent.remove_child(self)
	main.get_node("NavigationRegion3D/Barriers").add_child(self)
	global_transform = global_transform_backup

	if nav_mesh.is_baking():
		await nav_mesh.bake_finished

	nav_mesh.bake_navigation_mesh()
	await nav_mesh.bake_finished
	await get_tree().create_timer(3, false).timeout

func can_place_barrier() -> bool:
	# Area limits
	if global_position.x < -8 or global_position.x > 11:
		print("Can't place outside X bounds!")
		return false

	if global_position.z < -30 or global_position.z > -5:
		print("Can't place outside Z bounds!")
		return false

	if not can_place_down:
		print("overlap")
		return false
	## Distance check
	#var barriers = get_tree().get_nodes_in_group("barrier")
	#
	#for barrier in barriers:
		#if barrier == self:
			#continue
	#
		#if global_position.distance_to(barrier.global_position) < min_barrier_distance:
			#print("Too close to another barrier!")
			#return false

	return true
	

func create_friend_checkers():
	for data in checker1_rays:
		data["ray"].queue_free()

	for data in checker2_rays:
		data["ray"].queue_free()

	checker1_rays.clear()
	checker2_rays.clear()

	friends_cache = get_tree().get_nodes_in_group("friend")

	for friend in friends_cache:
		var ray1 = valid_barrier_checker_scene.instantiate()
		$Checker1Pos.add_child(ray1)

		checker1_rays.append({
			"ray": ray1,
			"friend": friend
		})

		var ray2 = valid_barrier_checker_scene.instantiate()
		$Checker2Pos.add_child(ray2)

		checker2_rays.append({
			"ray": ray2,
			"friend": friend
		})
		

func _on_hide_area_body_entered(body: Node3D) -> void:
	hide_area_valid = false

func _on_hide_area_body_exited(body: Node3D) -> void:
	hide_area_valid = true

func _on_hide_area_2_body_entered(body: Node3D) -> void:
	hide_area2_valid = false

func _on_hide_area_2_body_exited(body: Node3D) -> void:
	hide_area2_valid = true


func _on_overlap_checker_body_entered(body: Node3D) -> void:
	can_place_down = false


func _on_overlap_checker_body_exited(body: Node3D) -> void:
	can_place_down = true
