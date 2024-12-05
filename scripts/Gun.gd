extends Weapon
class_name Gun

@export_category("Gun Stats")
@export var gunRange: float = 100
@export var damage: float = 10.0
@export var weakPointMultiplier: float = 1.25
@export var knockbackForce: float = 10.0
@export var stunTime: float = 0
@export var maxBullets: int = 10

@export_category("Gun Runtime Stats")
@export var bulletsLeft: int = 10

@export_category("Gun Sounds")
@export var shootSound: AudioStreamPlayer
@export var reloadSound: AudioStreamPlayer

@export_category("Gun Animations")
@export var animationPlayer: AnimationPlayer

@export_category("Timing")
@export var shootCooldown: float = 0.5
@export var reloadCooldown: float = 1.0
@export var gunTimer: Timer

@export_category("Bullets Label")
@export var bulletsLabel: Label3D
@export var showMaxBullets: bool = true

@export_category("Gun RayCast")
@export var raycast: RayCast3D

func updateBulletsLabel() -> void:
	if bulletsLabel:
		bulletsLabel.text = String.num(bulletsLeft) + (("/"+String.num(maxBullets)) if showMaxBullets else "")

func _ready() -> void:
	if not gunTimer:
		gunTimer = Timer.new()
		gunTimer.one_shot = true
		add_child(gunTimer)
	
	updateBulletsLabel()


func use() -> bool:
	if (animationPlayer and animationPlayer.is_playing()) or gunTimer.time_left != 0: return false
	
	if bulletsLeft <= 0:
		reload()
		return false
	
	if animationPlayer and animationPlayer.has_animation("shoot"): animationPlayer.play("shoot")
	
	if shootSound: shootSound.play()
	
	bulletsLeft -= 1
	updateBulletsLabel()
	
	if raycast:
		raycast.collision_mask = 1|2
		#raycast.hit_from_inside = true
		raycast.exclude_parent = true
		if raycast.is_colliding():
			var hit = raycast.get_collider()
			var hit_pos = raycast.get_collision_point()
			var hit_normal = raycast.get_collision_normal()
			
			print(hit.has_method("damage"))
			print(raycast.global_transform.origin)
			print(hit_pos.distance_to(raycast.global_transform.origin))
			if hit_pos.distance_to(raycast.global_transform.origin) <= gunRange and hit.has_method("damage"):
				#if hit is Entity and hit.hasHitbox():  # Comprueba si puede recibir daño
				if true:
					var direction = (hit.global_transform.origin - raycast.global_transform.origin).normalized()
					var pushForce = direction * knockbackForce
					
					var attack = {}
					attack.damage = damage * (weakPointMultiplier if (hit.has_method("isWeakSpotAttack") and hit.isWeakSpotAttack(hit_normal)) else 1.0)
					#attack.origin = getParentEntity()
					attack.knockbackForce = pushForce
					attack.impactPosition = hit_normal
					
					hit.damage.rpc(attack)
	
	gunTimer.start(shootCooldown+0.01)
	await gunTimer.timeout
	
	if bulletsLeft <= 0:
		reload()
	
	return true

func reload() -> bool:
	if animationPlayer and animationPlayer.is_playing() or gunTimer.time_left != 0: return false
	
	if animationPlayer and animationPlayer.has_animation("reload"): animationPlayer.play("reload")
	
	if reloadSound: reloadSound.play()
	
	gunTimer.start(reloadCooldown)
	await gunTimer.timeout
	bulletsLeft = maxBullets
	
	updateBulletsLabel()
	
	return true
