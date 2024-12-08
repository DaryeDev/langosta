extends Node3D
class_name WeaponManager

@export var weaponIndex: int = 0:
	set(newIndex):
		if newIndex != weaponIndex:
			weaponIndex = newIndex%weapons.size()
			var resyncWeapon = func():
				if weapons[weaponIndex] != weapon:
					changeWeapon(weaponIndex)
			resyncWeapon.call_deferred()
		
@export var weaponScenes: Array[PackedScene]

var weapons: Array[Weapon]
var weapon: Weapon

func loadWeapons():
	for weaponScene in weaponScenes:
		var newWeapon = weaponScene.instantiate()
		newWeapon.set_multiplayer_authority(get_multiplayer_authority())
		weapons.append(newWeapon)
	if not weapon:
		changeWeapon.rpc(weaponIndex)

func _ready() -> void:
	loadWeapons()

@rpc("authority", "call_local", "reliable")
func changeWeapon(index:int=weaponIndex+1):
	if get_children().size() > 1:
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
