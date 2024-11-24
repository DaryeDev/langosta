extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var multiplayer_handler = $"../"
@onready var death_screen: PanelContainer = $DeathScreen
@onready var death_label: Label = $DeathScreen/ColorRect/death_label

var health = 3
var dead = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
@export var gravity = 20.0

@export var JUMP_VELOCITY = 10.0
@export var SPEED = 5.0
@export var SHIFT_MULTIPLIER = 2.0

# Variables from multiplayer_handler
var ground: CSGPolygon3D
var connectedPlayers: Dictionary
var border_margin: float
var range_x_min: int
var range_x_max: int
var range_z_min: int
var range_z_max: int
var spawn_y: int
var MIN_PLAYER_DISTANCE: int


func _enter_tree():
	# Set multiplayer authority based on the player's name.
	set_multiplayer_authority(str(name).to_int())

func _ready():
	# Only run this code if this instance has multiplayer authority.
	if not is_multiplayer_authority(): return
	
	ground = multiplayer_handler.get("ground")
	connectedPlayers = multiplayer_handler.get("connectedPlayers")
	border_margin = multiplayer_handler.get("border_margin")
	range_x_min = multiplayer_handler.get("range_x_min")
	range_x_max = multiplayer_handler.get("range_x_max")
	range_z_min = multiplayer_handler.get("range_z_min")
	range_z_max = multiplayer_handler.get("range_z_max")
	spawn_y = multiplayer_handler.get("spawn_y")
	MIN_PLAYER_DISTANCE = multiplayer_handler.get("MIN_PLAYER_DISTANCE")
	
	var spawn_position = get_new_position()
	self.position = spawn_position
	
	# Capture the mouse and set the camera as the current camera.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	# Only handle input if this instance has multiplayer authority.
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and !dead:
		# Rotate the player and camera based on mouse movement.
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_just_pressed("shoot") \
			and anim_player.current_animation != "shoot" and !dead:
		# Play shooting effects and check for collisions.
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

func player_movement():
	if not dead:
		# Handle Jump.
		if Input.is_action_just_pressed("space") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var current_speed = SPEED
		
		if Input.is_action_pressed("shift"):
			# Increase speed when shift is pressed.
			current_speed *= SHIFT_MULTIPLIER
		
		if direction:
			# Move the player in the input direction.
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			# Decelerate the player when no input is given.
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

		# Play appropriate animations based on player state.
		if anim_player.current_animation == "shoot":
			pass
		elif input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("move")
		else:
			anim_player.play("idle")

func get_random_position():
	# Get the bounds for generating random positions
	var origin = ground.global_transform.origin
	var bounds_size = Vector2(50, 50)  # Adjust based on expected size
	var min_x = origin.x - bounds_size.x / 2 + border_margin
	var max_x = origin.x + bounds_size.x / 2 - border_margin
	var min_z = origin.z - bounds_size.y / 2 + border_margin
	var max_z = origin.z + bounds_size.y / 2 - border_margin

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

func is_position_occupied(position) -> bool:
	# Check if the position is occupied by any player
	for player in connectedPlayers.values():
		if player.position.distance_to(position) < MIN_PLAYER_DISTANCE: # Adjust this value based on player size
			return true
	return false

func _physics_process(delta):
	# Only run this code if this instance has multiplayer authority.
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	player_movement()
	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	# Play shooting animation and effects.
	if !dead:
		anim_player.stop()
		anim_player.play("shoot")
		muzzle_flash.restart()
		muzzle_flash.emitting = true
	
@rpc("any_peer")
func receive_damage():
	# Reduce health and reset position if health is depleted.
	var death_text = "Respawning in %s seconds..."
	health -= 1
	if health <= 0:
		health_changed.emit(health)
		death_screen.show()
		dead = true
		for n in range(3,0,-1):
			death_label.text = death_text % n
			await get_tree().create_timer(1).timeout
		print("3 segundos han pasado")
		death_screen.hide()
		health = 3
		position = get_new_position()
		dead = false
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	# Return to idle animation after shooting.
	if anim_name == "shoot":
		anim_player.play("idle")
