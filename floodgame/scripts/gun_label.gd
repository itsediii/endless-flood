extends Label

@export var player: CharacterBody2D

func _process(_delta: float) -> void:
	if player == null:
		return
		
	var active_weapon = RunManager.equipped_weapons[RunManager.current_weapon_index]
	
	var current_ammo = 0
	var ammo_name = ""
	
	if active_weapon == "Shotgun":
		ammo_name = "Shells"
		current_ammo = RunManager.ammo_inventory["shell"]
	elif active_weapon == "Pistol" or active_weapon == "AssaultRifle":
		ammo_name = "Bullets"
		current_ammo = RunManager.ammo_inventory["bullet"]
		
	text = active_weapon + "\n" + ammo_name + ": " + str(current_ammo)
