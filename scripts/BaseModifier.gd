extends Node3D
class_name Modifier

@export var modifierIcon: CompressedTexture2D = preload("res://textures/yo.png")
@export var modifierName: String = "BaseModifier"
@export var modifierDescription: String = "Does nothing, but is the base of all the modifiers."
@export var modifierDuration: float = 10.0
@export var collider: Area3D
@export var mesh: MeshInstance3D
@export var timer: Timer

var player: Player

func _ready() -> void:
	if not timer:
		timer = Timer.new()
		timer.one_shot = true
		add_child(timer, true)
	
	if collider:
		collider.collision_mask = 0
		collider.set_collision_mask_value(2, true)
		
		collider.body_entered.connect(_internal_onBodyEntered)

@rpc("any_peer", "call_local", "reliable")
func _internal_onBodyEntered(body: Node3D) -> void:
	if body is Player:
		body = (body as Player)
		player = body
		body.applyModifier(self)
		
		_onAppliedOnPlayer()
		
		if collider:
			collider.queue_free()

		if mesh:
			mesh.queue_free()

		if timer:
			timer.start(modifierDuration)
			timer.timeout.connect(func():
				_onModifierTimeEnds()
				queue_free()
			)

@rpc("any_peer", "call_local", "reliable")
func _onAppliedOnPlayer() -> void:
	pass
	
@rpc("any_peer", "call_local", "reliable")
func _onModifierTimeEnds() -> void:
	pass

func attackModifier(attack: Dictionary) -> Dictionary:
	Globals.myPlayer.spawnExplosionAtCoordinates.rpc(Globals.myPlayer.global_position)
	
	return attack

func damageModifier(attack: Dictionary) -> Dictionary:
	return attack

func movementModifier(direction: Vector3, current_speed: float):
	return [direction, current_speed]
