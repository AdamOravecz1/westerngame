extends Node3D
var knife_has_hit = false

func slash():
	$AnimationPlayer.play("hit")

func start_knife_swing():
	knife_has_hit = false

func _on_knife_hit_box_area_entered(area: Area3D) -> void:
	if area.get_owner().has_method("hit") and not knife_has_hit:
		knife_has_hit = true
		$Sounds/HitSound.play()
		area.get_owner().hit(1, area.global_position)
