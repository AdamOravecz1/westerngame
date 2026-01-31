extends Node3D

@export var broken_model:PackedScene
@onready var nav_region = get_tree().get_first_node_in_group("NavigationRegion")

func hit():
	$CSGBox3D.collision_layer = 0
	$CSGBox3D.collision_mask = 0
	var broken_model_inst:Node3D = broken_model.instantiate()
	get_parent().add_child(broken_model_inst)
	broken_model_inst.transform = self.transform

	self.queue_free()
	

	
