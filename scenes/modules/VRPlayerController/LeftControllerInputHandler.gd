extends Node

@onready var controller: XRController3D = get_parent()

func _ready() -> void:
	controller.button_pressed.connect(onButtonPressed)
	controller.button_released.connect(onButtonReleased)

func _process(delta: float) -> void:
	# Movement proxyed to Player Script
	var dz_input_action = XRToolsUserSettings.get_adjusted_vector2(controller, "primary")
	var head_rotation = $"../../XRCamera3D".global_transform.basis
	var direction = (head_rotation * Vector3(dz_input_action.x, 0, -dz_input_action.y)).normalized()
	
	var velocity = Globals.myPlayer.SPEED * (Globals.myPlayer.runMultiplier if Input.is_action_pressed("run") else 1.0)
	
	Globals.myPlayer.update_velocity(direction, velocity)
	
func onButtonPressed(buttonName: String):
	match buttonName:
		"primary_click":
			Input.action_press("run")
		"by_button":
			Input.action_press("spawnRandomEnemy")

func onButtonReleased(buttonName: String):
	match buttonName:
		"primary_click":
			Input.action_release("run")
		"by_button":
			Input.action_release("spawnRandomEnemy")
