extends Node3D
class_name WeaponManager

@export var weaponIndex: int = 0
@export var weaponScenes: Array[PackedScene]

var weapons: Array[Weapon]
var weapon: Weapon

func loadWeapons():
	for weaponScene in weaponScenes:
		weapons.append(weaponScene.instantiate())
	if not weapon:
		changeWeapon.rpc(0)

func _ready() -> void:
	loadWeapons()

@rpc("authority", "call_local", "reliable")
func changeWeapon(index:int=weaponIndex+1):
	if get_children().size() > 0:
		remove_child(weapon)
	
	weaponIndex = index%weapons.size()
	weapon = weapons[weaponIndex]
	
	add_child(weapon)

func use() -> bool:
	if weapon:
		return await weapon.use()
	else: return false
	
func reload() -> bool:
	if weapon is Gun:
		return await weapon.reload()
	else: return false
