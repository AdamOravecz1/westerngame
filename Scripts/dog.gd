extends BasicEnemy

var running := true
var biting := false

func _ready() -> void:
	speed = 4
	skeleton = $BasicDog/Armature/Skeleton3D/PhysicalBoneSimulator3D
	model = $BasicDog

func _physics_process(delta: float) -> void:
	var current = $BasicDog/AnimationTree.get("parameters/Blend2/blend_amount")
	if biting:

		var new_value = lerp(current, 1.0, blend_speed * delta)
		$BasicDog/AnimationTree.set("parameters/Blend2/blend_amount", new_value)
		
	
	else:
	
		var new_value = lerp(current, 0.0, blend_speed * delta)
		$BasicDog/AnimationTree.set("parameters/Blend2/blend_amount", new_value)
		follow_path(player.global_position, delta)
	
		move_and_slide()


func _on_player_checker_body_entered(body: Node3D) -> void:
	if body == player:
		speed = 0
		$Bite.start()
		biting = true

func _on_player_checker_body_exited(body: Node3D) -> void:
	if body == player:
		biting = false
		$BasicDog/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
		speed = 4
		$Bite.stop()
		


func _on_bite_timeout() -> void:
	$BasicDog/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	await get_tree().create_timer(0.4, false).timeout
	if biting:
		player.take_damage(global_position)
	
func delete_after_death():
	$Bite.stop()
	$BasicDog/PlayerChecker.queue_free()
	for bone in $BasicDog/Armature/Skeleton3D.get_children():
		if bone is BoneAttachment3D:
			for shape in bone.get_children():
				if shape is Area3D:
					shape.monitoring = false
					shape.get_child(0).queue_free()
