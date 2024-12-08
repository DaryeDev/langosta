extends CharacterBody3D

@export var speed: float = 3.0  # Velocidad de movimiento

@onready var navAgent3d: NavigationAgent3D = $NavigationAgent3D

func _physics_process(delta):
	if Globals.myPlayer and Globals.currentMap and Globals.currentMap.navReg:
		navAgent3d.set_target_position(Globals.myPlayer.global_position)
		var destination = navAgent3d.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		
		velocity = direction * speed
		move_and_slide()

@export var health: float = 75

signal ded

@rpc("any_peer", "call_local")
func damage(attack: Dictionary):
	var damageQuantity = attack.get("damage", 1)
	health = health - damageQuantity

	if health <= 0:
		handle_death()

func handle_death():
	ded.emit()
	
	var newExplosion = preload("res://scenes/modules/Explosion.tscn").instantiate()
	Globals.currentMap.add_child(newExplosion)
	newExplosion.global_position = global_position
	queue_free()
