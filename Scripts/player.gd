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

@export var recoil_return_speed := 0.04          

@export var aim_x := 0.0
@export var normal_x := 0.6

@export var pull_speed := 10.0
@export var normal_fov := 75.0
@export var zoom_fov := 30.0
@export var zoom_speed := 10.0
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

var sniper_in_clip := 5
var sniper_in_chamber := 1
var free_sniper := 10

var dynamite_amount := 3
var dynamite_indicator_targets: Array = []
var dynamite_indicator_close_targets: Array = []
var indicators := {} 

@onready var camera: Camera3D = $Camera3D
@onready var revolver: Node3D = $Camera3D/Revolver
@onready var shotgun: Node3D = $Camera3D/Shotgun
@onready var sniper: Node3D = $Camera3D/Sniper

@onready var revolver_ray: RayCast3D = $Camera3D/RevolverRay
@onready var shotgun_rays: Node3D = $Camera3D/ShotgunRays
@onready var bowie_knife: Node3D = $Camera3D/BowieKnife

@onready var bullet_count: Label = $CanvasLayer/BulletCount
@onready var shotgun_count: Label = $CanvasLayer/ShotgunCount
@onready var sniper_count: Label = $CanvasLayer/SniperCount
@onready var money_count: Label = $CanvasLayer/MoneyCount

@onready var weapons := [bowie_knife, revolver, shotgun, sniper]
var weapon_unlocked := {
	"knife": true,
	"revolver": true,
	"shotgun": false,
	"sniper": false
}
var selected_weapon := 1
var switching_weapon := false

var pitch := 0.0

var cover_location := Vector3.ZERO

var in_shop := false
var placing_barrier := false
var paused = false

func _ready():
	add_to_group("friend")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	RefreshBulletCount()
	RefreshShotgunCount()
	RefreshSniperCount()
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
			
		if Input.is_action_just_pressed("one") and not switching_weapon and not reloading:
			switch_weapon(-(selected_weapon))
		if Input.is_action_just_pressed("two") and not switching_weapon and not reloading:
			switch_weapon(-(selected_weapon-1))
		if Input.is_action_just_pressed("three") and not switching_weapon and not reloading and weapon_unlocked["shotgun"]:
			switch_weapon(-(selected_weapon-2))
		if Input.is_action_just_pressed("four") and not switching_weapon and not reloading and weapon_unlocked["sniper"]:
			switch_weapon(-(selected_weapon-3))
		


		
		#Reload
		if Input.is_action_just_pressed("reload") and not reloading and not switching_weapon and weapons[selected_weapon] != bowie_knife:
			if weapons[selected_weapon] == revolver and free_bullets > 0:
				revolver.reload()
			elif weapons[selected_weapon] == shotgun and shotgun_in_barrel != 2 and free_shotgun > 0:
				shotgun.reload()
			elif weapons[selected_weapon] == sniper and sniper_in_clip != 5 and free_sniper > 0:
				sniper.reload()

		
		# Aim
		if not reloading:
			var target_x := aim_x if Input.is_action_pressed("aim") else normal_x

			revolver.position.x = lerp(revolver.position.x, target_x, pull_speed * delta)
			shotgun.position.x = lerp(shotgun.position.x, target_x, pull_speed * delta)
			sniper.position.x = lerp(sniper.position.x, target_x, pull_speed * delta)

		# Sniper aim
		var is_aiming: bool = Input.is_action_pressed("aim") and not reloading

		var target_fov := zoom_fov if (is_aiming and weapons[selected_weapon] == sniper) else normal_fov
		$Camera3D.fov = lerp($Camera3D.fov, target_fov, pull_speed * delta)

		var target_crosshair_alpha := 1.0 if (is_aiming and weapons[selected_weapon] == sniper) else 0.0
		$CanvasLayer/CrossHair.modulate.a = lerp($CanvasLayer/CrossHair.modulate.a, target_crosshair_alpha, pull_speed * delta)

		if weapons[selected_weapon] == sniper:
			var target_alpha := 0.0 if is_aiming else 1.0
			sniper.set_transparency(target_alpha, pull_speed, delta)


		# Fire
		if Input.is_action_just_pressed("fire") and not placing_barrier:
			# Revolver
			if cocked and not cocking and not reloading and not switching_weapon and weapons[selected_weapon] == revolver:
				revolver.fire()


			
			# Knife
			elif not switching_weapon and weapons[selected_weapon] == bowie_knife:
				bowie_knife.slash()
				
			# Shotgun
			elif not switching_weapon and weapons[selected_weapon] == shotgun and shotgun_in_barrel != 0:
				shotgun.fire()
				
			# Sniper
			elif not switching_weapon and weapons[selected_weapon] == sniper and sniper_in_chamber != 0:
				sniper.fire()




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
		if Input.is_action_just_pressed("duck") and not placing_barrier and not duck:
			duck = true
			speed = 3.0

			var tween = get_tree().create_tween()
			tween.tween_property($Camera3D, "position:y", 0.1, 0.15)

			var diff = stand_height - duck_height
			capsule.height = duck_height
			$CollisionShape3D.position.y -= diff / 2.0


		elif Input.is_action_just_released("duck") and not placing_barrier and duck:
			duck = false
			speed = 6.0

			var tween = get_tree().create_tween()
			tween.tween_property($Camera3D, "position:y", 0.615, 0.15)

			var diff = stand_height - duck_height
			capsule.height = stand_height
			$CollisionShape3D.position.y += diff / 2.0
			
		# Throw
		if Input.is_action_just_pressed("throw") and dynamite_amount > 0 and not placing_barrier:
			dynamite_amount -= 1
			RefreshDynamiteCount()
			var dynamite = dynamite_scene.instantiate()
			var dynamites_container = get_tree().current_scene.get_node_or_null("Dynamites")

			if dynamites_container:
				dynamites_container.add_child(dynamite)
			
			dynamite.global_transform = $Camera3D.global_transform
			dynamite.rotation_degrees = Vector3(0, 180, 270)
			var forward_dir = -$Camera3D.global_transform.basis.z.normalized()
			dynamite.apply_impulse(forward_dir * throw_force)
			
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.y = max(velocity.y, -terminal_velocity)
	else:
		if velocity.y < 0:
			velocity.y = 0

	# Interact
	if $Camera3D/InteractRay.get_collider() and not in_shop and not placing_barrier:
		if $Camera3D/InteractRay.get_collider().name == "Foundation" or $Camera3D/InteractRay.get_collider().name.begins_with("Menu"):
			$CanvasLayer/InteractIndicator.visible = true
	else:
		$CanvasLayer/InteractIndicator.visible = false
	if Input.is_action_just_pressed("interact") and $Camera3D/InteractRay.get_collider() and $Camera3D/InteractRay.get_collider().name == "Foundation" and not placing_barrier:
		$CanvasLayer/ShopMenu.shop($Camera3D/InteractRay.get_collider().get_parent())
		velocity.x = 0
		velocity.z = 0
		
	if Input.is_action_just_pressed("interact") and $Camera3D/InteractRay.get_collider() and $Camera3D/InteractRay.get_collider().name.begins_with("Menu") and not placing_barrier:
		$Camera3D/InteractRay.get_collider().get_parent().menu()
		velocity.x = 0
		velocity.z = 0

	# Recoil recovery
	recoil_offset = lerp(recoil_offset, 0.0, recoil_return_speed)
	camera.rotation.x = pitch + recoil_offset
	

	move_and_slide()

