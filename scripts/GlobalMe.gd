extends Node

signal healthChanged(currentHealth: int, maxHealth: int)

var player: CharacterBody3D

func setPlayer(player: CharacterBody3D):
	self.player = player
	
	if !OS.has_feature("viewer"):
		player.health_changed.connect(func(health_value: int):
			healthChanged.emit(health_value, player.maxHealth)
		)
