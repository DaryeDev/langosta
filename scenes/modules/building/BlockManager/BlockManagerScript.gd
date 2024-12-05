extends Node3D
class_name BlockManager

@export var raycast: RayCast3D
@export var ray_length = 5;
@export var buildCooldown: float = 0.25

func _ready() -> void:
	if not raycast:
		raycast = $RayCast3D

func get_gridmap(isPreview: bool = false) -> GridMap:
	var gridmap
	if isPreview:
		gridmap = Globals.currentMap.previewBlockGrid
	else:
		gridmap = Globals.currentMap.blockGrid
	
	if gridmap:
		return gridmap
	return null

func buildBlock(isPreview: bool = false):
	if $buildCooldownTimer.time_left == 0:
		var gridmap = get_gridmap(isPreview)
		if gridmap:
			if isPreview: 
				gridmap.clear()
			else:
				print("hola")
			if raycast.is_colliding():
				# Obtener la posición del hit en coordenadas globales
				var hit_pos = raycast.get_collision_point()
				var hit_normal = raycast.get_collision_normal()
				
				if hit_pos.distance_to(raycast.global_transform.origin) < 5:
					if not isPreview:
						var grid_pos = gridmap.local_to_map(gridmap.to_local(hit_pos))
						# Si golpeamos un bloque existente, colocar al lado
						var new_pos = grid_pos + Vector3i(
							int(round(hit_normal.x)),
							int(round(hit_normal.y)),
							int(round(hit_normal.z))
						)
						
						# Si golpeamos una celda vacía
						if gridmap.get_cell_item(Vector3(grid_pos.x, grid_pos.y, grid_pos.z)) == -1:
							gridmap.addBlock.rpc(Vector3(grid_pos.x, grid_pos.y, grid_pos.z))
						elif gridmap.get_cell_item(Vector3(new_pos.x, new_pos.y, new_pos.z)) == -1:
							gridmap.addBlock.rpc(Vector3(new_pos.x, new_pos.y, new_pos.z))
						else:
							print("xd")
					else:
						var grid_pos = gridmap.local_to_map(gridmap.to_local(hit_pos))
						gridmap.addBlock.rpc(Vector3(grid_pos.x, grid_pos.y, grid_pos.z))
		$buildCooldownTimer.start(buildCooldown)
