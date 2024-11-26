extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var multiplayer_handler = $"../"
@onready var death_screen: PanelContainer = $DeathScreen
@onready var death_label: Label = $DeathScreen/ColorRect/death_label

@export var gravity: int = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var JUMP_VELOCITY = 10.0
@export var SPEED = 5.0
@export var SHIFT_MULTIPLIER = 2.0
@export var Y_OVERRIDE = 2

var health = 3
var dead = false

# FIX PAUSED
var paused = false

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority():
		return
	
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	set_spawn_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func set_spawn_position():
	#self.position = get_new_position()
	self.position = Vector3.ZERO
	self.position.y = Y_OVERRIDE


func _unhandled_input(event):
	if not is_multiplayer_authority() or dead or paused:
		return
	
	if event is InputEventMouseMotion:
		handle_camera_rotation(event)
	
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		handle_shoot_collision()

func handle_camera_rotation(event):
	rotate_y(-event.relative.x * 0.005)
	camera.rotate_x(-event.relative.y * 0.005)
	camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)

func handle_shoot_collision():
	if raycast.is_colliding():
		var hit_player = raycast.get_collider()
		hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

func player_movement():
	if dead:
		return
	#
	if get_tree().paused:
		velocity.x = 0
		velocity.z = 0
		reset_animation()
		return

	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = SPEED
	if Input.is_action_pressed("shift"):
		current_speed *= SHIFT_MULTIPLIER
		
	update_velocity(direction, current_speed)
	update_animation(input_dir)
		
func update_velocity(direction, speed):
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func update_animation(input_dir):
	if anim_player.current_animation == "shoot":
		return
	if input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	player_movement()
	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	if dead:
		return
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	
@rpc("any_peer")
func receive_damage():
	health -= 1
	health_changed.emit(health)

	if health <= 0:
		handle_death()
	else:
		health_changed.emit(health)

func handle_death():
	dead = true
	death_screen.show()
	for n in range(3, 0, -1):
		death_label.text = "Respawning in %s seconds..." % n
		await get_tree().create_timer(1).timeout

	reset_player_state()

func reset_player_state():
	death_screen.hide()
	health = 3
	position = Vector3.ZERO
	dead = false
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
	
func reset_animation():
	anim_player.play("idle")
