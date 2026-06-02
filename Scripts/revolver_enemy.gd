extends BasicEnemy
class_name RevolverEnemy

@onready var enemy_anim: AnimationPlayer = $BasicConnectedDude.get_node("AnimationPlayer")
@onready var animation_tree: AnimationTree = $BasicConnectedDude/AnimationTree

@onready var gun_ray := $BasicConnectedDude/Armature/Skeleton3D/Gun/RayCast3D

var target_enemy = null
var looking_for = "friend"


func _ready() -> void:
	add_to_group("enemy")
	if get_script() == preload("res://Scripts/revolver_enemy.gd"):
		for barrier in get_tree().get_nodes_in_group("barrier"):
			barrier.create_enemy_checkers()
	$Fire.wait_time = randf_range(3.0, 5.0)
	skeleton = $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D
	model = $BasicConnectedDude

func _physics_process(delta):

	# Find closest enemy

	var closest_enemy_dist = INF

	for enemy in get_tree().get_nodes_in_group(looking_for):
		if enemy == self:
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_enemy_dist and enemy.health > 0:
			closest_enemy_dist = dist
			target_enemy = enemy

	if target_enemy == null:
		return
		
	print(target_enemy)

	# Aim at target
	var dir = (target_enemy.global_position - $PlayerShoot.global_position + Vector3(0, 1, 0)).normalized()
	if target_enemy == player:
		dir = (target_enemy.global_position - $PlayerShoot.global_position).normalized()

	$PlayerShoot.rotation.y = atan2(dir.x, dir.z)
	$PlayerShoot.rotation.x = asin(-dir.y)

	# Visibility check
	player_in_range = ($PlayerShoot.get_collider() == target_enemy)

	# Gun ray target
	if target_enemy.get_child_count() > 1:
		gun_ray.target_position = gun_ray.to_local(
			target_enemy.get_child(1).global_position
		)

	# Enemy list for cover reservation
	var group = get_groups()
	enemies = get_tree().get_nodes_in_group(group[0])
	enemies.erase(self)

	var closest := INF

	for area in hiding_spots:

		var dist := global_position.distance_to(area.global_position)
		var can_hide_there = true

		for enemy in enemies:
			if enemy.cover_location == area.global_position:
				can_hide_there = false
				break
		
		if group[0] == "enemy":
			if area.name == "HideArea" and not area.get_parent().hide_area_valid:
				can_hide_there = false

			if area.name == "HideArea2" and not area.get_parent().hide_area2_valid:
				can_hide_there = false

		elif group[0] == "friend":
			if area.name == "HideArea3" and not area.get_parent().hide_area3_valid:
				can_hide_there = false

			if area.name == "HideArea4" and not area.get_parent().hide_area4_valid:
				can_hide_there = false

		if (
			can_hide_there
			and dist < closest
			and not in_cover
			and global_position.distance_to(target_enemy.global_position) > 1
			and area.global_position.distance_to(target_enemy.global_position) < 10
		):
			closest = dist
			cover_location = area.global_position
			sees_cover = true
		
		elif closest == INF:
			sees_cover = false


	var current = animation_tree.get("parameters/Blend3/blend_amount")
	var current2 = animation_tree.get("parameters/Blend3 2/blend_amount")
	var current3 = animation_tree.get("parameters/Blend2/blend_amount")
	
	if shooting_from_cover:

		var new_value = lerp(current2, 1.0, blend_speed * delta)
		animation_tree.set("parameters/Blend3 2/blend_amount", new_value)

		var new_value2 = lerp(current3, 1.0, blend_speed * delta)
		animation_tree.set("parameters/Blend2/blend_amount", new_value2)

		look_at_target(target_enemy, delta)
		if name == "RevolverEnemy":
			print("shooting_from_cover")

	elif in_cover and player_in_range:

		ChangeAnimation(-1.0, current, delta)

		var new_value = lerp(current2, 0.0, blend_speed * delta)
		animation_tree.set("parameters/Blend3 2/blend_amount", new_value)

		var new_value2 = lerp(current3, 0.0, blend_speed * delta)
		animation_tree.set("parameters/Blend2/blend_amount", new_value2)

		speed = 0
		velocity = Vector3.ZERO

		look_at_target(target_enemy, delta)
		if name == "RevolverEnemy":
			print("in_cover")

	elif sees_cover and player_in_range:

		ChangeAnimation(0.0, current, delta)

		speed = 2
		has_strafe_target = false

		follow_path(cover_location, delta)
		if name == "RevolverEnemy":
			print("sees_cover")

	elif player_in_range:

		if speed != 0.5:
			animation_tree.set("parameters/TimeSeek/seek_request", 0)
			speed = 0.5

		ChangeAnimation(-1.0, current, delta)

		var new_value = lerp(current2, -1.0, blend_speed * delta)
		animation_tree.set("parameters/Blend3 2/blend_amount", new_value)

		animation_tree.set("parameters/Blend2/blend_amount", 1.0)

		if not has_strafe_target:
			strafe_target = get_random_point_around_self()
			has_strafe_target = true
			navigation_agent_3d.set_target_position(strafe_target)

		var destination = navigation_agent_3d.get_next_path_position()
		var direction = destination - global_position
		direction.y = 0

		if direction.length() < strafe_reach_distance:
			has_strafe_target = false
			velocity = Vector3.ZERO
		else:
			direction = direction.normalized()
			velocity = direction * speed

		look_at_target(target_enemy, delta)
		if name == "RevolverEnemy":
			print("player_in_range")
		

	else:
		animation_tree.set("parameters/Blend3 2/blend_amount", -1.0)

		ChangeAnimation(0.0, current, delta)

		speed = 2
		has_strafe_target = false

		follow_path(target_enemy.global_position, delta)
		if name == "RevolverEnemy":
			print("else", player_in_range)

	move_and_slide()


	
