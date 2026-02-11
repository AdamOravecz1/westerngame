extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var enemy_anim: AnimationPlayer = $BasicConnectedDude.get_node("AnimationPlayer")
@onready var animation_tree: AnimationTree = $BasicConnectedDude/AnimationTree

@export var health: float = 5
@export var speed: float = 2.0
@export var rotation_speed: float = 6.0
@export var blend_speed := 5.0

var strafe_target: Vector3
var has_strafe_target := false
@export var strafe_radius := 3.0
@export var strafe_reach_distance := 0.5

@onready var skeleton := $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D
@onready var model: Node3D = $BasicConnectedDude

const blood_scene := preload("res://Scenes/blood.tscn")

var is_ragdoll := false

@onready var gun_ray := $BasicConnectedDude/Armature/Skeleton3D/Gun/RayCast3D

var enemies = []

@onready var player = get_tree().get_first_node_in_group("Player")
var sees_player := false
var player_in_range := false
var sees_cover := false
var in_cover := false
var shooting_from_cover := false

var cover_location := Vector3.INF
var hiding_spots = []

func _ready() -> void:
	$Fire.wait_time = randf_range(3.0, 5.0)

func _physics_process(delta):
	var dir = (player.global_position - $PlayerShoot.global_position).normalized()

	$PlayerShoot.rotation.y = atan2(dir.x, dir.z) # left/right
	$PlayerShoot.rotation.x = asin(-dir.y)        # up/down
	
	if $PlayerShoot.get_collider() == player:
		player_in_range = true
	else:
		player_in_range = false
	
	gun_ray.target_position = gun_ray.to_local(player.get_child(1).global_position)
	enemies = get_tree().current_scene.get_child(0).get_children()
	enemies.erase(self)
	
	var closest := INF

	for area in hiding_spots:
		
		var dist := global_position.distance_to(area.global_position)
		var can_hide_there = true
		for enemy in enemies:
			if enemy.cover_location == area.global_position:
				can_hide_there = false
				break

		if can_hide_there and dist < closest and not in_cover and global_position.distance_to(player.global_position) > 3:
			closest = dist
			cover_location = area.global_position
			sees_cover = true


	var current = animation_tree.get("parameters/Blend3/blend_amount")
	var current2 = animation_tree.get("parameters/Blend3 2/blend_amount")
	var current3 = animation_tree.get("parameters/Blend2/blend_amount")
	
	if shooting_from_cover:
		var new_value = lerp(current2, 1.0, blend_speed * delta)
		animation_tree.set("parameters/Blend3 2/blend_amount", new_value)
		var new_value2 = lerp(current3, 1.0, blend_speed * delta)
		animation_tree.set("parameters/Blend2/blend_amount", new_value2)
		look_at_player(delta)
		#print("shooting_from_cover")
	
	elif in_cover and sees_player:
		ChangeAnimation(-1.0, current, delta)
		#print($BasicConnectedDude/PlayerChecker.get_collider())
		var new_value = lerp(current2, 0.0, blend_speed * delta)
		animation_tree.set("parameters/Blend3 2/blend_amount", new_value)
		var new_value2 = lerp(current3, 0.0, blend_speed * delta)
		animation_tree.set("parameters/Blend2/blend_amount", new_value2)
		
		
		speed = 0
		velocity = Vector3.ZERO
		look_at_player(delta)
		#print("in_cover")

	elif sees_cover and sees_player:
		# Set animation
		ChangeAnimation(0.0, current, delta)
		speed = 2
		has_strafe_target = false
		#$PlayerShoot/CollisionShape3D.shape.radius = 8
		
		follow_path(cover_location, delta)
		#print("sees_cover")
	
	elif player_in_range:
		if speed != 0.5:
			animation_tree.set("parameters/TimeSeek/seek_request", 0)
			#$PlayerShoot/CollisionShape3D.shape.radius = 10
			speed = 0.5
			
		#Set animation
		ChangeAnimation(-1.0, current, delta)
		var new_value = lerp(current2, -1.0, blend_speed * delta)
		animation_tree.set("parameters/Blend3 2/blend_amount", new_value)
		animation_tree.set("parameters/Blend2/blend_amount", 1.0)
		
		# Pick a new strafe target if needed
		if not has_strafe_target:
			strafe_target = get_random_point_around_self()
			has_strafe_target = true
			navigation_agent_3d.set_target_position(strafe_target)

		# Move toward strafe target
		var destination = navigation_agent_3d.get_next_path_position()
		var direction = destination - global_position
		direction.y = 0

		# If reached → choose another random point
		if direction.length() < strafe_reach_distance:
			has_strafe_target = false
			velocity = Vector3.ZERO
		else:
			direction = direction.normalized()
			velocity = direction * speed
			
		look_at_player(delta)
		#print("player_in_range")
		

	elif sees_player:
		
		# Set animation
		ChangeAnimation(0.0, current, delta)
		speed = 2
		has_strafe_target = false
		#$PlayerShoot/CollisionShape3D.shape.radius = 8
		
		follow_path(player.global_position, delta)
		#print("sees_player")
		

			
	else:
		# Set animation
		ChangeAnimation(1.0, current, delta)
		speed = 0
		velocity = Vector3.ZERO
		#print("else")
	move_and_slide()


