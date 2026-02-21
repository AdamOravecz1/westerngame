extends Node3D

@onready var player = get_tree().get_first_node_in_group("Player")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var recoil_strength := deg_to_rad(45.0)   



func reload():
	if animation_player.current_animation:
		await animation_player.animation_finished
		
	$Live.visible = true
	$Live_001.visible = true
	$Dead.visible = true
	$Dead_001.visible = true
	
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
	$Live.visible = false
	$Live_001.visible = false
	$Dead.visible = false
	$Dead_001.visible = false
	await animation_player.animation_finished
	

	
	player.reloading = false
	
func fire():

	if player.shotgun_in_barrel == 2:
		animation_player.play("Fire1")
		for i in $MuzzleFlash.get_children():
			i.emitting = true
		
	elif player.shotgun_in_barrel == 1:
		animation_player.play("Fire2")
		for i in $MuzzleFlash2.get_children():
			i.emitting = true
	await get_tree().process_frame
	await get_tree().process_frame
	$Sounds/FireSound.play()
	#await get_tree().process_frame

	player.recoil_offset += recoil_strength
	player.shotgun_in_barrel -= 1
		
	
