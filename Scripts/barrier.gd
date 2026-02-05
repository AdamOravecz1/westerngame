extends Node3D

@export var broken_model:PackedScene
@onready var nav_region = get_tree().get_first_node_in_group("NavigationRegion")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var player = get_tree().get_first_node_in_group("Player")

func _process(delta: float) -> void:
	$PlayerChecker.look_at(player.global_position, Vector3.UP)
	$PlayerChecker2.look_at(player.global_position, Vector3.UP)
	if $PlayerChecker.get_collider() == $Barrier and Vector2($HideArea.global_position.x, $HideArea.global_position.z) \
	.distance_to(Vector2(player.global_position.x, player.global_position.z)) >= 3:

		if snapped($HideArea.position.y, 0.01) == 100.05:
			$HideArea.position.y -= 100
	else:

		if snapped($HideArea.position.y, 0.01) == 0.05:
			$HideArea.position.y += 100

	if $PlayerChecker2.get_collider() == $Barrier and Vector2($HideArea2.global_position.x, $HideArea2.global_position.z) \
	.distance_to(Vector2(player.global_position.x, player.global_position.z)) >= 3:
		if snapped($HideArea2.position.y, 0.001) == 100.05:
			$HideArea2.position.y -= 100
	else: 
		if snapped($HideArea2.position.y, 0.001) == 0.05:
			$HideArea2.position.y += 100


func hit():
	var old_parent = self.get_parent()
	old_parent.remove_child(self)  # Remove from current parent
	main.add_child(self)     # Add to new parent
	var broken_model_inst:Node3D = broken_model.instantiate()
	get_parent().add_child(broken_model_inst)
	broken_model_inst.transform = self.transform

	self.queue_free()
	
