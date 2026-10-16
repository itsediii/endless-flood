extends Area2D
class_name InteractionArea

@export var action_name: String = "interact"

signal interacted_with(player: CharacterBody2D)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func interact(player: CharacterBody2D) -> void:
	interacted_with.emit(player)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var parent = get_parent()
		
		if parent is WeaponPickup:
			body.overlapping_pickup = parent
		else:
			body.overlapping_animal = parent
			
		if parent.has_method("show_interaction_glow"):
			parent.show_interaction_glow()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		var parent = get_parent()
		
		if body.overlapping_pickup == parent:
			body.overlapping_pickup = null
		elif body.overlapping_animal == parent:
			body.overlapping_animal = null
			
		if parent.has_method("hide_interaction_glow"):
			parent.hide_interaction_glow()
