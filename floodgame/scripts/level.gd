extends Node2D

@onready var island_generator = $Island

var bunny_scene = preload("res://entities/animal/bunny.tscn")
var deer_scene = preload("res://entities/animal/deer.tscn")
var wolf_scene = preload("res://entities/animal/wolf.tscn")
var bear_scene = preload("res://entities/animal/bear.tscn")
var chest_scene = preload("res://scenes/chest.tscn")

var demon = preload("res://entities/demon/demon.tscn")
var devil = preload("res://entities/devil/devil.tscn")

@onready var enemy_tiers = [
	{"scene": demon, "cost": 1, "unlock_level": 1},
	{"scene": devil, "cost": 4, "unlock_level": 3}
]

@onready var player = $Entities/player

var level_quota = {}
var animals_collected = { "bunny": 0, "deer": 0, "wolf": 0, "bear": 0 }
var time_left: float = 0.0

@export var extra_animals: int = 3
var walkable_land: Array[Vector2i] = []


func _ready() -> void:
	start_new_level()
	
	var retry_btn = $CanvasLayer/GameOver/ButtonContainer/RetryButton
	var menu_btn = $CanvasLayer/GameOver/ButtonContainer/MenuButton
	
	var continue_btn = $CanvasLayer/Pause/ButtonContainer/ContinueButton
	var menu_btn2 = $CanvasLayer/Pause/ButtonContainer/MenuButton2
	
	var health_btn = $CanvasLayer/Upgrade/GridContainer/UpgradeHealth
	var speed_btn = $CanvasLayer/Upgrade/GridContainer/UpgradeSpeed
	var ammo_btn = $CanvasLayer/Upgrade/GridContainer/UpgradeMaxAmmo
	var chest_btn = $CanvasLayer/Upgrade/GridContainer/UpgradeChest
	var desc_label = $CanvasLayer/Upgrade/UpgradeDescriptionLabel
	
	var finish_btn = $CanvasLayer/Upgrade/Finish 
	
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
		
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if menu_btn2:
		menu_btn2.pressed.connect(_on_menu2_pressed)
		
	if finish_btn:
		finish_btn.pressed.connect(_on_next_level_pressed)
		
	if desc_label:
		if health_btn:
			health_btn.mouse_entered.connect(func(): desc_label.text = "Costs 4 Deer and 1 Wolf.\nIncreases maximum health. Blocks incoming danger.")
			health_btn.mouse_exited.connect(func(): desc_label.text = "")
			health_btn.pressed.connect(_on_upgrade_health_pressed)
			
		if speed_btn:
			speed_btn.mouse_entered.connect(func(): desc_label.text = "Costs 3 Bunnies and 1 Deer.\nIncreases movement speed. Grants nimble legs to outrun predators.")
			speed_btn.mouse_exited.connect(func(): desc_label.text = "")
			speed_btn.pressed.connect(_on_upgrade_speed_pressed)
			
		if ammo_btn:
			ammo_btn.mouse_entered.connect(func(): desc_label.text = "Costs 2 Deer and 1 Bear.\nIncreases maximum ammo capacity. Stockpile extra munitions.")
			ammo_btn.mouse_exited.connect(func(): desc_label.text = "")
			ammo_btn.pressed.connect(_on_upgrade_ammo_pressed)
			
		if chest_btn:
			chest_btn.mouse_entered.connect(func(): desc_label.text = "Costs 5 Bunnies and 1 Bear.\nIncreases luck. You find more ammo inside chests.")
			chest_btn.mouse_exited.connect(func(): desc_label.text = "")
			chest_btn.pressed.connect(_on_upgrade_chest_pressed)
			
	
	print("Ammo Button is: ", ammo_btn, " | Desc Label is: ", desc_label)
	
func start_new_level() -> void:
	RunManager.current_health = min(RunManager.current_health + 2.0, RunManager.max_health)
	
	animals_collected = { "bunny": 0, "deer": 0, "wolf": 0, "bear": 0 }
	
	island_generator.noise.seed = randi()
	island_generator.chosen_biome_id = island_generator.BIOMES.values().pick_random()
	
	var raw_land = island_generator.generate_island()
	
	walkable_land = get_largest_landmass(raw_land)
	
	generate_level_quota()
	spawn_player()
	spawn_animals()
	spawn_enemies()
	spawn_chests()
	update_ui_display()
	update_health_ui()
	start_timer()

