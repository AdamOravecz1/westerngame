class_name BasicEnemy
extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@export var health: float = 5
@export var speed: float = 2.0
@export var rotation_speed: float = 6.0
@export var blend_speed := 5.0

var strafe_target: Vector3
var has_strafe_target := false
@export var strafe_radius := 3.0
@export var strafe_reach_distance := 0.5

@onready var skeleton := $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D
@onready var model: Node3D = $BasicConnectedDude

const blood_scene := preload("res://Scenes/blood.tscn")

var is_ragdoll := false

@onready var gun_ray := $BasicConnectedDude/Armature/Skeleton3D/Gun/RayCast3D

var enemies = []

@onready var player = get_tree().get_first_node_in_group("Player")
var sees_player := false
var player_in_range := false
var sees_cover := false
var in_cover := false
var shooting_from_cover := false

var cover_location := Vector3.INF
var hiding_spots = []

func _ready() -> void:
	$Fire.wait_time = randf_range(3.0, 5.0)


func hit(damage, pos):
	var blood_burst = blood_scene.instantiate()
	get_tree().current_scene.add_child(blood_burst)
	blood_burst.global_position = pos
	

	health -= damage
	if health<=0:
		die()
	
func die(from_position: Vector3 = global_position, strength: float = 0.0, l_damp = 6, a_damp = 9, grav = 1):
	player.AddMoney(5)
	if is_ragdoll:
		return

	is_ragdoll = true
	set_physics_process(false)

	velocity = Vector3.ZERO
	global_basis = global_basis.orthonormalized()
	#enemy_anim.stop()
	
	$CoverFinder.queue_free()
	$CoverChecker.queue_free()
	$Fire.stop()

	for bone in $BasicConnectedDude/Armature/Skeleton3D.get_children():
		if bone is BoneAttachment3D:
			for shape in bone.get_children():
				if shape is Area3D:
					shape.monitoring = false
					shape.get_child(0).queue_free()

	# Enable ragdoll
	skeleton.physical_bones_start_simulation()

	# Apply explosion force
	for bone in skeleton.get_children():
		if bone is PhysicalBone3D:
			bone.gravity_scale = grav
			bone.linear_damp = l_damp
			bone.angular_damp = a_damp

			var dir = (bone.global_position - from_position).normalized()
			var impulse = dir * strength

			# optional: add slight upward bias for nicer ragdolls
			impulse.y += strength * 0.1

			bone.apply_central_impulse(impulse * bone.mass)
	

	await get_tree().create_timer(5, false).timeout
	queue_free()
	
func follow_path(where, delta):
	# Move the navigation agent
	navigation_agent_3d.set_target_position(where)
	var destination = navigation_agent_3d.get_next_path_position()
	var direction = (destination - global_position)
	direction.y = 0  # prevent tilting
	direction = direction.normalized()

	# Move the character
	velocity = direction * speed

	# Smooth rotation toward movement direction
	if direction.length() > 0.01:
		
		# Simplest smooth Y rotation
		var target_yaw = atan2(direction.x, direction.z)
		var current_yaw = model.rotation.y
		model.rotation.y = lerp_angle(current_yaw, target_yaw, rotation_speed * delta)

func look_at_player(delta):
		# Look at player
		var look_dir = player.global_position - global_position
		look_dir.y = 0

		if look_dir.length() > 0.01:
			var target_yaw = atan2(look_dir.x, look_dir.z)
			model.rotation.y = lerp_angle(
				model.rotation.y,
				target_yaw,
				rotation_speed * delta
			)


func _on_cover_checker_area_entered(area: Area3D) -> void:
	if area.name.begins_with("HideArea") and area.global_position == cover_location:
		in_cover = true

func _on_cover_checker_area_exited(area: Area3D) -> void:
	if area.name.begins_with("HideArea"):
		#animation_tree.set("parameters/Blend3/blend_amount", -1.0)
		in_cover = false
		shooting_from_cover = false

func _on_cover_finder_area_entered(area: Area3D) -> void:
	if area.name.begins_with("HideArea"):
		hiding_spots.append(area)
		
func _on_cover_finder_area_exited(area: Area3D) -> void:
	if area.name.begins_with("HideArea"):
		hiding_spots.erase(area)
		if area.global_position == cover_location:
			shooting_from_cover = false
		sees_cover = false
		
