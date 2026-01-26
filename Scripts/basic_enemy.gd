extends CharacterBody3D

@onready var enemy_anim: AnimationPlayer = $BasicConnectedDude.get_node("AnimationPlayer")


@export var speed: float = 2.0
@export var rotation_speed: float = 6.0

@onready var skeleton := $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D
@onready var model: Node3D = $BasicConnectedDude


var is_ragdoll := false

@onready var player = get_tree().get_first_node_in_group("Player")

@onready var run_ray: RayCast3D = $RunRay
@onready var aim_ray: RayCast3D = $AimRay



func _physics_process(delta):
	if player == null:
		return

	# Rotate ray to face player (Y axis only)
	var ray_pos = run_ray.global_position
	var player_pos = player.global_position

	var dir = player_pos - ray_pos
	dir.y = 0

	var target_y = atan2(dir.x, dir.z)
	run_ray.global_rotation.y = target_y
	aim_ray.global_rotation.y = target_y
	
	# === Check if player is visible ===
	var sees_player := run_ray.is_colliding() and run_ray.get_collider() == player

	if sees_player:
		
		# Movement direction
		var direction = player.global_position - global_position
		direction.y = 0

		if direction.length() < 0.1:
			velocity = Vector3.ZERO
			move_and_slide()
			return

		direction = direction.normalized()

		# Move the physics body forward
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# Rotate only the model to face player
		var target_rot = Vector3(0, atan2(direction.x, direction.z), 0)
		model.rotation = model.rotation.slerp(target_rot, rotation_speed * delta)
		
		if aim_ray.is_colliding():
			if speed == 2:
				$BasicConnectedDude/AnimationTree.set("parameters/TimeSeek/seek_request", 0)
			
			$BasicConnectedDude/AnimationTree.set("parameters/Blend3/blend_amount", -1)
			
			speed = 1
		else:
			$BasicConnectedDude/AnimationTree.set("parameters/Blend3/blend_amount", 1)
			speed = 2
	else:
		$BasicConnectedDude/AnimationTree.set("parameters/Blend3/blend_amount", 0)
		velocity = Vector3.ZERO

	move_and_slide()
	


func hit(hitbox_type: String):
	print("Hit:", hitbox_type)

	die()
	
func die():
	if is_ragdoll:
		return

	is_ragdoll = true

	# Stop character motion
	velocity = Vector3.ZERO
	global_basis = global_basis.orthonormalized()

	# Stop animations
	enemy_anim.stop()

	# Disable character collision
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
			bone.linear_damp = 4.0
			bone.angular_damp = 6.0
			bone.apply_central_impulse(Vector3.DOWN * 0.5)

	# Stop logic
	set_physics_process(false)

	
