extends Node3D

@export var broken_model:PackedScene
@onready var nav_region = get_tree().get_first_node_in_group("NavigationRegion")
@onready var main = get_tree().get_first_node_in_group("Main")
@onready var player = get_tree().get_first_node_in_group("Player")

var full := true

func _ready():
	add_to_group("barrier")

func _process(delta: float) -> void:
	$PlayerChecker.look_at(player.global_position, Vector3.UP)
	$PlayerChecker2.look_at(player.global_position, Vector3.UP)
	if $PlayerChecker.get_collider() == $Barrier and Vector2($HideArea.global_position.x, $HideArea.global_position.z) \
	.distance_to(Vector2(player.global_position.x, player.global_position.z)) >= 3:
		$HideArea/CollisionShape3D.disabled = false
	else:
		$HideArea/CollisionShape3D.disabled = true

	if $PlayerChecker2.get_collider() == $Barrier and Vector2($HideArea2.global_position.x, $HideArea2.global_position.z) \
	.distance_to(Vector2(player.global_position.x, player.global_position.z)) >= 3:
		$HideArea2/CollisionShape3D.disabled = false
	else: 
		$HideArea2/CollisionShape3D.disabled = true


#func hit():
	#if full:
		#full = false
		#var old_parent = self.get_parent()
		#old_parent.remove_child(self)  # Remove from current parent
		#main.add_child(self)     # Add to new parent
		#var broken_model_inst:Node3D = broken_model.instantiate()
		#get_parent().add_child(broken_model_inst)
		#broken_model_inst.transform = self.transform
#
		#self.queue_free()
	
	
func destroy(from_position: Vector3, force: float = 5.0):
	if full:
		full = false

		var old_parent = get_parent()
		old_parent.remove_child(self)
		main.add_child(self)

		var broken_model_inst: Node3D = broken_model.instantiate()
		get_parent().add_child(broken_model_inst)
		broken_model_inst.transform = self.transform

		# Apply force to all rigid bodies inside the broken model
		for body in broken_model_inst.get_children():
			if body is RigidBody3D:
				var direction = (body.global_position - from_position).normalized()
				body.apply_impulse(direction * force)

		queue_free()
