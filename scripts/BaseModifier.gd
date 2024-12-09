@tool
extends Node3D
class_name Modifier

@export var modifierIcon: CompressedTexture2D:
	set(newIcon):
		modifierIcon = newIcon
		modifierIconPath = newIcon.resource_path

@export var modifierIconPath: String = "res://textures/yo.png"

@export var modifierName: String = "BaseModifier":
	set(newName):
		modifierName = newName
		name = newName

@export var modifierDescription: String = "Does nothing, but is the base of all the modifiers."
@export var modifierDuration: float = 10.0
@export var collider: Area3D
@export var mesh: MeshInstance3D
@export var timer: Timer

var player: Player

func _ready() -> void:
	if not Engine.is_editor_hint():
		if not timer:
			timer = Timer.new()
			timer.one_shot = true
			add_child(timer, true)
		
		if collider:
			collider.collision_mask = 0
			collider.set_collision_mask_value(2, true)
			
			collider.body_entered.connect(_internal_onBodyEntered)

func _internal_onBodyEntered(body: Node3D) -> void:
	if body is Player:
		body = (body as Player)
		player = body
		body.applyModifier(self)

func _internal_appliedOnPlayer(player: Player):
	self.player = player
	
	if not timer:
		timer = Timer.new()
		timer.one_shot = true
		add_child(timer, true)
	
	_onAppliedOnPlayer.call_deferred()
		
	if collider:
		collider.queue_free()

	if mesh:
		mesh.queue_free()

	if timer:
		timer.start(modifierDuration)
		timer.timeout.connect(func():
			_onModifierTimeEnds.call_deferred()
			player.removeModifier(self)
			queue_free()
		)

func _onAppliedOnPlayer() -> void:
	pass
	
func _onModifierTimeEnds() -> void:
	pass

func attackModifier(attack: Dictionary) -> Dictionary:
	return attack

func damageModifier(attack: Dictionary) -> Dictionary:
	return attack

func movementModifier(direction: Vector3, current_speed: float):
	return [direction, current_speed]
