extends CharacterBody3D

@onready var main = get_tree().get_first_node_in_group("Main")
var dynamite_scene = preload("res://Scenes/dynamite.tscn")
var dynamite_fitted_scene = preload("res://Scenes/dynamite_fitted_image.tscn")

@export var speed: float = 6.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.81
@export var terminal_velocity: float = 55.0
@export var jump_velocity: float = 4.5

@export var health := 100
var money := 0

var duck := false
@onready var capsule: CapsuleShape3D = $CollisionShape3D.shape
var stand_height := 2.0
var duck_height := 1.8

@export var recoil_strength := deg_to_rad(25.0)   
@export var recoil_return_speed := 0.04          

@export var aim_x := 0.0
@export var normal_x := 0.6

@export var pull_speed := 10.0
@export var throw_force: float = 10.0

var recoil_offset := 0.0 
var cocked := true
var cocking := false
var reloading := false

var chamber := [1,1,1,1,1,1]
var chamber_pointer := 0
var free_bullets := 6

var shotgun_in_barrel := 2
var free_shotgun := 6

var dynamite_amount := 3
var dynamite_indicator_targets: Array = []
var dynamite_indicator_close_targets: Array = []
var indicators := {} 

@onready var camera: Camera3D = $Camera3D
@onready var revolver: Node3D = $Camera3D/Revolver
@onready var shotgun: Node3D = $Camera3D/Shotgun

@onready var revolver_ray: RayCast3D = $Camera3D/RevolverRay
@onready var bowie_knife: Node3D = $Camera3D/BowieKnife

@onready var bullet_count: Label = $CanvasLayer/BulletCount
@onready var money_count: Label = $CanvasLayer/MoneyCount

@onready var weapons := [bowie_knife, revolver, shotgun]
var selected_weapon := 1
var switching_weapon := false

var pitch := 0.0

var in_shop := false
var paused = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	RefreshBulletCount()
	RefreshDynamiteCount()


func _unhandled_input(event):
	if event is InputEventMouseMotion and not in_shop:
		rotate_y(-event.relative.x * mouse_sensitivity)

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch
		

	
func pause():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	
		get_tree().paused = !paused


		cocked = paused
		paused = not paused
		
		$CanvasLayer/Pause.visible = paused


func _physics_process(delta: float) -> void:
	# Dynamite indicator 
	# Create missing indicators
	for target in dynamite_indicator_targets:
		if not indicators.has(target):
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://Pictures/DynamiteIcon.png") 
			sprite.scale = Vector2(0.15, 0.15)

			$CanvasLayer/UI_Center.add_child(sprite)
			indicators[target] = sprite
	
	# Remove dead/unused indicators
	for target in indicators.keys():
		if target not in dynamite_indicator_targets or target == null:
			indicators[target].queue_free()
			indicators.erase(target)
	for target in dynamite_indicator_targets:
		if target == null:
			continue

		var sprite = indicators[target]
		sprite.visible = true
		if target in dynamite_indicator_close_targets:
			sprite.modulate = Color(1, 0, 0, 1)
		else:
			sprite.modulate = Color(1, 1, 1, 1)

		$Dynamite_Indicator_LookAt.look_at(
			target.global_transform.origin,
			Vector3.UP
		)

		var angle = -$Dynamite_Indicator_LookAt.rotation.y
		var radius = 1000.0

		var offset = Vector2(sin(angle), -cos(angle)) * radius
		sprite.offset = offset
	
	if not in_shop:
		#Switch weapons
		if Input.is_action_just_pressed("switch_weapon_up") and not switching_weapon and not reloading:
			switch_weapon(1)
			
		if Input.is_action_just_pressed("switch_weapon_down") and not switching_weapon and not reloading:
			switch_weapon(-1)

		
		#Reload
		if Input.is_action_just_pressed("reload") and not reloading and free_bullets > 0 and not switching_weapon and weapons[selected_weapon] != bowie_knife:
			if weapons[selected_weapon] == revolver:
				revolver.reload()
			elif weapons[selected_weapon] == shotgun:
				shotgun.reload()

		
		# Aim
		if not reloading:
			var target_x := aim_x if Input.is_action_pressed("aim") else normal_x
			revolver.position.x = lerp(revolver.position.x, target_x, pull_speed * delta)
			shotgun.position.x = lerp(revolver.position.x, target_x, pull_speed * delta)
			


		# Fire
		if Input.is_action_just_pressed("fire"):
			# Revolver
			if cocked and not cocking and not reloading and not switching_weapon and weapons[selected_weapon] == revolver:
				revolver.fire()


			
			# Knife
			elif not switching_weapon and weapons[selected_weapon] == bowie_knife:
				bowie_knife.slash()
				
			# Shotgun
			elif not switching_weapon and weapons[selected_weapon] == shotgun and shotgun_in_barrel != 0:
				shotgun.fire()


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
		
		if direction != Vector3.ZERO and not $Sounds/StepSound.playing and is_on_floor():
			$Sounds/StepSound.pitch_scale = randf_range(0.7, 1)
			$Sounds/StepSound.play()

		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
			

		# Duck
		if Input.is_action_just_pressed("duck"):
			speed = 3.0

			var tween = get_tree().create_tween()
			tween.tween_property($Camera3D, "position:y", 0.1, 0.15)

			var diff = stand_height - duck_height
			capsule.height = duck_height
			$CollisionShape3D.position.y -= diff / 2.0


		elif Input.is_action_just_released("duck"):
			speed = 6.0

			var tween = get_tree().create_tween()
			tween.tween_property($Camera3D, "position:y", 0.615, 0.15)

			var diff = stand_height - duck_height
			capsule.height = stand_height
			$CollisionShape3D.position.y += diff / 2.0
			
		# Throw
		if Input.is_action_just_pressed("throw") and dynamite_amount > 0:
			dynamite_amount -= 1
			RefreshDynamiteCount()
			var dynamite = dynamite_scene.instantiate()
			var dynamites_container = get_tree().current_scene.get_node("Dynamites")
			dynamites_container.add_child(dynamite)
			
			dynamite.global_transform = $Camera3D.global_transform
			dynamite.rotation_degrees = Vector3(0, 180, 270)
			var forward_dir = -$Camera3D.global_transform.basis.z.normalized()
			dynamite.apply_impulse(forward_dir * throw_force)


	# Interact
	if Input.is_action_just_pressed("interact") and $Camera3D/InteractRay.get_collider() and $Camera3D/InteractRay.get_collider().name == "Shop":
		print("shop")
		$CanvasLayer/Shop.visible = !$CanvasLayer/Shop.visible
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			in_shop = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			in_shop = false

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
	
