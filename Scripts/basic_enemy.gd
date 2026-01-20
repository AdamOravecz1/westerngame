extends CharacterBody3D

@onready var enemy_anim: AnimationPlayer = $BasicEnemy3.get_node("AnimationPlayer")

@export var speed: float = 2.0
@export var rotation_speed: float = 6.0

@onready var skeleton := $BasicEnemy3/Armature/Skeleton3D/PhysicalBoneSimulator3D

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
	if is_ragdoll:
		apply_ragdoll_impulse(hitbox_type)
	else:
		die()
	
func die():
	if is_ragdoll:
		return

	is_ragdoll = true

	# Stop animations
	enemy_anim.stop()

	# Enable physics on bones
	skeleton.physical_bones_start_simulation()

	# Disable character movement
	set_physics_process(false)
	
func apply_ragdoll_impulse(hitbox_type: String):
	var impulse_dir = -global_basis.z
	impulse_dir.y += 0.8
	impulse_dir = impulse_dir.normalized()

	var impulse_strength := 6.0

	# Try to hit a specific bone (e.g. head), fallback to all
	var bone_name := hitbox_type.capitalize()

	var bone := skeleton.get_node_or_null(bone_name)
	if bone and bone is PhysicalBone3D:
		bone.apply_impulse(impulse_dir * impulse_strength)
	else:
		# Fallback: apply impulse to all bones
		for child in skeleton.get_children():
			if child is PhysicalBone3D:
				child.apply_impulse(impulse_dir * impulse_strength * 0.3)
