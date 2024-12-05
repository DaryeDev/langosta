extends Node

@onready var main_menu = $Main_UI/MainMenu
@onready var address_entry_host: LineEdit = $Main_UI/MainMenu/MarginContainer/VBoxContainer/VBoxContainer/AddressEntryHost
@onready var address_entry_connect: LineEdit = $Main_UI/MainMenu/MarginContainer/VBoxContainer/VBoxContainer2/AddressEntryConnect
@onready var hud = $Main_UI/HUD
@onready var health_bar = $Main_UI/HUD/HealthBar
@onready var host_ui = $Main_UI/Host_UI
@onready var pause_menu_ui = $Pause_Menu
@onready var main_menu_ui = $Main_UI

var paused = false

@export var Player = preload("res://scenes/modules/player.tscn")
const PORT = 3131
const DEFAULT_SERVER_IP = "localhost"
var peer = WebSocketMultiplayerPeer.new()

var dedicated = false

var levels = ["res://scenes/tests/test_nm.tscn", "res://scenes/jungle_level_web.tscn", "res://scenes/snow_level_web.tscn", "res://scenes/coliseum_level_web.tscn"]

func _ready() -> void:
	for level in levels:
		$LevelSpawner.add_spawnable_scene(level)
	
	pause_menu_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server")
		dedicated = true
		_on_host_pressed.call_deferred()

func _unhandled_input(event):
	# Handle pause and quit actions
	if event.is_action_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


# FIX TOGGLE FOR HOST
func _on_host_pressed():
	# Start as server
	var address
	if dedicated:
		address = "*"
	else:
		address = address_entry_host.text if address_entry_host.text != "" else "*"
	peer.create_server(PORT, address)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return
	multiplayer.multiplayer_peer = peer
	start_game()


func _on_connect_pressed():
	# Start as client
	var address = address_entry_connect.text if address_entry_connect.text != "" else DEFAULT_SERVER_IP
	peer.create_client("ws://" + address + ":" + str(PORT))
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	# Hide the UI and unpause to start the game.
	main_menu.hide()
	hud.show()
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
	level.add_child(newLevel)

# The server can restart the level by pressing HOME.
func _input(event):
	if not multiplayer.is_server():
		return
	if event.is_action("changeMap") and Input.is_action_just_pressed("changeMap"):
		var random_index = randi() % levels.size()
		var random_element = levels[random_index]
		change_level.call_deferred(load(random_element))
		#change_level.call_deferred(load("res://level.tscn"))


func _on_check_add_player_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


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
	get_tree().paused = paused  # Set the global paused state
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
