extends CharacterBody3D

@export var speed: float = 3.0  # Velocidad de movimiento
@export var attackRange: float = 1.5
@export var attackDamage: float = 10.0
@export var attackCooldown: float = 1.0

@export var attackTimer: Timer

@onready var navAgent3d: NavigationAgent3D = $NavigationAgent3D

var externalForces: Vector3 = Vector3.ZERO

@export var changeFocusedPlayerTimeInterval = 1.0  # Tiempo en segundos
var changeFocusedPlayerTimePassed = 0.0
var currentlyFocusedPlayer: Player

func _ready() -> void:
	if not attackTimer:
		attackTimer = Timer.new()
		attackTimer.one_shot = true
		add_child(attackTimer, true)
		
func targetNearestPlayer():
	if Globals.currentMap and Globals.currentMap.players:
		if changeFocusedPlayerTimePassed >= changeFocusedPlayerTimeInterval:
			if Globals.currentMap and Globals.currentMap.players:
				if Globals.currentMap.players.size() == 0:
					return  # No hay objetivos

				# Encuentra el objetivo más cercano
				var shortest_distance = 9999999

				for player in Globals.currentMap.players:
					var distance = global_transform.origin.distance_to(player.global_position)
					if distance < shortest_distance:
						shortest_distance = distance
						currentlyFocusedPlayer = player
			changeFocusedPlayerTimePassed = 0.0
	
	if currentlyFocusedPlayer != null and currentlyFocusedPlayer.global_position:
		navAgent3d.set_target_position(currentlyFocusedPlayer.global_position)

func _physics_process(delta):
	if multiplayer.is_server() and Globals.currentMap and Globals.currentMap.navReg:
		changeFocusedPlayerTimePassed += delta
		targetNearestPlayer()
		
		var destination = navAgent3d.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		
		velocity = direction * speed
		velocity += externalForces
		externalForces = Vector3.ZERO
		move_and_slide()
		
		if currentlyFocusedPlayer:
			if global_position.distance_to(currentlyFocusedPlayer.global_position) <= attackRange:
				if attackTimer.is_stopped():
					currentlyFocusedPlayer.damage.rpc({"damage": attackDamage})
					attackTimer.start(attackCooldown)

@export var health: float = 75

signal ded

@rpc("any_peer", "call_local")
func damage(attack: Dictionary):
	var damageQuantity = attack.get("damage", 1)
	var knockbackForce = attack.get("knockbackForce", Vector3.ZERO)
	
	health = health - damageQuantity
	externalForces += knockbackForce*10

	if health <= 0:
		handle_death()

func handle_death():
	ded.emit()
	
	var newExplosion = preload("res://scenes/modules/Z_death.tscn").instantiate()
	Globals.currentMap.add_child(newExplosion)
	newExplosion.global_position = global_position
	queue_free()
