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
@export var reload_rotate := 60
@export var normal_rotate := 89
@export var pull_speed := 10.0

var recoil_offset := 0.0 
var cocked := true
var cocking := false
var reloading := false

var chamber := [1,1,1,1,1,1]
var chamber_pointer := 0
var free_bullets := 6

@onready var camera: Camera3D = $Camera3D
@onready var revolver: Node3D = $Camera3D/Revolver
@onready var revolver_anim: AnimationPlayer = revolver.get_node("AnimationPlayer")
@onready var cylinder: Node3D = $Camera3D/Revolver/MainCylinder
@onready var live45: Node3D = $"Camera3D/Revolver/45Live"
@onready var dead45: Node3D = $"Camera3D/Revolver/45Dead"
@onready var fakes: Node3D = $Camera3D/Revolver/Fakes
@onready var bullet_count: Label = $CanvasLayer/BulletCount

var pitch := 0.0

func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	fakes.visible = false
	dead45.visible = false
	RefreshBulletCount()
	
	
	

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch


func _physics_process(delta: float) -> void:
	#Reload
	if Input.is_action_just_pressed("reload") and not reloading and free_bullets > 0:
		if revolver_anim.current_animation:
			await revolver_anim.animation_finished
		reloading = true
		var cylinder_length := revolver_anim.get_animation("CockAction").length
		var length := 0.2
		
		var tween_in := get_tree().create_tween()
		tween_in.parallel().tween_property(revolver, "position:x", aim_x, length)
		tween_in.parallel().tween_property(revolver, "rotation_degrees:x", reload_rotate, length)
		tween_in.parallel().tween_property(fakes,"rotation_degrees:x",fakes.rotation_degrees.x + 60,cylinder_length)
		
		await tween_in.finished
		fakes.visible = true
		dead45.visible = true

		revolver_anim.play("OpenAction")
		$Sounds/HalfDeCockSound.play()
		await revolver_anim.animation_finished

		
		while chamber.reduce(func(a, b): return a + b, 0) != 6 and free_bullets > 0:
			if chamber[chamber_pointer%6 - 1] == 0:
				revolver_anim.play("LoadAction")
				$Sounds/ReloadSound.play()
				free_bullets -= 1
				chamber[chamber_pointer%6 - 1] = 1
				chamber_pointer -= 1
				RefreshBulletCount()
				print(chamber)
				print(chamber_pointer)
				await revolver_anim.animation_finished
			
			var tween = get_tree().create_tween()
			tween.parallel().tween_property(cylinder,"rotation_degrees:x",cylinder.rotation_degrees.x + 60,cylinder_length)
			tween.parallel().tween_property(fakes,"rotation_degrees:x",fakes.rotation_degrees.x + 60,cylinder_length)
			tween.parallel().tween_property(live45,"rotation_degrees:x",live45.rotation_degrees.x + 60,cylinder_length)
			await tween.finished
			fakes.rotation_degrees.x = 60
			live45.rotation_degrees.x = 0
			


			

		revolver_anim.play("CloseAction")
		$Sounds/HalfCockSound.play()
		await revolver_anim.animation_finished

		var tween_out := get_tree().create_tween()
		tween_out.parallel().tween_property(revolver, "position:x", normal_x, length)
		tween_out.parallel().tween_property(revolver, "rotation_degrees:x", normal_rotate, length)
		await tween_out.finished

		reloading = false
		fakes.visible = false
		dead45.visible = false
		
	
	# Aim
	if not reloading:
		var target_x := aim_x if Input.is_action_pressed("aim") else normal_x
		revolver.position.x = lerp(revolver.position.x, target_x, pull_speed * delta)


	# Fire
	if Input.is_action_just_pressed("fire") and cocked and not cocking and not reloading:
		cocking = true
		cocked = false

		revolver_anim.play("FireAction")
		if chamber[chamber_pointer%6] == 1:
			await get_tree().create_timer(0.04).timeout
			chamber[chamber_pointer%6] = 0
			recoil_offset += recoil_strength
			$Sounds/FireSound.play()
			chamber_pointer += 1
			RefreshBulletCount()
		else:
			$Sounds/DryFireSound.play()
			chamber_pointer += 1

		await revolver_anim.animation_finished

		revolver_anim.play("CockAction")
		$Sounds/CockSound.play()

		var tween = get_tree().create_tween()
		var length := revolver_anim.get_animation("CockAction").length
		tween.tween_property(cylinder,"rotation_degrees:x",cylinder.rotation_degrees.x - 60,length)

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
	
	if direction != Vector3.ZERO and not $Sounds/StepSound.playing:
		$Sounds/StepSound.pitch_scale = randf_range(0.7, 1)
		$Sounds/StepSound.play()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	# Recoil recovery
	recoil_offset = lerp(recoil_offset, 0.0, recoil_return_speed)
	camera.rotation.x = pitch + recoil_offset
	
	# Debug Add Bullet:
	if Input.is_action_just_pressed("addbullet"):
		free_bullets += 1
		RefreshBulletCount()


	move_and_slide()

func RefreshBulletCount():
	bullet_count.text = str(free_bullets) + "/" + str(chamber.reduce(func(a, b): return a + b, 0))
