extends Node

@onready var main_menu = $Main_UI/MainMenu
@onready var address_entry = $Main_UI/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $Main_UI/HUD
@onready var health_bar = $Main_UI/HUD/HealthBar
@onready var host_ui = $Main_UI/Host_UI
@onready var pause_menu_ui = $Pause_Menu
@onready var main_menu_ui = $Main_UI

var paused = false

const Player = preload("res://scenes/player.tscn")
const PORT = 3131
const DEFAULT_SERVER_IP = "localhost"
var enet_peer = WebSocketMultiplayerPeer.new()

@export var range_x_min = -28 
@export var range_x_max = 28 
@export var range_z_min = -28 
@export var range_z_max = 28
@export var spawn_y = 1.5
@export var MIN_PLAYER_DISTANCE = 2

var connectedPlayers: Dictionary = {}

var add_player_check = false

func _unhandled_input(event):
	# Handle pause and quit actions
	if event.is_action_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	# Start hosting a game
	enet_peer.create_server(PORT, "*")
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	if add_player_check:
		main_menu.hide()
		hud.show()
		add_player(multiplayer.get_unique_id())
	else: 
		main_menu.hide()
		host_ui.show()
		

func _on_join_button_pressed():
	# Join an existing game
	main_menu.hide()
	hud.show()
	var address
	if address_entry.text == "":
		address = DEFAULT_SERVER_IP
	else:
		address = address_entry.text
	enet_peer.create_client("ws://" + address + ":" + str(PORT))
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(_on_peer_connected)

@rpc("call_remote")
func _on_peer_connected(peer_id):
	var player = get_node_or_null(str(peer_id))
	# if player:
	# 	player.call_deferred("update_position", get_new_position())
	while player == null:
		player = get_node_or_null(str(peer_id))
		await get_tree().create_timer(0.1).timeout
	print("Player ready")
	var position = get_new_position()
	player.call_deferred("update_position", position)

func add_player(peer_id):
	# Instantiate player
	var player = Player.instantiate()
	player.name = "Player" + str(peer_id)
	# Get a non-occupied position
	var spawn_position = get_new_position()
	player.position = spawn_position
	add_child(player)

	# Connect signals if the player is the authority
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

	# Store node directly in the dictionary
	connectedPlayers[peer_id] = player

func remove_player(peer_id):
	# Retrieve player from the dictionary
	var player = get_node_or_null(str(peer_id))
	#if connectedPlayers.has(peer_id):
		#var player = connectedPlayers[peer_id]
	if player:
		player.queue_free()
	connectedPlayers.erase(peer_id)

func update_health_bar(health_value):
	# Update the health bar value
	health_bar.value = health_value

func _on_multiplayer_spawner_spawned(node):
	# Connect health_changed signal if the node is the authority
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func toggle_pause():
	# Toggle the pause state
	paused = !paused
	if paused:
		pause_menu_ui.show()
		main_menu_ui.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		pause_menu_ui.hide()
		main_menu_ui.show()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_quit_pressed() -> void:
	# Quit the game
	get_tree().quit()

func _on_resume_pressed() -> void:
	# Resume the game
	toggle_pause()
	
func get_new_position():
	var spawn = get_random_position()
	while is_position_occupied(spawn):
		spawn = get_random_position()
	return spawn

func get_random_position():
	# Generate a random position within the game world bounds
	var x = randi_range(range_x_min, range_x_max)
	var z = randi_range(range_z_min, range_z_max)
	return Vector3(x, spawn_y, z)

func is_position_occupied(position) -> bool:
	# Check if the position is occupied by any player
	for player in connectedPlayers.values():
		if player.position.distance_to(position) < MIN_PLAYER_DISTANCE: # Adjust this value based on player size
			return true
	return false

func _on_check_button_toggled(toggled_on: bool) -> void:
	add_player_check = toggled_on

func _on_player_pressed() -> void:
	host_ui.hide()
	hud.show()
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())

func _on_leave_pressed() -> void:
	get_tree().quit()
