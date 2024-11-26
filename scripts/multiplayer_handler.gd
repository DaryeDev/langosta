extends Node3D

@onready var main_menu = $Main_UI/MainMenu
@onready var address_entry_host: LineEdit = $Main_UI/MainMenu/MarginContainer/VBoxContainer/VBoxContainer/AddressEntryHost
@onready var address_entry_join: LineEdit = $Main_UI/MainMenu/MarginContainer/VBoxContainer/VBoxContainer2/AddressEntryJoin
@onready var hud = $Main_UI/HUD
@onready var health_bar = $Main_UI/HUD/HealthBar
@onready var host_ui = $Main_UI/Host_UI
@onready var pause_menu_ui = $Pause_Menu
@onready var main_menu_ui = $Main_UI

var paused = false

@export var Player = preload("res://scenes/modules/player.tscn")
const PORT = 3131
const DEFAULT_SERVER_IP = "localhost"
var enet_peer = WebSocketMultiplayerPeer.new()

@export var range_x_min = 0
@export var range_x_max = 0 
@export var range_z_min = 0 
@export var range_z_max = 0
@export var spawn_y = 1.5
@export var MIN_PLAYER_DISTANCE = 2
@export var ground: CSGPolygon3D
@export var border_margin: float = 1.0  # Minimum distance from the border of the ground polygon

var connectedPlayers: Dictionary = {}

var add_player_check := false
var host = false

func _unhandled_input(event):
	# Handle pause and quit actions
	if event.is_action_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	# Start hosting a game
	var address
	if address_entry_host.text == "":
		address = "*"
	else:
		address = address_entry_host.text
	enet_peer.create_server(PORT, address)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	if add_player_check:
		main_menu.hide()
		hud.show()
		add_player(multiplayer.get_unique_id())
		host = true
	else: 
		main_menu.hide()
		host_ui.show()

func _on_join_button_pressed():
	# Join an existing game
	main_menu.hide()
	#loading_screen.show()
	hud.show()
	var address
	if address_entry_join.text == "":
		address = DEFAULT_SERVER_IP
	else:
		address = address_entry_join.text
	enet_peer.create_client("ws://" + address + ":" + str(PORT))
	multiplayer.multiplayer_peer = enet_peer
	#multiplayer.peer_connected.connect(_on_peer_connected)


#@rpc("call_remote")
#func _on_peer_connected(peer_id):
	#var player = get_node_or_null(str(peer_id))

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = "Player" + str(peer_id)
	var spawn_position = get_new_position()
	add_child(player)
	player.position = spawn_position
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
	connectedPlayers[peer_id] = player

func remove_player(peer_id):
	if connectedPlayers.has(peer_id):
		var player = connectedPlayers[peer_id]
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
	
func get_random_position():
	# Get the bounds for generating random positions
	var origin = Vector3.ZERO
	var bounds_size = Vector2(50, 50)  # Adjust based on expected size
	var min_x = origin.x - bounds_size.x / 2
	var max_x = origin.x + bounds_size.x / 2
	var min_z = origin.z - bounds_size.y / 2
	var max_z = origin.z + bounds_size.y / 2

	# Generate a random position within the bounds
	var x = randf_range(min_x, max_x)
	var z = randf_range(min_z, max_z)

	# Raycast to find the position on the ground
	var ray_origin = Vector3(x, 100, z)  # Start from above the ground
	var ray_target = Vector3(x, -100, z)  # Direction towards the ground

	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(ray_origin, ray_target, 1, [])
	var result = space_state.intersect_ray(ray)

	if result:
		# Return the position where the ray hit the ground
		return result.position
	else:
		# If no valid hit, retry
		return get_random_position()

func get_new_position():
	var spawn = get_random_position()
	while is_position_occupied(spawn):
		spawn = get_random_position()
	return spawn

func is_position_occupied(pos) -> bool:
	# Check if the position is occupied by any player
	for player in connectedPlayers.values():
		if player.position.distance_to(pos) < MIN_PLAYER_DISTANCE: # Adjust this value based on player size
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
