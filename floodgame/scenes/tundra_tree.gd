extends Node2D

@export var health: int = 3
@onready var sprite: Sprite2D = $Sprite2D

const TREE_WIDTH = 12.0
const TREE_HEIGHT = 26.0
const TREE_Y = 24.0

const TREE_X_POSITIONS = [18.0, 34.0]

func _ready() -> void:
	var chosen_x = TREE_X_POSITIONS.pick_random()
	
	sprite.region_rect = Rect2(chosen_x, TREE_Y, TREE_WIDTH, TREE_HEIGHT)
	
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
