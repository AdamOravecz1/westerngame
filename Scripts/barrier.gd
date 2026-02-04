extends Node3D

@export var broken_model:PackedScene
@onready var nav_region = get_tree().get_first_node_in_group("NavigationRegion")
@onready var main = get_tree().get_first_node_in_group("Main")




func hit():
	
	var old_parent = self.get_parent()
	old_parent.remove_child(self)  # Remove from current parent
	main.add_child(self)     # Add to new parent
	var broken_model_inst:Node3D = broken_model.instantiate()
	get_parent().add_child(broken_model_inst)
	broken_model_inst.transform = self.transform

	self.queue_free()
	
