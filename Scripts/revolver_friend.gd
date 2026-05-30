extends RevolverEnemy



func _ready() -> void:
	model = $BasicConnectedDude
	skeleton = $BasicConnectedDude/Armature/Skeleton3D/PhysicalBoneSimulator3D
	remove_from_group("enemy")
	add_to_group("friend")
	looking_for = "enemy"