func RefreshDynamiteCount():
	for i in $CanvasLayer/DynamiteContainer.get_children():
		i.queue_free()
	for i in range(dynamite_amount):
		var dynamite_fitted = dynamite_fitted_scene.instantiate()
		$CanvasLayer/DynamiteContainer.add_child(dynamite_fitted)
	
func AddMoney(amount):
	money += amount
	print(money)
	money_count.text = str(money)
	
	
func switch_weapon(dir):
	switching_weapon = true
	var tween_up = get_tree().create_tween()
	tween_up.tween_property(weapons[selected_weapon], "position", $Camera3D/OffWeaponPos.position, 0.5)
	await tween_up.finished
	weapons[selected_weapon].visible = false
	selected_weapon += dir
	selected_weapon = selected_weapon%len(weapons)
	

	weapons[selected_weapon].visible = true
	var tween_down = get_tree().create_tween()
	tween_down.tween_property(weapons[selected_weapon], "position", $Camera3D/OnWeaponPos.position, 0.5)
	await tween_down.finished
	switching_weapon = false
	
	
func take_damage(enemy_position):
	health -= 5
	$CanvasLayer/HealthBar.value = health
	var indicator := Sprite2D.new()
	indicator.texture = preload("res://Pictures/DamageIndicator.png") 
	indicator.modulate = Color(1, 0, 0, 1) # red
	indicator.scale = Vector2(0.5, 0.5)
	indicator.position = Vector2.ZERO

	$CanvasLayer/UI_Center.add_child(indicator)

	var tween = get_tree().create_tween()
	tween.tween_property(indicator, "modulate:a", 0.0, 0.5)
	tween.tween_callback(indicator.queue_free)
	$Damage_Indicator_LookAt.look_at(enemy_position, Vector3.UP)
	indicator.rotation = -$Damage_Indicator_LookAt.rotation.y


func _on_ammo_pressed() -> void:
	if money >= 1:
		AddMoney(-1)
		free_bullets += 1
		RefreshBulletCount()

func _on_health_pressed() -> void:
	if money >= 1 and health < 100:
		AddMoney(-1)
		health += 5
		$CanvasLayer/HealthBar.value = health


func _on_next_wave_pressed() -> void:
	main.next_wave()

func _on_dynamyte_pressed() -> void:
	if money >= 3:
		AddMoney(-3)
		dynamite_amount += 1
		RefreshDynamiteCount()

func _on_dynamite_close_body_entered(body: Node3D) -> void:
	dynamite_indicator_targets.append(body)

func _on_dynamite_close_body_exited(body: Node3D) -> void:
	dynamite_indicator_targets.erase(body)

func _on_dynamite_deadly_body_entered(body: Node3D) -> void:
	dynamite_indicator_close_targets.append(body)

func _on_dynamite_deadly_body_exited(body: Node3D) -> void:
	dynamite_indicator_close_targets.erase(body)
