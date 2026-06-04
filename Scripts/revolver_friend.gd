extends RevolverEnemy

@onready var main = get_tree().get_first_node_in_group("Main")

func _ready() -> void:
	for barrier in get_tree().get_nodes_in_group("barrier"):
		barrier.create_friend_checkers()
	model = $BasicConnectedDude
	skeleton = $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D
	remove_from_group("enemy")
	add_to_group("friend")
	looking_for = "enemy"
	
func _process(delta: float) -> void:
	if target_enemy == null:

		var current = animation_tree.get("parameters/Blend3/blend_amount")
		animation_tree.set("parameters/Blend3 2/blend_amount", -1.0)

		ChangeAnimation(0.0, current, delta)

		speed = 2
		has_strafe_target = false

		follow_path(main.friend_wave_point, delta)
		
		if navigation_agent_3d.is_navigation_finished():
			queue_free()
		
		move_and_slide()
	
func delete_after_death():
	for barrier in get_tree().get_nodes_in_group("barrier"):
		barrier.create_friend_checkers()
		
	$CoverFinder.queue_free()
	$CoverChecker.queue_free()
	$CollisionShape3D.queue_free()
	$Fire.stop()


	for bone in $BasicConnectedDude/Armature/Skeleton3D.get_children():
		if bone is BoneAttachment3D:
			for shape in bone.get_children():
				if shape is Area3D:
					shape.monitoring = false
					shape.get_child(0).queue_free
