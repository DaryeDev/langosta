extends Node3D
class_name WeaponManager

@export var weaponIndex: int = 0
@export var weaponScenes: Array[PackedScene]

var weapons: Array[Weapon]
var weapon: Weapon

func loadWeapons():
	for weaponScene in weaponScenes:
		weapons.append(weaponScene.instantiate())

func _ready() -> void:
	loadWeapons()
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		changeWeapon.rpc(weaponIndex)

@rpc("authority", "call_local", "reliable")
func changeWeapon(index:int=weaponIndex+1):
	if get_children().size() > 0:
		remove_child(weapon)
	
	weaponIndex = index%weapons.size()
	weapon = weapons[weaponIndex]
	
	add_child(weapon)

func use() -> bool:
	return await weapon.use()
	
func reload() -> bool:
	if weapon is Gun:
		return await weapon.reload()
	else: return false
