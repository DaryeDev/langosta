extends Node3D
class_name Billboard

# Hecho fatal lol, no hay tiempo

@export var timerLabel: Label
@export var timeLimit: int = 600
@export var startTimerAutomatically: bool = true
var onTimerEnd: Callable = func():
	get_tree().free()
@export var timer: SyncedTimer

@export var portrait0: TextureRect
@export var username0: Label
@export var healthBar0: ProgressBar

@export var portrait1: TextureRect
@export var username1: Label
@export var healthBar1: ProgressBar

var players: Dictionary = {}

func _ready() -> void:
	if multiplayer.is_server():
		timer.timeLimit = timeLimit
		
		if startTimerAutomatically and timer.is_stopped():
			timer.start_timer()
	
	timer.timeout.connect(onTimerEnd)

func seconds_to_mm_ss(seconds: int) -> String:
	var minutes = seconds / 60
	var remaining_seconds = seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]	

func _process(delta: float) -> void:
	if multiplayer.is_server():
		timerLabel.text = seconds_to_mm_ss(int(timer.get_remaining_time()))
	

func addPlayer(player: Player):
	if multiplayer.is_server():
		if players.size() < 2:
			players[player.name] = player
			_modifiedPlayers()

func removePlayer(player: Player):
	removePlayerById(player.name)

func removePlayerById(id: String):
	if multiplayer.is_server():
		players.erase(id)
		_modifiedPlayers()
		
func _updateHealthBarProxy(_maxHealth: int, _newHealth: int, player: Player):
	_updateHealthBar(players.keys().find(player.name), player)

func _updateHealthBar(index: int, player: Player):
	var healthBar: ProgressBar
	
	match index:
		0:
			healthBar = healthBar0
		1:
			healthBar = healthBar1
			
	healthBar.max_value = player.maxHealth
	healthBar.value = player.health
	healthBar.visible = true

func _modifiedPlayers():
	if multiplayer.is_server():
		portrait0.visible = false
		username0.visible = false
		healthBar0.visible = false
		
		portrait1.visible = false
		username1.visible = false
		healthBar1.visible = false
		
		if players.size() >= 1:
			var player0 = players.values()[0] as Player
			var a = player0.portrait.resource_path
			portrait0.imagePath = player0.portrait.resource_path
			username0.text = player0.username
			
			portrait0.visible = true
			username0.visible = true
			
			player0.healthChanged.connect(_updateHealthBarProxy.bind(player0))
			_updateHealthBar(0, player0)
			
			player0.usernameChanged.connect(func(newName: String):
				username0.text = newName
			)
		if players.size() >= 2:
			var player1 = players.values()[1] as Player
			portrait1.imagePath = player1.get("portrait").resource_path
			username1.text = player1.get("username")
			
			portrait1.visible = true
			username1.visible = true
			
			player1.healthChanged.connect(_updateHealthBarProxy.bind(player1))
			_updateHealthBar(1, player1)
			
			player1.usernameChanged.connect(func(newName: String):
				username1.text = newName
			)
