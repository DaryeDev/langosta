extends Area3D
class_name ZombieSpawnArea

@export var zombieScene: PackedScene = preload("res://scenes/modules/Teper.tscn")

@onready var collisionShape: CollisionShape3D = $CollisionShape3D

# Variables configurables
@export var initial_spawn_delay: float = 3.0 # Tiempo inicial entre spawns
@export var min_spawn_delay: float = 0.5    # Tiempo mínimo entre spawns
@export var spawn_delay_decrease_rate: float = 0.1 # Velocidad de reducción del delay
@export var maxZombies: int = 20

var _current_spawn_delay: float
var _time_since_last_spawn: float = 0.0
var _zombieCount: int = 0
var _zombiesKilled: int = 0

func _ready() -> void:
	_current_spawn_delay = initial_spawn_delay

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("spawnRandomEnemy"):
		spawnZombie()
		Input.action_release("spawnRandomEnemy")
	
	_time_since_last_spawn += delta

	# Comprobar si es hora de spawnear un zombie
	if _time_since_last_spawn >= _current_spawn_delay and _zombieCount < maxZombies:
		_zombieCount += 1
		spawnZombie()
		_time_since_last_spawn = 0.0

		# Reducir progresivamente el tiempo entre spawns, sin bajar del mínimo
		_current_spawn_delay = max(min_spawn_delay, _current_spawn_delay - spawn_delay_decrease_rate)

# Devuelve una posición aleatoria dentro del área
func get_random_position() -> Vector3:
	if not collisionShape or not collisionShape.shape:
		push_error("PlayerSpawnArea no tiene un CollisionShape3D válido.")
		return global_transform.origin
	
	var shape = collisionShape.shape
	if shape is BoxShape3D:
		var extents = shape.extents
		var random_position = Vector3(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y),
			randf_range(-extents.z, extents.z)
		)
		var z = get_parent()
		var a = global_transform
		var b = random_position
		var c = global_transform * random_position
		return c
	else:
		push_error("Forma no soportada en PlayerSpawnArea.")
		return global_transform.origin

# Método para spawnear un zombie
func spawnZombie():
	var spawn_position = get_random_position()
	spawn_position.y = 2
	var newZombie = zombieScene.instantiate()
	newZombie.ded.connect(func():
		_zombieCount -= 1
		_zombiesKilled += 1
	)
	(newZombie as Node3D).global_position = spawn_position
	if Globals.currentMap:
		Globals.currentMap.add_child(newZombie)
