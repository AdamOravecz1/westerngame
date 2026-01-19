extends CharacterBody3D

@onready var enemy_anim: AnimationPlayer = $BasicEnemy2.get_node("AnimationPlayer")

@export var speed: float = 2.0
@export var rotation_speed: float = 6.0

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

	# 🔥 IMPORTANT: invert direction for rotation
	var target_basis = Basis.looking_at(-direction, Vector3.UP)
	global_basis = global_basis.slerp(target_basis, rotation_speed * delta)

	# 🔥 Mesh forward is +Z
	var forward = global_basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

	move_and_slide()


func hit(hitbox_type: String):
	print("Hit:", hitbox_type)
