extends Node3D

@onready var player = get_tree().get_first_node_in_group("Player")

@onready var revolver_anim = $AnimationPlayer

@export var reload_rotate := 60
@export var normal_rotate := 89

@export var recoil_strength := deg_to_rad(25.0)   

@export var headshot := 100
@export var torsoshot := 3
@export var limbshot := 1

@onready var cylinder: Node3D = $MainCylinder
@onready var live45: Node3D = $"45Live"
@onready var dead45: Node3D = $"45Dead"
@onready var fakes: Node3D = $Fakes




func _ready() -> void:
	fakes.visible = false
	dead45.visible = false
	live45.visible = false

func reload():
	if revolver_anim.current_animation:
		await revolver_anim.animation_finished
	player.reloading = true
	var cylinder_length = revolver_anim.get_animation("CockAction").length
	var length := 0.2
	
	var tween_in := get_tree().create_tween()
	tween_in.parallel().tween_property(self, "position:x", player.aim_x, length)
	tween_in.parallel().tween_property(self, "rotation_degrees:x", reload_rotate, length)
	tween_in.parallel().tween_property(fakes,"rotation_degrees:x",fakes.rotation_degrees.x + 60,cylinder_length)
	
	await tween_in.finished
	fakes.visible = true
	dead45.visible = true
	live45.visible = true

	revolver_anim.play("OpenAction")
	$Sounds/HalfDeCockSound.play()
	await revolver_anim.animation_finished

	
	while player.chamber.reduce(func(a, b): return a + b, 0) != 6 and player.free_bullets > 0:
		if player.chamber[player.chamber_pointer%6 - 1] == 0:
			revolver_anim.play("LoadAction")
			$Sounds/ReloadSound.play()
			player.free_bullets -= 1
			player.chamber[player.chamber_pointer%6 - 1] = 1
			player.chamber_pointer -= 1
			player.RefreshBulletCount()

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
	tween_out.parallel().tween_property(self, "position:x", player.normal_x, length)
	tween_out.parallel().tween_property(self, "rotation_degrees:x", normal_rotate, length)
	await tween_out.finished

	player.reloading = false
	fakes.visible = false
	dead45.visible = false
	live45.visible = false
	
func fire():
	player.cocking = true
	player.cocked = false

	revolver_anim.play("FireAction")
	if player.chamber[player.chamber_pointer%6] == 1:


		await get_tree().process_frame
		await get_tree().process_frame
		for i in $MuzzleFlash.get_children():
			i.emitting = true

		$Sounds/FireSound.play()
		await get_tree().process_frame
		player.chamber[player.chamber_pointer%6] = 0
		player.recoil_offset += recoil_strength

		
		player.chamber_pointer += 1
		player.RefreshBulletCount()
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

	else:
		$Sounds/DryFireSound.play()
		player.chamber_pointer += 1

	await revolver_anim.animation_finished

	revolver_anim.play("CockAction")
	$Sounds/CockSound.play()

	var tween = get_tree().create_tween()
	var length = revolver_anim.get_animation("CockAction").length
	tween.tween_property(cylinder,"rotation_degrees:x",cylinder.rotation_degrees.x - 60,length)

	await revolver_anim.animation_finished
	player.cocked = true
	player.cocking = false
