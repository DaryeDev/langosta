extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D

var health = 3

# Get the gravity from the project settings to be synced with RigidBody nodes.
@export var gravity = 20.0

@export var JUMP_VELOCITY = 10.0
@export var SPEED = 5.0
@export var SHIFT_MULTIPLIER = 2.0

# Position
@export var range_x_min = -28 
@export var range_x_max = 28 
@export var range_z_min = -28 
@export var range_z_max = 28
@export var spawn_y = 1
@export var MIN_PLAYER_DISTANCE = 2

func _enter_tree():
	# Set multiplayer authority based on the player's name.
	set_multiplayer_authority(str(name).to_int())

func _ready():
	# Only run this code if this instance has multiplayer authority.
	if not is_multiplayer_authority(): return
	
	# Capture the mouse and set the camera as the current camera.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	# Only handle input if this instance has multiplayer authority.
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		# Rotate the player and camera based on mouse movement.
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if Input.is_action_just_pressed("shoot") \
			and anim_player.current_animation != "shoot":
		# Play shooting effects and check for collisions.
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

func player_movement():
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
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("call_local")
func update_position(spawn_position):
	position = Vector3(spawn_position)
	
@rpc("any_peer")
func receive_damage():
	# Reduce health and reset position if health is depleted.
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	# Return to idle animation after shooting.
	if anim_name == "shoot":
		anim_player.play("idle")
