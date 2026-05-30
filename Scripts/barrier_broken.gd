extends Node3D

@export var INTENSITY := 4
@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")

func _ready() -> void:
	for pieces:RigidBody3D in self.get_children().slice(0, 30):
		pieces.apply_impulse(pieces.get_child(0).position * INTENSITY, self.global_position)
	

	if nav_mesh.is_baking():
		await nav_mesh.bake_finished

	nav_mesh.bake_navigation_mesh()
	await nav_mesh.bake_finished
	await  get_tree().create_timer(3, false).timeout
	
	queue_free()
