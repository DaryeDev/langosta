extends Node3D
class_name Map

func _ready() -> void:
	Globals.currentMap = self

func spawnPlayer(player: CharacterBody3D):
	if has_node("PlayerSpawnPoint"):
		var playerSpawnPoint = get_node("PlayerSpawnPoint")
		if playerSpawnPoint is SpawnPoint:
			playerSpawnPoint.spawnPlayer(player)
			return
	elif has_node("PlayerSpawnPoints"):
		var spawnPoints = get_node("PlayerSpawnPoints").get_children()
		while true:
			spawnPoints.shuffle()
			for spawnPoint in spawnPoints:
				if (spawnPoint is SpawnPoint) and spawnPoint.isAvailable():
					spawnPoint.spawnPlayer(player)
					return
			await get_tree().create_timer(1).timeout
	elif has_node("PlayerSpawnArea"):
		var spawn_area = get_node("PlayerSpawnArea")
		if spawn_area is SpawnArea:
			spawn_area.spawnPlayer(player)
			return
