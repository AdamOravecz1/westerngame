extends Node3D

@export var broken_model:PackedScene
@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var player = get_tree().get_first_node_in_group("Player")

var full := true
var placed := false

var can_place_down := true

var bounds_tween: Tween = null
var overlap_tween: Tween = null

func _ready():
	add_to_group("barrel")
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ok") and not placed:
		if can_place_barrel():
			place()
			
	if Input.is_action_just_pressed("cancel") and not placed:
		player.placing_barrier = false
		queue_free()

	if Input.is_action_pressed("rotate_left") and not placed:
		rotate_y(deg_to_rad(90 * delta))

	if Input.is_action_pressed("rotate_right") and not placed:
		rotate_y(deg_to_rad(-90 * delta))


func hit():
	if full:
		main.add_barrel(-1)
		
		$Area3D.monitoring = true
		full = false

		visible = false
		var old_parent = self.get_parent()
		old_parent.remove_child(self)  # Remove from current parent
		main.add_child(self)     # Add to new parent
		var broken_model_inst:Node3D = broken_model.instantiate()
		get_parent().add_child(broken_model_inst)
		broken_model_inst.transform = self.transform
		
		
		await get_tree().create_timer(0.1, false).timeout
		self.queue_free()
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body and body.has_method("take_damage"):
		body.take_damage(global_position)
	if body.name == "Boss":
		if body.health - 20 > 0:
			body.hit(20, body.global_position)
		else:
			body.die(global_position, 5, 3, 4, 1.2)
	elif body and body.has_method("die"):
		body.die(global_position, 5, 3, 4, 1.2)
	if body and body.get_owner() and body.get_owner().has_method("destroy"):
		body.get_owner().destroy(global_position)
	if body is StaticBody3D:
		if body.get_owner().has_method("hit"):
			body.get_owner().hit()
			
func place():
	main.add_barrel(1)
	$CanvasLayer.visible = false
	$StaticBody3D/CollisionShape3D.disabled = false
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

func can_place_barrel() -> bool:
	# Area limits
	if global_position.x < -8 or global_position.x > 11:
		print("Can't place outside X bounds!")
		flash_bounds()
		return false

	if global_position.z < -30 or global_position.z > -5:
		print("Can't place outside Z bounds!")
		flash_bounds()
		return false

	if not can_place_down:
		print("overlap")
		flash_overlap()
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

func cancel_placing():
	player.placing_barrier = false
	queue_free()

func _on_overlap_checker_body_entered(body: Node3D) -> void:
	can_place_down = false


func _on_overlap_checker_body_exited(body: Node3D) -> void:
	can_place_down = true
	
func flash_bounds():
	if bounds_tween and bounds_tween.is_valid():
		return

	bounds_tween = get_tree().create_tween()
	bounds_tween.tween_property($CanvasLayer/OutOfBounds,"modulate",Color(1.0, 0.0, 0.0, 1.0),0.1)

	bounds_tween.tween_property($CanvasLayer/OutOfBounds,"modulate",Color(1.0, 0.0, 0.0, 0.0),2.0)

	await bounds_tween.finished
	bounds_tween = null
	
func flash_overlap():
	if overlap_tween and overlap_tween.is_valid():
		return

	overlap_tween = get_tree().create_tween()
	overlap_tween.tween_property($CanvasLayer/Overlap,"modulate",Color(1.0, 0.0, 0.0, 1.0),0.1)

	overlap_tween.tween_property($CanvasLayer/Overlap,"modulate",Color(1.0, 0.0, 0.0, 0.0),2.0)

	await overlap_tween.finished
	overlap_tween = null
