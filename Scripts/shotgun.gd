extends Node3D

@onready var player = get_tree().get_first_node_in_group("Player")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var recoil_strength := deg_to_rad(55.0)   

func _ready() -> void:
	$Live.visible = false
	$Dead.visible = false
	$Live_001.visible = false
	$Dead_001.visible = false



func reload():
	if animation_player.current_animation:
		await animation_player.animation_finished
		
	$Live.visible = true
	$Dead.visible = true
	$Live_001.visible = true
	$Dead_001.visible = true
		
	var tween_in := get_tree().create_tween()
	tween_in.parallel().tween_property(self, "position:x", player.normal_x, 0.2)
	
	player.reloading = true
	
	if player.shotgun_in_barrel == 0:
		animation_player.play("LoadBoth")
		player.free_shotgun -= 2
		await animation_player.animation_finished
		animation_player.play("Cock2")
		await animation_player.animation_finished
		animation_player.play("Cock1")
	elif player.shotgun_in_barrel == 1:
		animation_player.play("LoadOne")
		player.free_shotgun -= 1
		await animation_player.animation_finished
		animation_player.play("Cock1")
	player.shotgun_in_barrel = 2

	await animation_player.animation_finished
	
	player.RefreshShotgunCount()
	player.reloading = false
	
	$Live.visible = false
	$Dead.visible = false
	$Live_001.visible = false
	$Dead_001.visible = false
	
func fire():
	if player.shotgun_in_barrel == 2:
		animation_player.play("Fire1")
		await get_tree().process_frame
		await get_tree().process_frame
		sound_n_light($MuzzleFlash)

		
	elif player.shotgun_in_barrel == 1:
		animation_player.play("Fire2")
		await get_tree().process_frame
		await get_tree().process_frame
		sound_n_light($MuzzleFlash2)
		
	for ray in player.shotgun_rays.get_children():
		if ray.is_colliding():
			var collider = ray.get_collider()
			
			var hit_pos = ray.get_collision_point()

			if collider is Area3D:
				var enemy = collider.get_owner()
				if enemy and enemy.has_method("hit"):
					enemy.hit(1, hit_pos)
			if collider is StaticBody3D:
				var enemy = collider.get_owner()
				if enemy and enemy.has_method("hit"):
					enemy.hit()
		
	await get_tree().process_frame

	player.recoil_offset += recoil_strength
	player.shotgun_in_barrel -= 1
	player.RefreshShotgunCount()
	

	
func sound_n_light(light):
	for i in light.get_children():
		i.emitting = true
	$Sounds/FireSound.play()
