extends Node

var current_level: int = 1
var total_score: int = 0
var enemy_hp_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0

var starter_time: float = 300.0 
var minimum_time: float = 120.0
var current_level_time: float = 300.0

var max_health: float = 12.0
var current_health: float = max_health
var player_speed = 150

var ammo_inventory = {"bullet": 80, "shell": 24}
var max_ammo = {"bullet": 255, "shell": 72}

var chest_reward_percentage: float = 0.20

var equipped_weapons = ["Shotgun", "Pistol"]
var current_weapon_index = 0 

var total_animals_collected = { "bunny": 0, "deer": 0, "wolf": 0, "bear": 0 }

func advance_level() -> void:
	current_level += 1
	
	enemy_hp_multiplier = 1.0 + ((current_level - 1) * 0.2)
	enemy_damage_multiplier = 1.0 + ((current_level - 1) * 0.15)
	
	var time_loss = (current_level - 1) * 15.0
	current_level_time = max(starter_time - time_loss, minimum_time)
	
func add_score(amount: int) -> void:
	var scaled_points = amount * current_level
	total_score += scaled_points

func reset_run() -> void:
	current_level = 1
	total_score = 0
	current_level_time = starter_time
	current_health = max_health
	enemy_hp_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	ammo_inventory = {"bullet": 80, "shell": 24}
	equipped_weapons = ["Shotgun", "Pistol"]
	current_weapon_index = 0
