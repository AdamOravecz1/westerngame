extends RigidBody3D

func _on_explosion_effect_range_body_entered(body: Node3D) -> void:
	if body and body.has_method("take_damage"):
		body.take_damage(global_position, 50)
	if body.name == "Boss":
		if body.health - 20 > 0:
			body.hit(20, body.global_position)
		else:
			body.die(global_position, 5, 3, 4, 1.2)
	elif body and body.has_method("die"):
		body.die(global_position, 5, 3, 4, 1.2)
	if body and body.get_owner() and body.get_owner().has_method("destroy"):
		body.get_owner().destroy(global_position)
	if body is StaticBody3D:
		if body.get_owner().has_method("hit"):
			body.get_owner().hit()
