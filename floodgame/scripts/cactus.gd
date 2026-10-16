extends Node2D

@export var health: int = 3
@onready var sprite: Sprite2D = $Sprite2D

const CACTUS_VARIANTS = [
	{"x": 19.0, "y": 19.0, "w": 10.0, "h": 25.0}, 
	{"x": 35.0, "y": 27.0, "w": 10.0, "h": 17.0}, 
	{"x": 50.0, "y": 27.0, "w": 12.0, "h": 17.0} 
]

func _ready() -> void:
	var data = CACTUS_VARIANTS.pick_random()
	
	sprite.region_rect = Rect2(data["x"], data["y"], data["w"], data["h"])
	
	sprite.offset.y = -(data["h"] / 2.0)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
