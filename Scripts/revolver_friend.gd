extends RevolverEnemy

func _ready() -> void:
	for barrier in get_tree().get_nodes_in_group("barrier"):
		barrier.create_friend_checkers()
	model = $BasicConnectedDude
	skeleton = $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D
	remove_from_group("enemy")
	add_to_group("friend")
	looking_for = "enemy"
	
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
