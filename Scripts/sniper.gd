extends Node3D

@export var headshot := 100
@export var torsoshot := 100
@export var limbshot := 4

@onready var player = get_tree().get_first_node_in_group("Player")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var recoil_strength := deg_to_rad(55.0)   

func reload():
	animation_player.play("Open")
	await animation_player.animation_finished
	while player.free_sniper > 0 and player.sniper_in_clip < 5:
		animation_player.play("In")
		await animation_player.animation_finished
		player.free_sniper -= 1
		player.sniper_in_clip += 1
	animation_player.play("Close")
	await animation_player.animation_finished
	if player.sniper_in_chamber == 0:
		player.sniper_in_clip -= 1
		player.sniper_in_chamber += 1
	print("in_chamber: ", player.sniper_in_chamber, " in_clip: ", player.sniper_in_clip, " free: ", player.free_sniper)

func fire():
	animation_player.play("Fire")
	#sound_n_light($MuzzleFlash)
		
	if player.revolver_ray.is_colliding():
		var collider = player.revolver_ray.get_collider()

		var damage = 0
		if collider.name == "Head":
			damage = headshot
		elif collider.name == "Body":
			damage = torsoshot
		else:
			damage = limbshot
		
		var hit_pos = player.revolver_ray.get_collision_point()

		if collider is Area3D:
			var enemy = collider.get_owner()
			if enemy and enemy.has_method("hit"):
				enemy.hit(damage, hit_pos)
				
		if collider is StaticBody3D:
			var enemy = collider.get_owner()
			if enemy and enemy.has_method("hit"):
				enemy.hit()
		

	player.recoil_offset += recoil_strength
	player.sniper_in_chamber -= 1
	
	await animation_player.animation_finished
	animation_player.play("Open")
	await animation_player.animation_finished
	animation_player.play("Out")
	await animation_player.animation_finished
	animation_player.play("Close")
	await animation_player.animation_finished
	
	if player.sniper_in_clip > 0:
		player.sniper_in_chamber += 1
		player.sniper_in_clip -= 1
	print("in_chamber: ", player.sniper_in_chamber, " in_clip: ", player.sniper_in_clip, " free: ", player.free_sniper)
	
	#player.RefreshShotgunCount()
