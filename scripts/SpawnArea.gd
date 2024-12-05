extends Area3D
class_name SpawnArea

# Devuelve una posición aleatoria dentro del área
func get_random_position() -> Vector3:
	var collision_shape = $CollisionShape3D
	if not collision_shape or not collision_shape.shape:
		push_error("PlayerSpawnArea no tiene un CollisionShape3D válido.")
		return global_transform.origin
	
	var shape = collision_shape.shape
	if shape is BoxShape3D:
		var extents = shape.extents
		var random_position = Vector3(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y),
			randf_range(-extents.z, extents.z)
		)
		return global_transform * random_position
	else:
		push_error("Forma no soportada en PlayerSpawnArea.")
		return global_transform.origin

# Método para spawnear un jugador
func spawnPlayer(player: CharacterBody3D):
	var spawn_position = get_random_position()
	player.global_transform.origin = spawn_position
