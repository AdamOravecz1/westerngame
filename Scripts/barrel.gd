extends Node3D

@export var broken_model:PackedScene
@onready var nav_region = get_tree().get_first_node_in_group("NavigationRegion")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var player = get_tree().get_first_node_in_group("Player")

var full := true

func _ready():
	add_to_group("barrier")


func hit():
	if full:
		$Area3D.monitoring = true
		full = false

		visible = false
		var old_parent = self.get_parent()
		old_parent.remove_child(self)  # Remove from current parent
		main.add_child(self)     # Add to new parent
		var broken_model_inst:Node3D = broken_model.instantiate()
		get_parent().add_child(broken_model_inst)
		broken_model_inst.transform = self.transform
		
		
		await get_tree().create_timer(0.1, false).timeout
		self.queue_free()
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body and body.has_method("take_damage"):
		body.take_damage(global_position)
	if body and body.has_method("die"):
		body.die(global_position, 5, 3, 4, 1.2)
	if body and body.get_owner() and body.get_owner().has_method("destroy"):
		body.get_owner().destroy(global_position)
	if body is StaticBody3D:
		if body.get_owner().has_method("hit"):
			body.get_owner().hit()
