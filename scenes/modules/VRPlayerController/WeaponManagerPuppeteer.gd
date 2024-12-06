extends Node3D

@onready var controller: XRController3D = get_parent()

func _ready() -> void:
	controller.button_pressed.connect(onButtonPressed)
	controller.button_released.connect(onButtonReleased)

func _process(delta: float) -> void:
	Globals.myPlayer.weaponManager.global_position = global_position
	Globals.myPlayer.weaponManager.global_rotation = global_rotation
	
func onButtonPressed(buttonName: String):
	match buttonName:
		"trigger_click":
			Input.action_press("shoot")
		"grip_click":
			Input.action_press("grab")
		"by_button":
			Input.action_press("reload")

func onButtonReleased(buttonName: String):
	match buttonName:
		"trigger_click":
			Input.action_release("shoot")
		"grip_click":
			Input.action_release("grab")
		"by_button":
			Input.action_release("reload")
