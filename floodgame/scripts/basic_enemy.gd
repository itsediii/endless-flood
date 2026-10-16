extends CharacterBody2D

@export var max_health: float = 3.0
@export var walk_speed: float = 50.0
@export var chase_speed: float = 120.0
@export var patrol_interval: float = 3.0
@export var attack_cooldown: float = 1.0
@export var attack_damage: float = 1.0

enum State { IDLE, PATROL, CHASE, DEAD }
var current_state: State = State.IDLE
var current_health: float = max_health

var patrol_direction: Vector2 = Vector2.ZERO
var player: Node2D = null

var attack_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var patrol_timer: Timer = $PatrolTimer
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	current_health = max_health * RunManager.enemy_hp_multiplier
	patrol_timer.wait_time = patrol_interval
	patrol_timer.start()
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if attack_timer > 0.0:
		attack_timer -= delta
	else:
		for body in hitbox.get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(roundi(attack_damage * RunManager.enemy_damage_multiplier)) 
				attack_timer = attack_cooldown
				break 

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			animated_sprite.play("idle")
			
		State.PATROL:
			velocity = patrol_direction * walk_speed
			animated_sprite.play("walk")
			if velocity.x != 0:
				animated_sprite.flip_h = velocity.x < 0
				
		State.CHASE:
			if player:
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * chase_speed
				animated_sprite.play("run")
				if velocity.x != 0:
					animated_sprite.flip_h = velocity.x < 0
			else:
				current_state = State.IDLE

	move_and_slide()

func _on_patrol_timer_timeout() -> void:
	if current_state == State.DEAD or current_state == State.CHASE:
		return

	if randf() > 0.5:
		current_state = State.PATROL
		var random_angle = randf() * PI * 2
		patrol_direction = Vector2.RIGHT.rotated(random_angle)
	else:
		current_state = State.IDLE

func _on_detection_area_body_entered(body: Node2D) -> void:
	if current_state == State.DEAD: return 
	
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body: Node2D) -> void:
	if current_state == State.DEAD: return 
	
	if body == player:
		player = null
		current_state = State.IDLE

func take_damage(amount: float) -> void:
	if current_state == State.DEAD: return
	
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	if current_state == State.DEAD:
		return
		
	current_state = State.DEAD
	velocity = Vector2.ZERO
	
	if has_node("Hitbox"): 
		hitbox.process_mode = Node.PROCESS_MODE_DISABLED 
		
	animated_sprite.play("death")
	animated_sprite.animation_finished.connect(_on_death_animation_finished)

func _on_death_animation_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.pause()
		animated_sprite.modulate = Color(0.35, 0.35, 0.35, 1.0)
		
		collision_layer = 0
		collision_mask = 0
		
