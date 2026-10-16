extends CharacterBody2D

enum Behavior { PASSIVE, NEUTRAL, AGGRESSIVE }
enum State { IDLE, WANDER, CHASE, FLEE, DEAD }

signal animal_collected(animal_node)

@export var animal_type: String = "bunny"
@export var personality: Behavior = Behavior.PASSIVE
@export var speed: float = 100.0
@export var max_health: int = 3
@export var attack_cooldown: float = 1.0
@export var attack_damage: float = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: InteractionArea = $InteractionArea

var current_state: State = State.IDLE
var health: int = max_health
var player_ref: CharacterBody2D = null
var is_aggroed_neutral: bool = false

var wander_direction: Vector2 = Vector2.ZERO
var state_timer: float = 0.0

var player_to_damage: Node2D = null
var attack_timer: float = 0.0

func _ready() -> void:
	health = max_health
	
	if interaction_area:
		interaction_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	pick_random_wander()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if player_to_damage and attack_timer <= 0.0:
		deal_damage_to_player()

	if current_state == State.IDLE or current_state == State.WANDER:
		state_timer -= delta
		if state_timer <= 0.0:
			pick_random_wander()

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			sprite.play("idle")
			
		State.WANDER:
			velocity = wander_direction * (speed * 0.5)
			sprite.play("run")
			if wander_direction.x != 0:
				sprite.flip_h = wander_direction.x < 0
			if is_on_wall():
				pick_random_wander()
			
		State.CHASE:
			if player_ref:
				var direction = (player_ref.global_position - global_position).normalized()
				velocity = direction * speed
				sprite.play("run")
				sprite.flip_h = direction.x < 0
				
		State.FLEE:
			if player_ref:
				var direction = (global_position - player_ref.global_position).normalized()
				velocity = direction * (speed * 1.3) 
				sprite.play("run")
				sprite.flip_h = direction.x < 0

	move_and_slide()

func pick_random_wander() -> void:
	if randf() < 0.5:
		current_state = State.IDLE
		state_timer = randf_range(5.5, 8.0)
	else:
		current_state = State.WANDER
		state_timer = randf_range(1.0, 3.0)
		var random_angle = randf_range(0, 2 * PI)
		wander_direction = Vector2(cos(random_angle), sin(random_angle))

func _on_detection_area_body_entered(body: Node2D) -> void:
	if current_state == State.DEAD: return 
	
	if body.is_in_group("player"):
		player_ref = body
		evaluate_behavior()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if current_state == State.DEAD: return 
	
	if body == player_ref:
		player_ref = null
		is_aggroed_neutral = false
		pick_random_wander()

func evaluate_behavior() -> void:
	if not player_ref or current_state == State.DEAD: return
	
	match personality:
		Behavior.PASSIVE:
			current_state = State.FLEE
		Behavior.AGGRESSIVE:
			current_state = State.CHASE
		Behavior.NEUTRAL:
			current_state = State.CHASE if is_aggroed_neutral else State.IDLE

func take_damage(amount: float) -> void:
	if current_state == State.DEAD: return
	
	health -= amount
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		
		if personality == Behavior.NEUTRAL or personality == Behavior.AGGRESSIVE:
			current_state = State.CHASE
		elif personality == Behavior.PASSIVE:
			current_state = State.FLEE
			
	if health <= 0:
		die()

func die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	player_to_damage = null
	
	set_collision_layer_value(2, false) 
	set_collision_mask_value(1, false)  
	set_collision_mask_value(2, false)  
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	if has_node("Hitbox"): 
		$Hitbox.process_mode = Node.PROCESS_MODE_DISABLED 
		
	sprite.play("death") 
	
	if interaction_area: 
		interaction_area.process_mode = Node.PROCESS_MODE_INHERIT

func _on_interaction_area_interacted_with(_player: CharacterBody2D) -> void:
	animal_collected.emit(self)
	queue_free()

func deal_damage_to_player() -> void:
	if player_to_damage and player_to_damage.has_method("take_damage"):
		player_to_damage.take_damage(roundi(attack_damage))
		attack_timer = attack_cooldown

func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state == State.DEAD: return

	if personality == Behavior.PASSIVE: return

	if body.is_in_group("player"):
		player_to_damage = body
		if attack_timer <= 0.0:
			deal_damage_to_player()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if player_to_damage == body:
			player_to_damage = null

func show_interaction_glow() -> void:
	pass

func hide_interaction_glow() -> void:
	pass
