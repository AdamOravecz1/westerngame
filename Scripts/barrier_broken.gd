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
	await  get_tree().create_timer(5, false).timeout
	
	fade_out()

func fade_out():
	var meshes = find_children("*", "MeshInstance3D", true, false)
	var tween = create_tween()

	for mesh in meshes:
		var material = mesh.get_active_material(0)

		if material:
			material = material.duplicate()
		else:
			material = StandardMaterial3D.new()

		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
		mesh.material_override = material

		tween.parallel().tween_property(material, "albedo_color:a", 0.0, 1.5)

	await tween.finished
	queue_free()
