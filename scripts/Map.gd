extends Node3D
class_name Map

@export var mapName: String = ""
@export var navReg: NavigationRegion3D
@export var blockGrid: GridMap
@export var blocksPlaced: Array = []
@export var billboard: Billboard
@export var playerSpawner: PlayerSpawner
@export var enableVoting: bool = false

var players: Array[Player] = []
signal onNewPlayer(id: int)
signal onPlayerDisconnected(id: int)

@rpc("authority", "call_local", "reliable")
func _emitOnNewPlayer(id: int):
	onNewPlayer.emit(id)
@rpc("authority", "call_local", "reliable")
func _emitOnPlayerDisconnected(id: int):
	onPlayerDisconnected.emit(id)

func _ready() -> void:
	if not playerSpawner and $PlayerSpawner:
		playerSpawner = $PlayerSpawner
	
	Globals.currentMap = self
	
	for block in blocksPlaced:
		blockGrid.addBlock(block[0], block[1], false)
	print(mapName)

func spawnPlayer(player: CharacterBody3D):
	if has_node("PlayerSpawnPoint"):
		var playerSpawnPoint = get_node("PlayerSpawnPoint")
		if playerSpawnPoint is SpawnPoint:
			playerSpawnPoint.spawnPlayer(player)
			return
	elif has_node("PlayerSpawnPoints"):
		print("PlayerSpawnPoints")
		var spawnPoints = get_node("PlayerSpawnPoints").get_children()
		while true:
			spawnPoints.shuffle()
			for spawnPoint in spawnPoints:
				if (spawnPoint is SpawnPoint) and spawnPoint.isAvailable():
					spawnPoint.spawnPlayer(player)
					return
			await get_tree().create_timer(1).timeout
	elif has_node("PlayerSpawnArea"):
		print("PlayerSpawnArea")
		var spawn_area = get_node("PlayerSpawnArea")
		if spawn_area is SpawnArea:
			spawn_area.spawnPlayer(player)
			return
