extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar

var paused = false

const Player = preload("res://player.tscn")
const PORT = 3131
const DEFAULT_SERVER_IP = "localhost"
const USE_SSL = true # Set this to true or false based on your requirement 
const TRUSTED_CHAIN_PATH = "res://certs/localhost.pem" 
const PRIVATE_KEY_PATH = "res://certs/localhost-key.pem"
#var enet_peer = WebSocketMultiplayerPeer.new()

var connectedPlayers = {}

var player_info = {"name": ""}

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	var enet_peer = WebSocketMultiplayerPeer.new()
	main_menu.hide()
	hud.show()
	
	#var priv = load(PRIVATE_KEY_PATH) 
	#var cert = load(TRUSTED_CHAIN_PATH) 
	#var tlsOptions = TLSOptions.server(priv, cert) 
	
	#enet_peer.create_server(PORT, "*", tlsOptions)
	enet_peer.create_server(PORT, "*")
	
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed():
	var enet_peer = WebSocketMultiplayerPeer.new()
	main_menu.hide()
	hud.show()
	
	#var cert = load(TRUSTED_CHAIN_PATH) 
	#var tlsOptions = TLSOptions.client(cert) 
	
	#enet_peer.create_client("wss://" + address_entry.text + ":" + str(PORT), tlsOptions)
	enet_peer.create_client("ws://" + address_entry.text + ":" + str(PORT))
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func toggle_pause():
	paused = !paused
	if paused:
		$Pause_Menu.show()
		$CanvasLayer.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		$Pause_Menu.hide()
		$CanvasLayer.show()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_resume_pressed() -> void:
	toggle_pause()