func RefreshBulletCount():
	bullet_count.text = str(free_bullets) + "/" + str(chamber.reduce(func(a, b): return a + b, 0))
	
func RefreshShotgunCount():
	shotgun_count.text = str(free_shotgun) + "/" + str(shotgun_in_barrel)
	
func RefreshSniperCount():
	sniper_count.text = str(free_sniper) + "/" + str(sniper_in_chamber + sniper_in_clip)
	
func DisplayCorrectAmmoType():
	bullet_count.visible = false
	shotgun_count.visible = false
	sniper_count.visible = false
	if weapons[selected_weapon] == revolver:
		bullet_count.visible = true
	elif weapons[selected_weapon] == shotgun:
		shotgun_count.visible = true
	elif weapons[selected_weapon] == sniper:
		sniper_count.visible = true
	
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
	selected_weapon = get_next_unlocked_weapon(selected_weapon, dir)
	

	weapons[selected_weapon].visible = true
	var tween_down = get_tree().create_tween()
	tween_down.tween_property(weapons[selected_weapon], "position", $Camera3D/OnWeaponPos.position, 0.5)
	await tween_down.finished
	switching_weapon = false
	DisplayCorrectAmmoType()
	
	
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

func _on_dynamite_close_body_entered(body: Node3D) -> void:
	dynamite_indicator_targets.append(body)

func _on_dynamite_close_body_exited(body: Node3D) -> void:
	dynamite_indicator_targets.erase(body)

func _on_dynamite_deadly_body_entered(body: Node3D) -> void:
	dynamite_indicator_close_targets.append(body)

func _on_dynamite_deadly_body_exited(body: Node3D) -> void:
	dynamite_indicator_close_targets.erase(body)

func _on_shutgun_ammo_pressed() -> void:
	if money >= 1:
		AddMoney(-1)
		free_shotgun += 1
		RefreshShotgunCount()

func teleport(pos, rot):
	in_shop = true
	var tween = get_tree().create_tween()
	tween.tween_property($CanvasLayer/ColorRect, "modulate", Color(1,1,1,1), 0.5)
	await tween.finished
	global_position = pos
	rotation = rot
	var tween2 = get_tree().create_tween()
	tween2.tween_property($CanvasLayer/ColorRect, "modulate", Color(1,1,1,0), 0.5)
	await tween2.finished
	in_shop = false

func get_next_unlocked_weapon(start_index: int, dir: int) -> int:
	var idx = start_index

	for i in range(len(weapons)):
		idx = (idx + dir) % len(weapons)
		if idx < 0:
			idx = len(weapons) - 1

		var w = weapons[idx]

		if w == bowie_knife and weapon_unlocked["knife"]:
			return idx
		elif w == revolver and weapon_unlocked["revolver"]:
			return idx
		elif w == shotgun and weapon_unlocked["shotgun"]:
			return idx
		elif w == sniper and weapon_unlocked["sniper"]:
			return idx

	return start_index
	
func unlock_shotgun():
	if weapon_unlocked["shotgun"]:
		return
	weapon_unlocked["shotgun"] = true

func unlock_sniper():
	if weapon_unlocked["sniper"]:
		return
	weapon_unlocked["sniper"] = true
