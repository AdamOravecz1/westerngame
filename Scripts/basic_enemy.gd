extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var enemy_anim: AnimationPlayer = $BasicConnectedDude.get_node("AnimationPlayer")

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

@onready var player = get_tree().get_first_node_in_group("Player")
var sees_player := false
var player_in_range := false


func _physics_process(delta):
	print(global_position.distance_to(player.global_position))
	if player == null:
		return
	
	var current = $BasicConnectedDude/AnimationTree.get("parameters/Blend3/blend_amount")
	
	if player_in_range:
		if speed == 2:
			$BasicConnectedDude/AnimationTree.set("parameters/TimeSeek/seek_request", 0)
			$Fire.start()
			$PlayerShoot/CollisionShape3D.shape.radius = 10
			speed = 0.5
		#Set animation
		ChangeAnimation(-1.0, current, delta)
		# Pick a new strafe target if needed
		if not has_strafe_target:
			strafe_target = get_random_point_around_self()
			has_strafe_target = true
			navigation_agent_3d.set_target_position(strafe_target)

		# Move toward strafe target
		var destination = navigation_agent_3d.get_next_path_position()
		var direction = destination - global_position
		direction.y = 0

		# If reached → choose another random point
		if direction.length() < strafe_reach_distance:
			has_strafe_target = false
			velocity = Vector3.ZERO
		else:
			direction = direction.normalized()
			velocity = direction * speed
		
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

	
	elif sees_player:
		
		# Set animation
		ChangeAnimation(0.0, current, delta)
		$Fire.stop()
		speed = 2
		has_strafe_target = false
		$PlayerShoot/CollisionShape3D.shape.radius = 8
		
		# Move the navigation agent
		navigation_agent_3d.set_target_position(player.global_position)
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
			
	else:
		# Set animation
		ChangeAnimation(1.0, current, delta)
		
		speed = 0
		velocity = Vector3.ZERO
	

	move_and_slide()


func hit(hitbox_type: String, pos):
	var blood_burst = blood_scene.instantiate()
	get_tree().current_scene.add_child(blood_burst)
	blood_burst.global_position = pos
	
	print("Hit:", hitbox_type)
	if hitbox_type == "Head":
		health -= 100
	elif hitbox_type == "Body":
		health -= 3
	else:
		health -= 1
	if health<=0:
		die()
	
func die():
	if is_ragdoll:
		return

	is_ragdoll = true
	
	# Stop logic
	set_physics_process(false)

	# Stop character motion
	velocity = Vector3.ZERO
	global_basis = global_basis.orthonormalized()

	# Stop animations
	enemy_anim.stop()

	# Disable character collision
	$PlayerSearch.queue_free()
	$PlayerShoot.queue_free()
	$Fire.queue_free()
	$CollisionShape3D.disabled = true
	for bone in $BasicConnectedDude/Armature/Skeleton3D.get_children():
		if bone is BoneAttachment3D:
			for shape in bone.get_children():
				if shape is Area3D:
					shape.monitoring = false
					shape.get_child(0).queue_free()

	# Enable ragdoll
	skeleton.physical_bones_start_simulation()

	# Stabilize bones
	for bone in skeleton.get_children():
		if bone is PhysicalBone3D:
			bone.linear_damp = 6.0
			bone.angular_damp = 9.0
			bone.apply_central_impulse(Vector3.DOWN * 0.5)

	# Stop logic
	set_physics_process(false)
	
func ChangeAnimation(target, current, delta):
	var new_value = lerp(current, target, blend_speed * delta)
	$BasicConnectedDude/AnimationTree.set("parameters/Blend3/blend_amount", new_value)
	
func get_random_point_around_self() -> Vector3:
	# Random angle between -90° and +90°
	var angle = randf_range(-PI * 0.5, PI * 0.5)

	# Forward direction of the enemy
	var forward = model.global_transform.basis.z
	if global_position.distance_to(player.global_position) <= 3:
		forward = -model.global_transform.basis.z

	forward.y = 0
	forward = forward.normalized()

	# Rotate forward vector around Y
	var dir = forward.rotated(Vector3.UP, angle)

	return global_position + dir * strafe_radius



func _on_fire_timeout() -> void:
	$Fire.start()
	$Sounds/FireSound.play()
	$BasicConnectedDude/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	print("fire")


func _on_player_search_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		sees_player = true
		


func _on_player_search_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		sees_player = false


func _on_player_shoot_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = true


func _on_player_shoot_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = false
		
