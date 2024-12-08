extends Node
class_name MultiplayerManager

# UI and game logic
@onready var main_menu = $Main_UI/MainMenu
@export var address_entry_host: LineEdit
@export var address_entry_connect: LineEdit
#@onready var hud = $Main_UI/HUD
#@onready var health_bar = $Main_UI/HUD/HealthBar
@onready var host_ui = $Main_UI/Host_UI
@onready var pause_menu_ui = $Pause_Menu
@onready var main_menu_ui = $Main_UI

@export var userInfo: Dictionary = {}

# Flags
var initialized = false
var dedicated = false

# Role
var server = false

# Multiplayer
const PORT = 3131
const DEFAULT_SERVER_IP = "localhost"
var peer = WebSocketMultiplayerPeer.new()

# Level spawner
var levels = ["res://scenes/tests/test_nm.tscn", "res://scenes/jungle_level_web.tscn", "res://scenes/snow_level_web.tscn", "res://scenes/coliseum_level_web.tscn"]

func isServerNotPlaying():
	return Globals.isServerNotPlaying or OS.has_feature("isServerNotPlaying")

func _process(delta: float) -> void:
	if !initialized:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Globals.paused else Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	Globals.multiplayerManager = self
	
	if DisplayServer.get_name() == "headless":
		dedicated = true
		print("Automatically starting dedicated server")
		_on_host_pressed.call_deferred()
	else:
		# Initialize UI and game logic only in non-headless mode
		for level in levels:
			$LevelSpawner.add_spawnable_scene(level)
		
	#pause_menu_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	# Handle pause and quit actions
	if event.is_action_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


@rpc("any_peer", "call_local", "reliable")
func askForUserInfo():
	setupUser.rpc_id(1, Globals.username, Globals.role)
	if Globals.role == "Viewer":
		Globals.currentMap.playerSpawner.add_player(multiplayer.get_unique_id(), Globals.username, "Viewer")

@rpc("any_peer", "call_local", "reliable")
func setupUser(userName: String, role: String):
	if multiplayer.is_server():
		var id = multiplayer.get_remote_sender_id()
		if not id in userInfo:
			userInfo[id] = {
				"name" = userName,
				"role" = role
			}
			
			print("User %s (%d) role set to %s" % [userName, id, role])
			
			if Globals.currentMap and role != "Viewer":
				Globals.currentMap.playerSpawner.add_player(id, userName, role)
		else:
			print("User %d not found to set role %s" % [id, role])

# FIX TOGGLE FOR HOST
func _on_host_pressed():
	# Start as server
	var address
	if dedicated:
		address = "*"
	else:
		address = address_entry_host.text if address_entry_host.text != "" else "*"
	peer.create_server(PORT, address)
	multiplayer.peer_connected.connect(func(id: int):
		askForUserInfo.rpc_id(id)
	)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return
	server = true
	multiplayer.multiplayer_peer = peer
	setupUser(Globals.username, Globals.role)
	start_game()


func _on_connect_pressed():
	# Start as client
	# Make a toggle for viewer
	var address = address_entry_connect.text if address_entry_connect.text != "" else "ws://"+DEFAULT_SERVER_IP
	peer.create_client(address + ":" + str(PORT))
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	# Hide the UI and unpause to start the game.
	initialized = true
	main_menu.hide()
	
	if OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		change_level.call_deferred(load("res://scenes/tests/test_nm.tscn"))


# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	
	# Add new level.
	var newLevel = scene.instantiate()
	Globals.currentMap = newLevel
	level.add_child(newLevel)

# The server can restart the level by pressing HOME.
func _input(event):
	if not multiplayer.is_server():
		return
	if event.is_action("changeMap") and Input.is_action_just_pressed("changeMap"):
		var random_index = randi() % levels.size()
		var random_element = levels[random_index]
		change_level.call_deferred(load(random_element))
	if event.is_action("zombies") and Input.is_action_just_pressed("zombies"):
		change_level.call_deferred(load("res://scenes/jungle_level_web.tscn"))

func _on_check_add_player_toggled(toggled_on: bool) -> void:
	Globals.isServerNotPlaying = !toggled_on

func _on_connect_viewer_pressed() -> void:
	Globals.role = "Viewer"
	_on_connect_pressed.call_deferred()

#func update_health_bar(health_value):
	## Update the health bar value
	#health_bar.value = health_value

#func _on_multiplayer_spawner_spawned(node):
	## Connect health_changed signal if the node is the authority
	#if node.is_multiplayer_authority():
		#node.health_changed.connect(update_health_bar)


func toggle_pause():
	# Toggle the pause state
	if !initialized:
		return
	Globals.paused = !Globals.paused
	if Globals.paused:
		pause_menu_ui.show()
		main_menu_ui.hide()
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		pause_menu_ui.hide()
		main_menu_ui.show()
		#if isServerNotPlaying() and server:
			#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#else:
			#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_quit_pressed() -> void:
	# Quit the game
	get_tree().quit()

func _on_resume_pressed() -> void:
	# Resume the game
	toggle_pause()


func _on_enableVR_button_toggled(toggled_on: bool) -> void:
	Globals.isUsingVR = toggled_on
