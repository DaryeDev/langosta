extends Node3D

@onready var grid_container: GridContainer = $GridContainer
@onready var players: Node = $"../../Players"

# Dictionary to track players' SubViewportContainers, original cameras, and player nodes
var player_viewports = {}
var original_cameras = {}
var player_nodes = {}
var camera_initialized = {}
var height_adjustments = {}

func _enter_tree():
	print("Player name in viewport: ", str(name))
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority():
		return

	self.process_mode = Node.PROCESS_MODE_ALWAYS
	Globals.currentMap.onNewPlayer.connect(_on_player_connected)
	Globals.currentMap.onPlayerDisconnected.connect(_on_player_disconnected)
	for player in players.get_children():
		if player is Player:
			_on_player_connected(player.name)
	get_viewport().connect("size_changed", _on_window_resized)

# Function to handle a new player connection
func add_player_viewport(player_name):
	# Skip if the player already has a viewport or is the current player
	if str(player_name) in player_viewports or str(player_name) == name:
		return

	# Get the player node as a child of the `Players` node
	var player_node_path = NodePath(str(player_name))
	var player_node = players.get_node_or_null(player_node_path)
	if not player_node:
		print("Player node not found: ", player_name)
		return

	# Fetch the Camera3D from the player node
	var camera = player_node.get_node_or_null("Camera3D")
	if not camera:
		print("Camera3D not found for player: ", player_name)
		return

	# Disable the camera in the main scene to avoid conflicts
	camera.current = false

	# Create a new SubViewportContainer
	var container = SubViewportContainer.new()

	# Create a new SubViewport
	var sub_viewport = SubViewport.new()
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Create a clone of the camera for exclusive use in the SubViewport
	var camera_clone = Camera3D.new()
	camera_clone.current = true
	sub_viewport.add_child(camera_clone)

	# Add SubViewport to the container
	container.add_child(sub_viewport)

	# Add the container to the GridContainer
	grid_container.add_child(container)

	# Store the viewport container, original camera, and player node
	player_viewports[str(player_name)] = container
	original_cameras[str(player_name)] = camera
	player_nodes[str(player_name)] = player_node
	camera_initialized[str(player_name)] = false
	height_adjustments[str(player_name)] = 0.0
	print("Added viewport for player: ", player_name)

	# Adjust the layout of the viewports
	adjust_viewports()

# Function to handle player disconnection
func remove_player_viewport(player_name):
	if str(player_name) in player_viewports:
		var container = player_viewports[str(player_name)]
		grid_container.remove_child(container)
		container.queue_free()
		player_viewports.erase(str(player_name))
		original_cameras.erase(str(player_name))
		player_nodes.erase(str(player_name))
		camera_initialized.erase(str(player_name))
		print("Removed viewport for player: ", player_name)

		# Adjust the layout of the viewports
		adjust_viewports()

# Ajustar el diseño de los viewports
func adjust_viewports():
	var num_players = player_viewports.size()
	if num_players == 0:
		return

	# Calcular el número de columnas y filas como la raíz cuadrada del número de jugadores
	var cols = int(ceil(sqrt(num_players)))
	var rows = int(ceil(float(num_players) / cols))

	# Ajustar la cantidad de columnas del GridContainer
	grid_container.columns = cols

	var window_size = get_viewport().get_visible_rect().size

	# Calcular el tamaño de cada viewport
	var viewport_width = window_size.x / cols
	var viewport_height = window_size.y / rows

	# Asegurarse de que el tamaño de cada viewport no exceda el tamaño de la ventana
	if viewport_width * cols > window_size.x:
		viewport_width = window_size.x / cols
	if viewport_height * rows > window_size.y:
		viewport_height = window_size.y / rows

	var index = 0
	for player_name in player_viewports.keys():
		var container = player_viewports[player_name]
		var sub_viewport = container.get_child(0)

		var row = index / cols
		var col = index % cols

		sub_viewport.size = Vector2(viewport_width, viewport_height)
		container.size = Vector2(viewport_width, viewport_height)
		container.position = Vector2(col * viewport_width, row * viewport_height)

		index += 1

# Synchronize camera transform from the original camera and player
func _process(delta):
	for player_name in original_cameras.keys():
		var original_camera = original_cameras[player_name]
		var player_node = player_nodes[player_name]
		var container = player_viewports[player_name]
		var sub_viewport = container.get_child(0)

		if sub_viewport:
			var cloned_camera = sub_viewport.get_child(0)
			if cloned_camera:
				cloned_camera.global_position = player_node.camera.global_position
				cloned_camera.global_rotation = player_node.camera.global_rotation

# Simulate player connection and disconnection
func _on_player_connected(player_name):
	print("Player name: ", player_name)
	add_player_viewport(player_name)

func _on_player_disconnected(player_name):
	remove_player_viewport(player_name)

# Handle window resize
func _on_window_resized():
	adjust_viewports()
