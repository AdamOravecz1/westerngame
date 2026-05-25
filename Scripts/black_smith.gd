extends Node3D

@onready var nav_mesh = get_tree().get_first_node_in_group("NavigationRegion")
var index = get_index()

func _ready() -> void:
	await get_tree().create_timer(2.0, false).timeout
	if nav_mesh.is_baking():
		await nav_mesh.bake_finished

	nav_mesh.bake_navigation_mesh()
	await nav_mesh.bake_finished
	await get_tree().create_timer(3, false).timeout
