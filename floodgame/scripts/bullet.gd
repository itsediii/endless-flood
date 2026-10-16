extends Area2D
class_name BaseBullet

var speed: float = 600.0
var damage: float = 1.0 # Changed to float to match the trees/player health safely!
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0

var time_alive: float = 0.0

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
	
func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	
	if parent and "current_state" in parent and parent.current_state == parent.State.DEAD:
		return
		
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
	elif parent and parent.has_method("take_damage"):
		parent.take_damage(damage)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if "current_state" in body and body.current_state == body.State.DEAD:
		return
		
	if body.is_in_group("player"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	queue_free()
