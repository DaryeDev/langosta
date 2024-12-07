extends CharacterBody3D
class_name Player

#signal health_changed(health_value)

# UI and game logic
@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var raycast = $Camera3D/RayCast3D
@onready var multiplayer_handler = $"../"
@onready var death_screen: PanelContainer = $Control/SubViewportContainer/SubViewport/DeathScreen
@onready var death_label: Label = $Control/SubViewportContainer/SubViewport/DeathScreen/ColorRect/death_label
@onready var health_bar: ProgressBar = $HUD/HealthBar

@export var portrait: CompressedTexture2D = preload("res://textures/yo.png")

@export var weakPointCollision: CollisionShape3D
@export var weakPointMultiplier: float = 1.5

signal usernameChanged(newName: String)
@export var username: String = "QuesoCrema":
	set(newName):
		username = newName
		usernameChanged.emit(newName)
	get:
		return username

# Exported variables
@export var blockManager: BlockManager
@export var weaponManager: WeaponManager
@export var gravityMultiplier: float = 1.0
@export var JUMP_VELOCITY: float = 4.5
@export var SPEED: float = 5.0
@export var runMultiplier: float = 2.0
@export var maxHealth = 100
@export var health = 100

signal healthChanged(maxHealth: int, newHealth: int)

# Flags
var weaponAnimPlayer: AnimationPlayer
var defaultGravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var dead = false

func _enter_tree():
	print("Player name in player_new: ", str(name))
	set_multiplayer_authority(str(name).to_int())
	if (multiplayer.get_unique_id() == str(name).to_int()):
		username = Globals.username

func _ready():
	if not is_multiplayer_authority():
		return
	
	Globals.myPlayer = self
	
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if Globals.currentMap and is_instance_valid(Globals.currentMap):
		Globals.currentMap.spawnPlayer(self)
	
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	if weaponManager and weaponManager.weapon and weaponManager.weapon.has_node("AnimationPlayer"):
		weaponAnimPlayer = weaponManager.weapon.animationPlayer
		if weaponAnimPlayer:
			weaponAnimPlayer.animation_finished.connect(_on_animation_player_animation_finished)
	
	if Globals.isUsingVR and VrShit.initialize():
		var vrPlayerController = preload("res://scenes/modules/VRPlayerController/VRPlayerController.tscn").instantiate()
		add_child(vrPlayerController)
	else:
		if blockManager:
			blockManager.raycast = raycast
		
		if weaponManager and weaponManager.weapon:
			weaponManager.weapon.raycast = raycast

func _process(delta: float) -> void:
	if (not is_multiplayer_authority()) or dead or Globals.paused:
		return
	
	if !Globals.isUsingVR:
		if weaponManager and weaponManager.weapon:
			weaponManager.weapon.raycast = raycast
		
	if Input.is_action_just_pressed("shoot"):
		weaponManager.use()
		
	if Input.is_action_just_pressed("changeGun"):
		weaponManager.changeWeapon.rpc()
		
	if Input.is_action_just_pressed("reload"):
		weaponManager.reload()
		
	if Input.is_action_pressed("build"):
		blockManager.buildBlock()

func _input(event: InputEvent):
	if (not is_multiplayer_authority()) or dead or Globals.paused:
		return
	
	if event is InputEventMouseMotion:
		handle_camera_rotation(event)

func handle_camera_rotation(event):
	rotate_y(-event.relative.x * 0.005)
	camera.rotate_x(-event.relative.y * 0.005)
	camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)

func player_movement():
	if dead:
		return
	
	if Globals.paused:
		velocity.x = 0
		velocity.z = 0
		reset_animation()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = SPEED
	if Input.is_action_pressed("run"):
		current_speed *= runMultiplier
		
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
	if weaponAnimPlayer and weaponAnimPlayer.current_animation == "shoot":
		return
	if !Globals.isUsingVR:
		if input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("move", 0.2)
		else:
			anim_player.play("idle", 0.2)

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if not is_on_floor():
		velocity.y -= defaultGravity * gravityMultiplier * delta

	if !Globals.isUsingVR:
		player_movement()
	
	move_and_slide()
	
@rpc("any_peer", "call_local")
func damage(attack: Dictionary):
	var damageQuantity = attack.get("damage", 1)
	health -= damageQuantity
	
	healthChanged.emit(maxHealth, health)
	
	if (not is_multiplayer_authority()) or dead:
		return
	
	if damageQuantity < 0:
		if is_multiplayer_authority():
			$HealthAnimationPlayer.play("heal")
	else:
		if is_multiplayer_authority():
			$HealthAnimationPlayer.play("damage")

	if health <= 0:
		handle_death()


func handle_death():
	#$bodyCollision.disabled = true
	#$headCollision.disabled = true
	$CollisionShape3D.disabled = true
	dead = true
	
	if is_multiplayer_authority():
		death_screen.show()
	
		for n in range(3, 0, -1):
			death_label.text = "Respawning in %s seconds..." % n
			await get_tree().create_timer(1).timeout

	reset_player_state()
	#$bodyCollision.disabled = false
	#$headCollision.disabled = false
	$CollisionShape3D.disabled = false

func reset_player_state():
	if is_multiplayer_authority():
		death_screen.hide()
	
	weaponManager.reload()

	health = maxHealth
	healthChanged.emit(maxHealth, health)
	
	if Globals.currentMap and is_instance_valid(Globals.currentMap):
		Globals.currentMap.spawnPlayer(self)
	
	dead = false

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot" and !Globals.isUsingVR:
		anim_player.play("idle", 0.2)
	
func reset_animation():
	if !Globals.isUsingVR:
		anim_player.play("idle", 0.2)

func update_health_bar(health_value):
	# Update the health bar value
	health_bar.value = health_value
