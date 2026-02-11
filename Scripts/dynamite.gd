extends RigidBody3D



func _on_explosion_effect_range_area_entered(area: Area3D) -> void:
	
	var barrier = area.get_owner()
	if barrier and barrier.has_method("destroy"):
		barrier.destroy(global_position)


func _on_explosion_effect_range_body_entered(body: Node3D) -> void:
	if body and body.has_method("die"):
		body.die(global_position, 5, 0, 0, 1)
