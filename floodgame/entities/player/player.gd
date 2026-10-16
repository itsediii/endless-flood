extends CharacterBody2D

var is_dead: bool = false

var current_weapon: Node2D

const pickup_scene = preload("res://scenes/weapon_pickup.tscn")

var overlapping_pickup = null
var overlapping_animal: Node2D = null

var is_flying: bool = false

func _ready() -> void:
	update_weapon_nodes()

func _physics_process(_delta: float) -> void:
	if is_flying or is_dead:
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * RunManager.player_speed
		$AnimatedSprite2D.play("run")
		
		if $FootstepsTimer and $FootstepsTimer.is_stopped():
			if $Footsteps:
				$Footsteps.play()
			$FootstepsTimer.start()
		
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = true
		elif direction.x > 0:
			$AnimatedSprite2D.flip_h = false
	else:
		velocity = velocity.move_toward(Vector2.ZERO, RunManager.player_speed)
		$AnimatedSprite2D.play("idle")
		
		if $FootstepsTimer:
			$FootstepsTimer.stop()

	move_and_slide()
	
func _process(_delta: float) -> void:
	if is_flying or is_dead:
		return 
	
	if Input.is_action_just_pressed("swap_weapon"):
		try_swap_weapon()
		
	if Input.is_action_just_pressed("interact"):
		if is_instance_valid(overlapping_pickup):
			var area_component = overlapping_pickup.get_node_or_null("InteractionArea")
			if area_component:
				area_component.interact(self)
		else:
			overlapping_pickup = null
				
		if is_instance_valid(overlapping_animal):
			var area_component = overlapping_animal.get_node_or_null("InteractionArea")
			if area_component:
				area_component.interact(self)

	if current_weapon:
		var mouse_pos = get_global_mouse_position()
		current_weapon.look_at(mouse_pos)
		
		var weapon_sprite = current_weapon.get_node_or_null("GunSprite") 
		if weapon_sprite:
			if mouse_pos.x < global_position.x:
				weapon_sprite.flip_v = true
			else:
				weapon_sprite.flip_v = false
			
	if Input.is_action_pressed("fire"):
		var ammo_type = current_weapon.get("ammo_type")
		if ammo_type != null and RunManager.ammo_inventory.has(ammo_type):
			var available = RunManager.ammo_inventory[ammo_type]
			if available > 0:
				var ammo_used = current_weapon.fire(available)
				RunManager.ammo_inventory[ammo_type] -= ammo_used
		else:
			current_weapon.fire(999)

func try_swap_weapon() -> void:
	var next_index = 1 - RunManager.current_weapon_index
	if RunManager.equipped_weapons[next_index] != "":
		RunManager.current_weapon_index = next_index
		update_weapon_nodes()

func update_weapon_nodes() -> void:
	var all_possible_weapons = ["Pistol", "AssaultRifle", "Shotgun"]
	
	for weapon_name in all_possible_weapons:
		if $Weapons.has_node(weapon_name):
			var weapon_node = $Weapons.get_node(weapon_name)
			weapon_node.visible = false
			weapon_node.process_mode = Node.PROCESS_MODE_DISABLED

	var active_weapon_name = RunManager.equipped_weapons[RunManager.current_weapon_index]
	if active_weapon_name != "" and $Weapons.has_node(active_weapon_name):
		current_weapon = $Weapons.get_node(active_weapon_name)
		current_weapon.visible = true
		current_weapon.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		current_weapon = null
		
func take_damage(amount: float) -> void:
	if is_dead or is_flying:
		return
		
	RunManager.current_health -= amount
	
	if RunManager.current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	RunManager.current_health = 0
	velocity = Vector2.ZERO
	
	if $Death:
		$Death.play()
	
	if $AnimatedSprite2D.sprite_frames.has_animation("death"):
		$AnimatedSprite2D.play("death")
	else:
		$AnimatedSprite2D.play("idle")
		
	if current_weapon:
		current_weapon.visible = false
