extends Node3D

@export var broken_model:PackedScene
@onready var nav_region = get_tree().get_first_node_in_group("NavigationRegion")
@onready var main = get_tree().get_first_node_in_group("Main")

var occupied1 := false
var occupied2 := false



func hit():
	
	var old_parent = self.get_parent()
	old_parent.remove_child(self)  # Remove from current parent
	main.add_child(self)     # Add to new parent
	var broken_model_inst:Node3D = broken_model.instantiate()
	get_parent().add_child(broken_model_inst)
	broken_model_inst.transform = self.transform

	self.queue_free()
	


func _on_hide_area_body_entered(body: Node3D) -> void:
	if body.name == "BasicEnemy":
		occupied1 = true
	#print("occupied 1 = ", occupied1)


func _on_hide_area_body_exited(body: Node3D) -> void:
	if body.name == "BasicEnemy":
		occupied1 = false
	#print("occupied 1 = ", occupied1)


func _on_hide_area_2_body_entered(body: Node3D) -> void:
	if body.name == "BasicEnemy":
		occupied2 = true
	#print("occupied 2 = ", occupied2)


func _on_hide_area_2_body_exited(body: Node3D) -> void:
	if body.name == "BasicEnemy":
		occupied2 = false
	#print("occupied 2 = ", occupied2)
