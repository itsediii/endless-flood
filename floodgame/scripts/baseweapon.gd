extends Node2D
class_name BaseWeapon

@export var ammo_type: String = "bullet"
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5
@export var damage: int = 1
@export var bullet_speed: float = 600.0
@export var bullet_scale: float = 1.0
@export var bullet_lifetime: float = 2.0
@export var bullet_count: int = 1
@export var spread_angle: float = 0.2

@export var shoot_sound: AudioStream

@onready var muzzle_flash: AnimatedSprite2D = $MuzzleFlash

var can_fire: bool = true

func fire(available_ammo: int, angle: float = 0.0) -> int:
	if not can_fire or available_ammo <= 0:
		return 0
		
	trigger_muzzle_flash()
	play_shoot_sound()
	
	var base_angle = angle if angle != 0.0 else global_rotation
	var bullets_to_fire = min(bullet_count, available_ammo)
	
	for i in range(bullets_to_fire):
		var final_angle = base_angle
		if bullets_to_fire > 1:
			final_angle += randf_range(-spread_angle, spread_angle)
		spawn_bullet(final_angle)
	
	_start_cooldown()
	
	return bullets_to_fire

func _start_cooldown() -> void:
	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func spawn_bullet(angle: float) -> void:
	if not bullet_scene: return
	
	var bullet = bullet_scene.instantiate()
	bullet.scale = Vector2(bullet_scale, bullet_scale)
	bullet.top_level = true 
	get_tree().current_scene.add_child(bullet)
	
	if has_node("Muzzle"):
		bullet.global_position = $Muzzle.global_position
	else:
		bullet.global_position = global_position
		
	bullet.global_rotation = angle
	bullet.direction = Vector2.RIGHT.rotated(angle)
	bullet.damage = damage
	bullet.speed = bullet_speed
	bullet.lifetime = bullet_lifetime

func trigger_muzzle_flash() -> void:
	if not muzzle_flash: return
	
	muzzle_flash.stop()
	muzzle_flash.frame = 0
	muzzle_flash.rotation = randf_range(-0.2, 0.2)
	muzzle_flash.z_index = 5
	muzzle_flash.visible = true
	muzzle_flash.play("flash")
	
	await muzzle_flash.animation_finished
	muzzle_flash.visible = false

func play_shoot_sound() -> void:
	if not shoot_sound: return
	
	var player = $AudioStreamPlayer2D as AudioStreamPlayer2D
	if player:
		player.stream = shoot_sound
		player.play()
