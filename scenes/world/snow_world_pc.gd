extends Node3D

var grass: PackedScene =  preload("res://scenes/world/grass.tscn")

func _ready() -> void:
	# Comprobar si se está ejecutando en un navegador web (HTML5)
	if OS.get_name() != "HTML5":
		# Solo cargar o instanciar grass si no es HTML5
		grass.instantiate()
	else:
		print("Ejecutando en un navegador, no se cargará grass.")

# El resto del código
func _process(delta: float) -> void:
	pass
