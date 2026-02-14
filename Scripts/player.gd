extends CharacterBody3D

@onready var main = get_tree().get_first_node_in_group("Main")
var dynamite_scene = preload("res://Scenes/dynamite.tscn")

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

@export var recoil_strength := deg_to_rad(25.0)   # how hard the kick is
@export var recoil_return_speed := 0.04          # how fast it settles back

@export var aim_x := 0.0
@export var normal_x := 0.6
@export var reload_rotate := 60
@export var normal_rotate := 89
@export var pull_speed := 10.0
@export var throw_force: float = 10.0

var recoil_offset := 0.0 
var cocked := true
var cocking := false
var reloading := false

var chamber := [1,1,1,1,1,1]
var chamber_pointer := 0
var free_bullets := 6

var dynamite_amount := 3
var dynamite_indicator_targets: Array = []
var dynamite_indicator_close_targets: Array = []
var indicators := {} # target -> sprite


@onready var camera: Camera3D = $Camera3D
@onready var revolver: Node3D = $Camera3D/Revolver
@onready var bowie_knife: Node3D = $Camera3D/BowieKnife
@onready var revolver_anim: AnimationPlayer = revolver.get_node("AnimationPlayer")
@onready var cylinder: Node3D = $Camera3D/Revolver/MainCylinder
@onready var live45: Node3D = $"Camera3D/Revolver/45Live"
@onready var dead45: Node3D = $"Camera3D/Revolver/45Dead"
@onready var fakes: Node3D = $Camera3D/Revolver/Fakes
@onready var bullet_count: Label = $CanvasLayer/BulletCount
@onready var money_count: Label = $CanvasLayer/MoneyCount
@onready var dynamite_count: Label = $CanvasLayer/DynamiteCount


@onready var weapons := [bowie_knife, revolver]
var selected_weapon := 1
var switching_weapon := false

var knife_has_hit := false

var pitch := 0.0

var in_shop := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	fakes.visible = false
	dead45.visible = false
	live45.visible = false
	RefreshBulletCount()
	RefreshDynamiteCount()
	


func _unhandled_input(event):
	if event is InputEventMouseMotion and not in_shop:
		rotate_y(-event.relative.x * mouse_sensitivity)

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch
		

	if event.is_action_pressed("cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	
	# Dynamite indicator 
	# Create missing indicators
	for target in dynamite_indicator_targets:
		if not indicators.has(target):
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://Pictures/DynamiteIcon.png") 
			sprite.scale = Vector2(0.25, 0.25)

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
		var radius = 500.0

		var offset = Vector2(sin(angle), -cos(angle)) * radius
		sprite.offset = offset
	
	if not in_shop:
		#Switch weapons
		if Input.is_action_just_pressed("switch_weapon_up") and not switching_weapon and not reloading:
			switch_weapon(1)
			
		if Input.is_action_just_pressed("switch_weapon_down") and not switching_weapon and not reloading:
			switch_weapon(-1)

		
		#Reload
		if Input.is_action_just_pressed("reload") and not reloading and free_bullets > 0 and not switching_weapon and weapons[selected_weapon] == revolver:
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
			live45.visible = true

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
			live45.visible = false
			
		
		# Aim
		if not reloading:
			var target_x := aim_x if Input.is_action_pressed("aim") else normal_x
			revolver.position.x = lerp(revolver.position.x, target_x, pull_speed * delta)


		# Fire
		if Input.is_action_just_pressed("fire"):
			# Revolver
			if cocked and not cocking and not reloading and not switching_weapon and weapons[selected_weapon] == revolver:
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
					if $Camera3D/RayCast3D.is_colliding():
						var collider = $Camera3D/RayCast3D.get_collider()
						var hit_pos = $Camera3D/RayCast3D.get_collision_point()

						if collider is Area3D:
							var enemy = collider.get_owner()
							if enemy and enemy.has_method("hit"):
								enemy.hit(collider.name, hit_pos)
						if collider is CSGBox3D:
							var enemy = collider.get_owner()
							if enemy and enemy.has_method("hit"):
								enemy.hit()
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
			
			# Knife
			elif not switching_weapon and weapons[selected_weapon] == bowie_knife:
				$Camera3D/BowieKnife/AnimationPlayer.play("hit")


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
	dynamite_count.text = str(dynamite_amount)
	
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

func start_knife_swing():
	knife_has_hit = false

func _on_knife_hit_box_area_entered(area: Area3D) -> void:
	if area.get_owner().has_method("hit") and not knife_has_hit:
		knife_has_hit = true
		$Sounds/HitSound.play()
		area.get_owner().hit("UpperArm", area.global_position)


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
