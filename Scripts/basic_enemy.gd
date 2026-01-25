extends CharacterBody3D

@onready var enemy_anim: AnimationPlayer = $BasicConnectedDude.get_node("AnimationPlayer")

@export var speed: float = 2.0
@export var rotation_speed: float = 6.0

@onready var skeleton := $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D

var is_ragdoll := false

@onready var player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):
	if player == null:
		return

	var direction = player.global_position - global_position
	direction.y = 0

	if direction.length() < 0.1:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	direction = direction.normalized()

	var target_basis = Basis.looking_at(-direction, Vector3.UP)
	global_basis = global_basis.slerp(target_basis, rotation_speed * delta)

	var forward = global_basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

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

	
