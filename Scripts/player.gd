extends CharacterBody3D

@export var speed: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.81
@export var terminal_velocity: float = 55.0
@export var jump_velocity: float = 4.5

@export var recoil_strength := deg_to_rad(25.0)   # how hard the kick is
@export var recoil_return_speed := 0.04          # how fast it settles back

var recoil_offset := 0.0


@onready var camera: Camera3D = $Camera3D
@onready var revolver: Node3D = $Camera3D/Revolver
@onready var revolver_anim: AnimationPlayer = revolver.get_node("AnimationPlayer")
@onready var cylinder: Node3D = $Camera3D/Revolver/MainCylinder


var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	# Cock
	if Input.is_action_just_pressed("cock"):
		revolver_anim.play("CockAction")
		var tween = get_tree().create_tween()
		tween.tween_property(cylinder, "rotation_degrees:x", cylinder.rotation_degrees.x + 60, 0.5)


	# Fire
	if Input.is_action_just_pressed("fire"):
		revolver_anim.play("FireAction")
		recoil_offset += recoil_strength
		

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.y = max(velocity.y, -terminal_velocity)
	else:
		if velocity.y < 0:
			velocity.y = 0

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement input
	var input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	# Recoil recovery
	recoil_offset = lerp(recoil_offset, 0.0, recoil_return_speed)
	camera.rotation.x = pitch + recoil_offset


	move_and_slide()
