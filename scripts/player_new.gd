extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var gunRaycast = $Camera3D/RayCast3D
@onready var multiplayer_handler = $"../"
@onready var death_screen: PanelContainer = $DeathScreen
@onready var death_label: Label = $DeathScreen/ColorRect/death_label
@export var weapon: Weapon
var weaponAnimPlayer: AnimationPlayer

@export var gravity: int = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var JUMP_VELOCITY = 10.0
@export var SPEED = 5.0
@export var SHIFT_MULTIPLIER = 2.0
@export var Y_OVERRIDE = 2

@export var maxHealth = 100
@export var health = 100
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
	
	if (weapon):
		weapon.gunRaycast = gunRaycast
		if (weapon.has_node("AnimationPlayer")):
			weaponAnimPlayer = weapon.get_node("AnimationPlayer")
			weaponAnimPlayer.animation_finished.connect(_on_animation_player_animation_finished)


func set_spawn_position():
	#self.position = get_new_position()
	self.position = Vector3.ZERO
	self.position.y = Y_OVERRIDE


func _unhandled_input(event):
	if not is_multiplayer_authority() or dead or paused:
		return
	
	if event is InputEventMouseMotion:
		handle_camera_rotation(event)
	
	if Input.is_action_just_pressed("shoot"):
		weapon.use()

func handle_camera_rotation(event):
	rotate_y(-event.relative.x * 0.005)
	camera.rotate_x(-event.relative.y * 0.005)
	camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)

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
	if weaponAnimPlayer.current_animation == "shoot":
		return
	if input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move", 0.2)
	else:
		anim_player.play("idle", 0.2)

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	player_movement()
	move_and_slide()
	
@rpc("any_peer")
func damage(attack: Dictionary):
	var damageQuantity = attack.get("damage", 1)
	health -= damageQuantity
	health_changed.emit(health)
	
	if damageQuantity < 0:
		$HealthAnimationPlayer.play("heal")
	else:
		$HealthAnimationPlayer.play("damage")

	if health <= 0:
		handle_death()
	else:
		health_changed.emit(health)

func handle_death():
	$MeshInstance3D.visible = false # No parece funcionar, hacer animación de muerte o algo jsjs
	$CollisionShape3D.disabled = true # ... pero, por ahora, hacerlos caer bajo la tierra mola 😎
	dead = true
	death_screen.show()
	for n in range(3, 0, -1):
		death_label.text = "Respawning in %s seconds..." % n
		await get_tree().create_timer(1).timeout

	reset_player_state()
	$MeshInstance3D.visible = true # esto tampoco funciona, claro jsjsjs
	$CollisionShape3D.disabled = false
	

func reset_player_state():
	death_screen.hide()
	health = maxHealth
	position = Vector3.ZERO
	dead = false
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle", 0.2)
	
func reset_animation():
	anim_player.play("idle", 0.2)
