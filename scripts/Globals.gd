extends Node

#signal healthChanged(currentHealth: int, maxHealth: int)
signal mapChanged()
#
#func _onHealthChanged(health_value: int):
	#healthChanged.emit(health_value, myPlayer.maxHealth)

var myPlayer: CharacterBody3D:
	set(newPlayer):
		#if myPlayer:
			#myPlayer.health_changed.disconnect(_onHealthChanged)
		#
		myPlayer = newPlayer
#
		#newPlayer.health_changed.connect(_onHealthChanged)
	get:
		return myPlayer

var currentMap: Map:
	set(newMap):
		currentMap = newMap
		mapChanged.emit()
		
	get:
		return currentMap
		
var isViewer: bool = false
var isUsingVR: bool = false
var paused: bool = false
