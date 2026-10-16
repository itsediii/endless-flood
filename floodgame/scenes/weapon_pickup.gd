extends Node2D
class_name WeaponPickup

@export var weapon_name: String = "Pistol"
@export var pickup_texture: Texture2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var interaction_area: InteractionArea = $InteractionArea

var weapon_regions = {
	"Pistol": Rect2(0.0, 118.0, 12.0, 10.0),
	"AssaultRifle": Rect2(128.0, 100.0, 26.0, 12.0),
	"Shotgun": Rect2(64.0, 85.0, 32.0, 11.0)
}

func _ready() -> void:
	setup_weapon_visual()
	
	if interaction_area:
		interaction_area.interacted_with.connect(_on_interaction_area_interacted_with)
		
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.overlapping_pickup = self

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.overlapping_pickup == self:
			body.overlapping_pickup = null

func setup_weapon_visual() -> void:
	if sprite_2d and weapon_regions.has(weapon_name):
		sprite_2d.region_enabled = true
		sprite_2d.region_rect = weapon_regions[weapon_name]

func setup_pickup(new_name: String, new_texture: Texture2D) -> void:
	weapon_name = new_name
	if new_texture:
		sprite_2d.texture = new_texture
	
	if is_inside_tree():
		setup_weapon_visual()

func _on_interaction_area_interacted_with(player: CharacterBody2D) -> void:
	var empty_slot_index = RunManager.equipped_weapons.find("")
	
	if empty_slot_index != -1:
		RunManager.equipped_weapons[empty_slot_index] = weapon_name
		RunManager.current_weapon_index = empty_slot_index
		
	else:
		var current_slot = RunManager.current_weapon_index
		var old_weapon_name = RunManager.equipped_weapons[current_slot]
		
		RunManager.equipped_weapons[current_slot] = weapon_name
				
		if old_weapon_name != "" and player.pickup_scene:
			var dropped = player.pickup_scene.instantiate()
			dropped.global_position = global_position
			
			dropped.z_index = z_index
			
			var old_weapon_node = player.get_node("Weapons/" + old_weapon_name)
			var old_texture = old_weapon_node.get_node("GunSprite").texture
			
			get_tree().current_scene.add_child(dropped)
			dropped.setup_pickup(old_weapon_name, old_texture)
	
	player.update_weapon_nodes()
	
	player.overlapping_pickup = null 
		
	queue_free()
