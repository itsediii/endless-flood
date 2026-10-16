extends Node2D
class_name AnimalPickup

@export var animal_type: String = "deer"

@onready var interaction_area: InteractionArea = $InteractionArea

signal animal_collected(animal_node: Node2D)

func _ready() -> void:
	if interaction_area:
		interaction_area.interacted_with.connect(_on_interaction_area_interacted_with)

func _on_interaction_area_interacted_with(_player: CharacterBody2D) -> void:    
	animal_collected.emit(self)
	queue_free()
