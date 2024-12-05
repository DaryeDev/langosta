extends Node3D

const SPAWN_RANDOM := 5.0
var spawn_host_player = true


func _ready():
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server") and spawn_host_player:
		add_player(1)


func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)


func add_player(id: int):
	var character
	if id == 1:
		print("Soy server")
		if Globals.isViewer and OS.has_feature("viewer"):
			character = load("res://scenes/modules/server_viewport.tscn").instantiate()
		else:
			character = load("res://scenes/modules/player_new.tscn").instantiate()
	else:
		character = load("res://scenes/modules/player_new.tscn").instantiate()

	# Set player id.
	#character.player = id
	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)
	character.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 2, pos.y * SPAWN_RANDOM * randf())
	character.name = str(id)
	$Players.add_child(character, true)


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