func get_largest_landmass(all_land: Array[Vector2i]) -> Array[Vector2i]:
	var unvisited = {}
	for cell in all_land:
		unvisited[cell] = true
		
	var largest_island: Array[Vector2i] = []
	
	while unvisited.size() > 0:
		var start_cell = unvisited.keys()[0]
		var current_island: Array[Vector2i] = []
		var queue = [start_cell]
		
		unvisited.erase(start_cell)
		
		while queue.size() > 0:
			var cell = queue.pop_front()
			current_island.append(cell)
			
			var neighbors = [
				cell + Vector2i.UP,
				cell + Vector2i.DOWN,
				cell + Vector2i.LEFT,
				cell + Vector2i.RIGHT
			]
			
			for neighbor in neighbors:
				if unvisited.has(neighbor):
					unvisited.erase(neighbor)
					queue.append(neighbor)
					
		if current_island.size() > largest_island.size():
			largest_island = current_island
			
	return largest_island

func generate_level_quota() -> void:
	var level = RunManager.current_level
	
	if level == 1:
		level_quota = { "bunny": 2, "deer": 1, "wolf": 0, "bear": 0 }
	elif level == 2:
		level_quota = { "bunny": 3, "deer": 2, "wolf": 1, "bear": 0 }
	else:
		level_quota = {
			"bunny": randi_range(2, 2 + level),
			"deer": randi_range(1, 1 + level),
			"wolf": randi_range(0, level / 2),
			"bear": randi_range(0, level / 3)
		}

func spawn_animals() -> void:
	var animal_types = [bunny_scene, deer_scene, wolf_scene, bear_scene]
	var animals_to_spawn: Array = []
	
	var scene_mapping = {
		"bunny": bunny_scene,
		"deer": deer_scene,
		"wolf": wolf_scene,
		"bear": bear_scene
	}
	
	for type in level_quota:
		var count = level_quota[type]
		for i in range(count):
			animals_to_spawn.append(scene_mapping[type])

	for i in range(extra_animals):
		var random_animal_scene = animal_types.pick_random()
		animals_to_spawn.append(random_animal_scene)
		
	for random_animal_scene in animals_to_spawn:
		if random_animal_scene == null:
			continue
			
		var animal_instance = random_animal_scene.instantiate()
		var random_cell = walkable_land.pick_random()
		
		animal_instance.position = island_generator.tile_map_layer.map_to_local(random_cell)
		add_child(animal_instance)
		animal_instance.connect("animal_collected", Callable(self, "_on_animal_collected"))
		
func spawn_player() -> void:
	var border_tiles: Array[Vector2i] = []
	var spawn_pixel_pos = Vector2.ZERO
	for cell in walkable_land:
		var neighbors = [
			cell + Vector2i.UP,
			cell + Vector2i.DOWN,
			cell + Vector2i.LEFT,
			cell + Vector2i.RIGHT
		]
		for neighbor in neighbors:
			if not walkable_land.has(neighbor):
				border_tiles.append(cell)
				break 
	if border_tiles.size() > 0:
		var random_border_cell = border_tiles.pick_random()
		spawn_pixel_pos = island_generator.tile_map_layer.map_to_local(random_border_cell)
	elif walkable_land.size() > 0:
		var fallback_cell = walkable_land.pick_random()
		spawn_pixel_pos = island_generator.tile_map_layer.map_to_local(fallback_cell)
	player.global_position = island_generator.tile_map_layer.to_global(spawn_pixel_pos)
		
func _on_animal_collected(animal_node) -> void:
	var type = animal_node.animal_type
	
	if animals_collected.has(type):
		animals_collected[type] += 1
		
	update_ui_display()
	check_win_condition()

func check_win_condition() -> void:
	for type in level_quota:
		if animals_collected[type] < level_quota[type]:
			return
	win_level()

