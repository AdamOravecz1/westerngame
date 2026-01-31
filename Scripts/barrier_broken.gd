extends Node3D

@export var INTENSITY := 4
@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")

func _ready() -> void:
	for pieces:RigidBody3D in self.get_children():
		pieces.apply_impulse(pieces.get_child(0).position * INTENSITY, self.global_position)
	
	await get_tree().create_timer(1.5).timeout
	
	nav_mesh.bake_navigation_mesh()
	await  get_tree().create_timer(1.5).timeout
	
	queue_free()
