extends MultiplayerSpawner

@export var player = "res://scenes/modules/player.tscn"

func _init() -> void:
	add_spawnable_scene(player)
	print("Adding player...")