func win_level() -> void:
	$LevelTimer.stop()
	
	for animal_type in animals_collected:
		var amount_gathered = animals_collected[animal_type] 
		RunManager.total_animals_collected[animal_type] += amount_gathered
		print("Banked ", amount_gathered, " ", animal_type, "s!")
	
	if player:
		player.is_flying = true
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("run")
			
		if player.has_node("Camera2D"):
			var camera = player.get_node("Camera2D")
			var current_cam_pos = camera.global_position
			player.remove_child(camera)
			add_child(camera)
			camera.global_position = current_cam_pos

		var light_beam = Line2D.new()
		add_child(light_beam)
		light_beam.width = 16.0
		var beam_gradient = Gradient.new()
		
		beam_gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0)) 
		beam_gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0)) 
		
		light_beam.gradient = beam_gradient
		
		var beam_top = Vector2(player.global_position.x, player.global_position.y - 500.0)
		var beam_bottom = Vector2(player.global_position.x, player.global_position.y + 30.0)
		light_beam.add_point(beam_top)
		light_beam.add_point(beam_bottom)
		
		var tween = create_tween()
		var target_y = player.global_position.y - 600.0
		
		tween.set_parallel(true)
		
		tween.tween_property(player, "global_position:y", target_y, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		var beam_tween = create_tween()
		beam_tween.tween_property(light_beam, "modulate:a", 1.0, 0.2)
		beam_tween.tween_property(light_beam, "modulate:a", 0.0, 1.3) 
		
		tween.set_parallel(false)
		await tween.finished
		
		light_beam.queue_free()
		
	RunManager.add_score(500)
	var time_left_bonus = int($LevelTimer.time_left) * 10
	if time_left_bonus > 0:
		RunManager.add_score(time_left_bonus)
		
	RunManager.advance_level()
	
	if (RunManager.current_level - 1) % 2 == 0:
		
		if $CanvasLayer.has_node("GameplayUI"):
			$CanvasLayer/GameplayUI.visible = false
			
		update_wallet_display()
			
		if $CanvasLayer.has_node("Upgrade"):
			$CanvasLayer/Upgrade.visible = true
			
	else:
		get_tree().reload_current_scene()

func update_ui_display() -> void:
	var score_label = $CanvasLayer.get_node_or_null("GameplayUI/ScoreLabel")
	if score_label:
		score_label.text = "Score: " + str(RunManager.total_score)
	
	var display_text = "Targets:\n"
	for type in level_quota:
		var required = level_quota[type]
		if required > 0:
			var collected = animals_collected[type]
			var animal_name = type.capitalize()
			if collected >= required:
				display_text += "[color=green]" + animal_name + ": " + str(collected) + "/" + str(required) + " ✓[/color]\n"
			else:
				display_text += animal_name + ": " + str(collected) + "/" + str(required) + "\n"
				
	var quota_label = $CanvasLayer.get_node_or_null("GameplayUI/QuotaLabel")
	if quota_label:
		quota_label.text = display_text
		
func update_health_ui() -> void:
	var health_label = $CanvasLayer.get_node_or_null("GameplayUI/HealthLabel")
	if health_label:
		var current = RunManager.current_health
		var max_h = RunManager.max_health
		
		health_label.text = "HP: %d / %d" % [int(current), int(max_h)]
	
func start_timer() -> void:
	$LevelTimer.start(RunManager.current_level_time)
	
	if not $LevelTimer.timeout.is_connected(_on_level_timer_timeout):
		$LevelTimer.timeout.connect(_on_level_timer_timeout)

func toggle_pause() -> void:
	if $CanvasLayer.has_node("GameOver") and $CanvasLayer/GameOver.visible:
		return
		
	var tree = get_tree()
	tree.paused = !tree.paused
	$CanvasLayer/Pause.visible = tree.paused

func _on_continue_pressed() -> void:
	get_tree().paused = false
	$CanvasLayer/Pause.visible = false

func _on_menu2_pressed() -> void:
	get_tree().paused = false
	RunManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()
		
	if Input.is_key_pressed(KEY_R):
		game_over()
		
	if $LevelTimer.time_left > 0:
		update_timer_ui()
		
	update_health_ui()
	
	if player and player.get("is_dead") == true:
		if $CanvasLayer.has_node("GameOver") and not $CanvasLayer/GameOver.visible:
			game_over()

func update_timer_ui() -> void:
	var time_left_seconds = $LevelTimer.time_left
	
	var minutes = int(time_left_seconds) / 60
	var seconds = int(time_left_seconds) % 60
	var format_string = "%02d:%02d" % [minutes, seconds]
	
	$CanvasLayer/GameplayUI/CountdownLabel.text = "Time Left: " + format_string

func _on_level_timer_timeout() -> void:
	game_over()

func game_over() -> void:
	$LevelTimer.stop()
	
	if player:
		player.set_process(false)
		player.set_physics_process(false)
		
	if $CanvasLayer.has_node("GameplayUI"):
		$CanvasLayer/GameplayUI.visible = false
		
	var final_score_label = $CanvasLayer.get_node_or_null("GameOver/GameOverScoreLabel")
	if final_score_label:
		final_score_label.text = "Final Score: " + str(RunManager.total_score)
		
	if $CanvasLayer.has_node("GameOver"):
		$CanvasLayer/GameOver.visible = true
		
func _on_retry_pressed() -> void:
	RunManager.reset_run() 
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	RunManager.reset_run() 
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func spawn_enemies() -> void:
	var level = RunManager.current_level
	
	var raw_budget = 6 + (level * 3) 
	var budget = clampi(raw_budget, 0, 30)
	var roster = []
	
	var highest_tier_data = null
	for enemy in enemy_tiers:
		if level >= enemy.unlock_level:
			highest_tier_data = enemy
			
	if highest_tier_data and highest_tier_data.unlock_level > 1:
		if budget >= highest_tier_data.cost:
			roster.append(highest_tier_data.scene)
			budget -= highest_tier_data.cost

	while budget > 0:
		var available_purchases = []
		
		for enemy in enemy_tiers:
			if level >= enemy.unlock_level and budget >= enemy.cost:
				available_purchases.append(enemy)
				
		if available_purchases.size() == 0:
			break 
			
		var chosen_enemy = available_purchases.pick_random()
		roster.append(chosen_enemy.scene)
		budget -= chosen_enemy.cost

	var enemies_node = $Entities/Enemies
	if not enemies_node: return
	
	for enemy_scene in roster:
		if enemy_scene == null: continue
			
		var enemy_instance = enemy_scene.instantiate()
		var random_cell = walkable_land.pick_random()
		
		enemy_instance.position = island_generator.tile_map_layer.map_to_local(random_cell)
		enemies_node.add_child(enemy_instance)

func spawn_chests() -> void:
	var chests_node = $Entities/Chests
	
	var number_of_chests = 3 

	for i in range(number_of_chests):
		var chest_instance = chest_scene.instantiate()
		
		var random_cell = walkable_land.pick_random()
		
		chest_instance.position = island_generator.tile_map_layer.map_to_local(random_cell)
		
		chests_node.add_child(chest_instance)

func _on_upgrade_health_pressed() -> void:
	var wallet = RunManager.total_animals_collected
	
	if wallet["deer"] >= 4 and wallet["wolf"] >= 1:
		wallet["deer"] -= 4
		wallet["wolf"] -= 1
		
		RunManager.max_health += 4.0
		RunManager.current_health += 4.0 
		update_health_ui()
		update_wallet_display()

func _on_upgrade_speed_pressed() -> void:
	var wallet = RunManager.total_animals_collected
	
	if wallet["bunny"] >= 3 and wallet["deer"] >= 1:
		wallet["bunny"] -= 3
		wallet["deer"] -= 1
		
		RunManager.player_speed += 25.0
		update_wallet_display()

func _on_upgrade_ammo_pressed() -> void:
	var wallet = RunManager.total_animals_collected
	
	if wallet["deer"] >= 2 and wallet["bear"] >= 1:
		wallet["deer"] -= 2
		wallet["bear"] -= 1
		
		for type in RunManager.max_ammo:
			RunManager.max_ammo[type] = int(RunManager.max_ammo[type] * 1.30)
		update_wallet_display()

func _on_upgrade_chest_pressed() -> void:
	var wallet = RunManager.total_animals_collected
	
	if wallet["bunny"] >= 5 and wallet["bear"] >= 1:
		wallet["bunny"] -= 5
		wallet["bear"] -= 1
		
		RunManager.chest_reward_percentage += 0.10
		update_wallet_display()
		
func _on_next_level_pressed() -> void:
	if $CanvasLayer.has_node("Upgrade"):
		$CanvasLayer/Upgrade.visible = false
	get_tree().reload_current_scene()
	
func update_wallet_display() -> void:
	var wallet_label = $CanvasLayer/Upgrade/WalletLabel
	var wallet = RunManager.total_animals_collected
	
	if wallet_label:
		wallet_label.text = "Bank: %d Bunnies | %d Deer | %d Wolves | %d Bears" % [
			wallet["bunny"], 
			wallet["deer"], 
			wallet["wolf"], 
			wallet["bear"]
		]