func ChangeAnimation(target, current, delta):
	var new_value = lerp(current, target, blend_speed * delta)
	animation_tree.set("parameters/Blend3/blend_amount", new_value)
	
func get_random_point_around_self() -> Vector3:
	# Random angle between -90° and +90°
	var angle = randf_range(-PI * 0.5, PI * 0.5)

	# Forward direction
	var forward = model.global_transform.basis.z
	if global_position.distance_to(target_enemy.global_position) <= 3:
		forward = -forward

	forward.y = 0
	forward = forward.normalized()

	# Rotate forward vector around Y
	var dir = forward.rotated(Vector3.UP, angle)
	dir.y = 0
	dir = dir.normalized()


	return global_position + dir * strafe_radius


func _on_fire_timeout() -> void:
	$Fire.wait_time = randf_range(3.0, 5.0)
	if animation_tree.get("parameters/Blend3/blend_amount") <= -0.9:
		if in_cover and player_in_range:
			shooting_from_cover = true
			await get_tree().create_timer(1, false).timeout
			if in_cover and health > 0:
				shoot_gun()
				await get_tree().create_timer(1, false).timeout
				shooting_from_cover = false
				#print("shot_from_cover")
			
		elif player_in_range and health > 0:
			shoot_gun()
			#print("just_shot")

		#print("fire")

func _on_cover_checker_area_entered(area: Area3D) -> void:
	if area.name.begins_with("HideArea") and area.global_position == cover_location:
		print("area_entered")
		in_cover = true

func _on_cover_checker_area_exited(area: Area3D) -> void:
	if area.name.begins_with("HideArea"):
		print("area_exited")
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
	
		
func shoot_gun():
	for i in $BasicConnectedDude/Armature/Skeleton3D/Gun/MuzzleFlash.get_children():
		i.emitting = true
	$Sounds/FireSound.play()
	if gun_ray.get_collider() == player:
		player.take_damage(global_position)
	animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
func delete_after_death():
	$CoverFinder.queue_free()
	$CoverChecker.queue_free()
	$Fire.stop()


	for bone in $BasicConnectedDude/Armature/Skeleton3D.get_children():
		if bone is BoneAttachment3D:
			for shape in bone.get_children():
				if shape is Area3D:
					shape.monitoring = false
					shape.get_child(0).queue_free()
					
	if get_script() == preload("res://Scripts/revolver_enemy.gd"):
		for barrier in get_tree().get_nodes_in_group("barrier"):
			barrier.create_enemy_checkers()
