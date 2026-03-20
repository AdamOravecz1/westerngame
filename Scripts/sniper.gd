extends Node3D

@export var headshot := 100
@export var torsoshot := 100
@export var limbshot := 4

@onready var player = get_tree().get_first_node_in_group("Player")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var recoil_strength := deg_to_rad(55.0)   

func _ready() -> void:
	$Live.visible = false
	$LiveAmmo.visible = false
	$Dead.visible = false

func reload():
	if animation_player.current_animation:
		await animation_player.animation_finished
	var tween_in := get_tree().create_tween()
	tween_in.parallel().tween_property(self, "position:x", player.normal_x, 0.2)
	player.reloading = true

	animation_player.play("Open")
	await animation_player.animation_finished
	$Live.visible = true
	$LiveAmmo.visible = true
	while player.free_sniper > 0 and player.sniper_in_clip < 5:
		animation_player.play("In")
		await animation_player.animation_finished
		player.free_sniper -= 1
		player.sniper_in_clip += 1
		player.RefreshSniperCount()
	$Live.visible = false
	$LiveAmmo.visible = false
	animation_player.play("Close")
	await animation_player.animation_finished
	player.reloading = false
	if player.sniper_in_chamber == 0:
		player.sniper_in_clip -= 1
		player.sniper_in_chamber += 1
		player.RefreshSniperCount()
	

	#print("in_chamber: ", player.sniper_in_chamber, " in_clip: ", player.sniper_in_clip, " free: ", player.free_sniper)

func fire():
	animation_player.play("Fire")
	for i in $MuzzleFlash.get_children():
		i.emitting = true
		
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
	player.RefreshSniperCount()

	$Dead.visible = true
	
	await animation_player.animation_finished
	animation_player.play("Open")
	await animation_player.animation_finished
	animation_player.play("Out")
	await animation_player.animation_finished
	animation_player.play("Close")
	await animation_player.animation_finished

	$Dead.visible = false

	if player.sniper_in_clip > 0:
		player.sniper_in_chamber += 1
		player.sniper_in_clip -= 1
	#print("in_chamber: ", player.sniper_in_chamber, " in_clip: ", player.sniper_in_clip, " free: ", player.free_sniper)
	