func hit(hitbox_type: String, pos):
	var blood_burst = blood_scene.instantiate()
	get_tree().current_scene.add_child(blood_burst)
	blood_burst.global_position = pos
	
	print("Hit:", hitbox_type)
	if hitbox_type == "Head":
		health -= 100
	elif hitbox_type == "Body":
		health -= 3
	else:
		health -= 1
	if health<=0:
		die()
	
func die(from_position: Vector3 = global_position, strength: float = 0.0, l_damp = 6, a_damp = 9, grav = 1):
	player.AddMoney(5)
	if is_ragdoll:
		return

	is_ragdoll = true
	set_physics_process(false)

	velocity = Vector3.ZERO
	global_basis = global_basis.orthonormalized()
	enemy_anim.stop()

	$PlayerSearch.queue_free()
	$CoverFinder.queue_free()
	$CoverChecker.queue_free()
	$Fire.stop()

	for bone in $BasicConnectedDude/Armature/Skeleton3D.get_children():
		if bone is BoneAttachment3D:
			for shape in bone.get_children():
				if shape is Area3D:
					shape.monitoring = false
					shape.get_child(0).queue_free()

	# Enable ragdoll
	skeleton.physical_bones_start_simulation()

	# Apply explosion force
	for bone in skeleton.get_children():
		if bone is PhysicalBone3D:
			bone.gravity_scale = grav
			bone.linear_damp = l_damp
			bone.angular_damp = a_damp

			var dir = (bone.global_position - from_position).normalized()
			var impulse = dir * strength

			# optional: add slight upward bias for nicer ragdolls
			impulse.y += strength * 0.1

			bone.apply_central_impulse(impulse * bone.mass)
	

	await get_tree().create_timer(5).timeout
	queue_free()



	
func ChangeAnimation(target, current, delta):
	var new_value = lerp(current, target, blend_speed * delta)
	animation_tree.set("parameters/Blend3/blend_amount", new_value)
	
func get_random_point_around_self() -> Vector3:
	# Random angle between -90° and +90°
	var angle = randf_range(-PI * 0.5, PI * 0.5)

	# Forward direction
	var forward = model.global_transform.basis.z
	if global_position.distance_to(player.global_position) <= 3:
		forward = -forward

	forward.y = 0
	forward = forward.normalized()

	# Rotate forward vector around Y
	var dir = forward.rotated(Vector3.UP, angle)
	dir.y = 0
	dir = dir.normalized()


	return global_position + dir * strafe_radius


	
func follow_path(where, delta):
	# Move the navigation agent
	navigation_agent_3d.set_target_position(where)
	var destination = navigation_agent_3d.get_next_path_position()
	var direction = (destination - global_position)
	direction.y = 0  # prevent tilting
	direction = direction.normalized()

	# Move the character
	velocity = direction * speed

	# Smooth rotation toward movement direction
	if direction.length() > 0.01:
		
		# Simplest smooth Y rotation
		var target_yaw = atan2(direction.x, direction.z)
		var current_yaw = model.rotation.y
		model.rotation.y = lerp_angle(current_yaw, target_yaw, rotation_speed * delta)

func look_at_player(delta):
		# Look at player
		var look_dir = player.global_position - global_position
		look_dir.y = 0

		if look_dir.length() > 0.01:
			var target_yaw = atan2(look_dir.x, look_dir.z)
			model.rotation.y = lerp_angle(
				model.rotation.y,
				target_yaw,
				rotation_speed * delta
			)

func _on_fire_timeout() -> void:
	$Fire.wait_time = randf_range(3.0, 5.0)
	if animation_tree.get("parameters/Blend3/blend_amount") <= -0.9:
		if in_cover and player_in_range:
			shooting_from_cover = true
			await get_tree().create_timer(1).timeout
			if in_cover and health > 0:
				animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				$Sounds/FireSound.play()
				if gun_ray.get_collider() == player:
					player.take_damage(global_position)
				await get_tree().create_timer(1).timeout
				shooting_from_cover = false
				#print("shot_from_cover")
			
		elif player_in_range:
			$Sounds/FireSound.play()
			if gun_ray.get_collider() == player:
				player.take_damage(global_position)
			animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			#print("just_shot")

		#print("fire")


func _on_player_search_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		sees_player = true
		


func _on_player_search_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		sees_player = false

func _on_cover_checker_area_entered(area: Area3D) -> void:
	if area.name.begins_with("HideArea") and area.global_position == cover_location:
		in_cover = true

func _on_cover_checker_area_exited(area: Area3D) -> void:
	if area.name.begins_with("HideArea"):
		animation_tree.set("parameters/Blend3/blend_amount", -1.0)
		in_cover = false
		shooting_from_cover = false

func _on_cover_finder_area_entered(area: Area3D) -> void:
	if area.name.begins_with("HideArea"):
		hiding_spots.append(area)
		
func _on_cover_finder_area_exited(area: Area3D) -> void:
	if area.name.begins_with("HideArea"):
		hiding_spots.erase(area)
		if area.global_position == cover_location:
			shooting_from_cover = false
		sees_cover = false
