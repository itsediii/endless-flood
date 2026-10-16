extends Area2D

@onready var sprite = $Sprite2D
@onready var spawn_point = $Marker2D
@onready var open_sound = $OpenSound

var closed_rect = Rect2(2, 14, 12, 14) 
var open_rect = Rect2(18, 8, 12, 20)  

var weapons = [
	"Pistol",
	"AssaultRifle",
	"Shotgun"
]

var ammo_types = [
	"bullet",
	"shell"
]

var is_open = false

const PICKUP_SCENE = preload("res://scenes/weapon_pickup.tscn")

func _ready():
	sprite.region_rect = closed_rect
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not is_open and body.is_in_group("player"):
		open_chest()

func open_chest():
	is_open = true
	sprite.region_rect = open_rect
	open_sound.play()
	
	var random_weapon_name = weapons.pick_random()
	spawn_item(random_weapon_name)
	
	for current_ammo_type in ammo_types:
		var max_capacity = RunManager.max_ammo[current_ammo_type]
		
		var ammo_amount = int(max_capacity * RunManager.chest_reward_percentage) 
		
		RunManager.ammo_inventory[current_ammo_type] += ammo_amount
		
		if RunManager.ammo_inventory[current_ammo_type] > max_capacity:
			RunManager.ammo_inventory[current_ammo_type] = max_capacity
		

	
func spawn_item(weapon_name: String):
	if PICKUP_SCENE:
		var item_instance = PICKUP_SCENE.instantiate()
		item_instance.weapon_name = weapon_name
		item_instance.z_index = z_index + 1 
		
		if spawn_point:
			item_instance.global_position = spawn_point.global_position
		else:
			item_instance.global_position = global_position
		
		get_tree().current_scene.call_deferred("add_child", item_instance)
