extends Node3D

var hover_speed = 2.0  # Speed of hovering
var hover_amplitude = 2.0  # Height of hovering
var original_position = Vector3()
@onready var crystals: MeshInstance3D = $"."  # MeshInstance3D for the crystals

var min_emission = 1  # Minimum emission energy
var max_emission = 50  # Maximum emission energy

func _ready():
	original_position = position  # Store the original position

func _process(_delta):
	var time = Time.get_ticks_msec() / 1000.0  # Get time in seconds
	# Update position for hover effect
	position.y = original_position.y + sin(time * hover_speed) * hover_amplitude
	
	# Calculate emission energy using a sine wave
	var emission = lerp(min_emission, max_emission, (sin(time * hover_speed) + 1) / 2)
	
	# Update the shader parameter
	var surface = crystals.get_surface_override_material(0)
	if surface is ShaderMaterial:
		var shader = surface as ShaderMaterial
		shader.set_shader_parameter("emission_energy", emission)
