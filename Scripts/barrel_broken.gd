extends Node3D

@export var INTENSITY := 8
@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")

func _ready() -> void:
	for pieces: RigidBody3D in self.get_children().slice(0, 46):
		var dir = (pieces.global_position - global_position).normalized()
		pieces.apply_impulse(dir * INTENSITY)
	
	$Sparks.emitting = true
	$Flash.emitting = true
	$Fire.emitting = true
	$Smoke.emitting = true
	

	if nav_mesh.is_baking():
		await get_tree().create_timer(.5, false).timeout

	nav_mesh.bake_navigation_mesh()
	await nav_mesh.bake_finished
	await get_tree().create_timer(3, false).timeout
	
	queue_free()
