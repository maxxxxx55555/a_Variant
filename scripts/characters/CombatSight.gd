extends RefCounted

static func clear(attacker: PhysicsBody3D, target: Node3D) -> bool:
	if not is_instance_valid(target) or not attacker.is_inside_tree(): return false
	var origin := attacker.global_position + Vector3.UP
	var destination := target.global_position + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 1, [attacker.get_rid()])
	var hit := attacker.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target
