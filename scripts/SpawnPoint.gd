extends Node3D
class_name SpawnPoint

@export var spawnTimeout: float = 5.0
@export var timeoutTimer: Timer

func _ready():
	if not timeoutTimer:
		timeoutTimer = Timer.new()
		timeoutTimer.one_shot = true
		add_child(timeoutTimer)

func isAvailable() -> bool:
	if timeoutTimer.time_left == 0:
		return true
	else:
		return false
		
func getCoords() -> Vector3:
	return global_position

func getRotation() -> Vector3:
	return global_rotation
	
func spawnPlayer(player: CharacterBody3D):
	if isAvailable():
		player.global_position = getCoords()
		player.global_rotation = getRotation()
		
		timeoutTimer.start(spawnTimeout)
