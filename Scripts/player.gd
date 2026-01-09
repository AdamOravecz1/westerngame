extends CharacterBody3D

@export var speed: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.81
@export var terminal_velocity: float = 55.0
@export var jump_velocity: float = 4.5

@export var recoil_strength := deg_to_rad(25.0)   # how hard the kick is
@export var recoil_return_speed := 0.04          # how fast it settles back

@export var aim_x := 0.0
@export var normal_x := 0.6
@export var pull_speed := 10.0

var recoil_offset := 0.0 
var cocked := true
var cocking := false

var rounds := 6

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
	
	# Aim
	var target_x := aim_x if Input.is_action_pressed("aim") else normal_x
	revolver.position.x = lerp(revolver.position.x, target_x, pull_speed * delta)


	# Fire
	if Input.is_action_just_pressed("fire") and cocked and not cocking:
		cocking = true
		cocked = false

		revolver_anim.play("FireAction")
		if rounds > 0:
			rounds -= 1
			recoil_offset += recoil_strength
			$FireSound.play()
		else:
			$DryFireSound.play()

		await revolver_anim.animation_finished

		revolver_anim.play("CockAction")
		$CockSound.play()

		var tween = get_tree().create_tween()
		var length := revolver_anim.get_animation("CockAction").length
		tween.tween_property(cylinder,"rotation_degrees:x",cylinder.rotation_degrees.x + 60,length)

		await revolver_anim.animation_finished
		cocked = true
		cocking = false

		

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
