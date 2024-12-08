extends Node

## Movement mode
enum TurnMode {
	DEFAULT,	## Use turn mode from project/user settings
	SNAP,		## Use snap-turning
	SMOOTH		## Use smooth-turning
}


## Movement provider order
@export var order : int = 5

## Movement mode property
@export var turn_mode : TurnMode = TurnMode.DEFAULT

## Smooth turn speed in radians per second
@export var smooth_turn_speed : float = 2.0

## Seconds per step (at maximum turn rate)
@export var step_turn_delay : float = 0.2

## Step turn angle in degrees
@export var step_turn_angle : float = 20.0

## Our directional input
@export var input_action : String = "primary"

# Turn step accumulator
var _turn_step : float = 0.0


@onready var controller: XRController3D = get_parent()

func _ready() -> void:
	controller.button_pressed.connect(onButtonPressed)
	controller.button_released.connect(onButtonReleased)
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and Globals.myPlayer.is_on_floor():
		Globals.myPlayer.velocity.y = Globals.myPlayer.JUMP_VELOCITY
	
	# Player Rotation
	if !controller.get_is_active():
		return
	
	var deadzone = 0.1
	if _snap_turning():
		deadzone = XRTools.get_snap_turning_deadzone()

	# Read the left/right joystick axis
	var left_right := controller.get_vector2(input_action).x
	if abs(left_right) <= deadzone:
		# Not turning
		_turn_step = 0.0
		return

	# Handle smooth rotation
	if !_snap_turning():
		left_right -= deadzone * sign(left_right)
		rotate_player(smooth_turn_speed * delta * left_right)
		return

	# Disable repeat snap turning if delay is zero
	if step_turn_delay == 0.0 and _turn_step < 0.0:
		return

	# Update the next turn-step delay
	_turn_step -= abs(left_right) * delta
	if _turn_step >= 0.0:
		return

	# Turn one step in the requested direction
	if step_turn_delay != 0.0:
		_turn_step = step_turn_delay
	rotate_player(deg_to_rad(step_turn_angle) * sign(left_right))
	
	
func onButtonPressed(buttonName: String):
	match buttonName:
		"ax_button":
			Input.action_press("jump")
		"primary_click":
			Input.action_press("changeGun")

func onButtonReleased(buttonName: String):
	match buttonName:
		"ax_button":
			Input.action_release("jump")
		"primary_click":
			Input.action_release("changeGun")

func rotate_player(angle: float):
	var t1 := Transform3D()
	var t2 := Transform3D()
	var rot := Transform3D()
	
	var player: CharacterBody3D = Globals.myPlayer
	var xrCam: XRCamera3D = $"../../XRCamera3D"

	t1.origin = -xrCam.transform.origin
	t2.origin = xrCam.transform.origin
	rot = rot.rotated(Vector3.DOWN, angle)
	player.transform = (player.transform * t2 * rot * t1).orthonormalized()

# Test if snap turning should be used
func _snap_turning():
	match turn_mode:
		TurnMode.SNAP:
			return true

		TurnMode.SMOOTH:
			return false

		_:
			return XRToolsUserSettings.snap_turning
