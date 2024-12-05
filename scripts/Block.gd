extends StaticBody3D
class_name Block

@export var max_health: int = 20
@export var current_health: int = 20

var deathCallback: Callable

func setDeathCallback(callback: Callable):
	deathCallback = callback

@rpc("any_peer", "call_local", "reliable")
func damage(attack: Dictionary):
	var damageQuantity = attack.get("damage", 1)
	current_health -= damageQuantity
	
	print("Block hit! Current health:", current_health)
		
	if current_health <= 0:
		die()

func die():
	print("Block died")
	queue_free()  # Elimina el enemigo
	if deathCallback:
		deathCallback.call()
