extends Node3D

@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var multiplayer_handler = $"../../"

# Dictionary to track players' SubViewport nodes
var player_viewports = {}

func _enter_tree():
	print("Player name in viewport: ", str(name))
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority():
		return
		
	#Me.setPlayer(self)
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	#
	#multiplayer.multiplayer_peer.connect("player_connected", self, "_on_player_connected")
	#multiplayer_handler.connect("player_disconnected", self, "_on_player_disconnected")

func get_all_cameras():
	var cameras_dict = {}
	for player_name in player_viewports.keys():
		var viewport = player_viewports[player_name]
		if viewport.has_node("Camera3D"):
			cameras_dict[player_name] = viewport.get_node("Camera3D")
	return cameras_dict

# Function to handle a new player connection
func add_player_viewport(player_name):
	if player_name in player_viewports:
		return # Avoid duplicates
	
	# Create a new SubViewport
	var sub_viewport = SubViewport.new()
	sub_viewport.size = sub_viewport_container.rect_size  # Match the container size
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Create a new Camera3D for the SubViewport
	var camera = Camera3D.new()
	camera.current = true
	sub_viewport.add_child(camera)
	
	# Add the SubViewport to the container
	sub_viewport_container.add_child(sub_viewport)
	player_viewports[player_name] = sub_viewport
	print("Added viewport for player: ", player_name)

# Function to handle player disconnection
func remove_player_viewport(player_name):
	if player_name in player_viewports:
		var sub_viewport = player_viewports[player_name]
		sub_viewport_container.remove_child(sub_viewport)
		sub_viewport.queue_free()
		player_viewports.erase(player_name)
		print("Removed viewport for player: ", player_name)

# Simulate player connection and disconnection
func _on_player_connected(player_name):
	add_player_viewport(player_name)

func _on_player_disconnected(player_name):
	remove_player_viewport(player_name)
