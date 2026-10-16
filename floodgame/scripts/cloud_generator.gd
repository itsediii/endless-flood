@tool
extends Node2D

const CLOUDS_FOLDER = "res://assets/Clouds_black/"

@export var cloud_count: int = 15:
	set(value):
		cloud_count = value
		if Engine.is_editor_hint():
			generate_clouds()

@export var min_distance: float = 120.0:
	set(value):
		min_distance = value

func _ready():
	generate_clouds()

func generate_clouds():
	for child in get_children():
		child.queue_free()

	var master_cloud_deck: Array = []
	for shape_num in range(2, 6):
		var folder_path = CLOUDS_FOLDER + "Shape" + str(shape_num) + "/"
		var folder_files = get_png_files_in_folder(folder_path)
		master_cloud_deck.append_array(folder_files)
		
	if cloud_count > master_cloud_deck.size():
		print("Warning: Cloud count is higher than total unique assets. Capping count.")
		cloud_count = master_cloud_deck.size()

	master_cloud_deck.shuffle()

	var screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")

	for i in range(cloud_count):
		var unique_cloud_path = master_cloud_deck.pop_front()
		
		var safe_position = find_safe_position(screen_width)
		spawn_cloud_sprite(unique_cloud_path, safe_position)

func find_safe_position(screen_width: float) -> Vector2:
	var max_attempts = 50
	
	for attempt in range(max_attempts):
		var test_x = randf_range(0, screen_width)
		var test_y = randf_range(10, 160) 
		var test_pos = Vector2(test_x, test_y)
		
		var spot_is_safe = true
		for existing_cloud in get_children():
			if existing_cloud is Sprite2D:
				if test_pos.distance_to(existing_cloud.position) < min_distance:
					spot_is_safe = false
					break
					
		if spot_is_safe:
			return test_pos
			
	return Vector2(randf_range(0, screen_width), randf_range(10, 160))

func get_png_files_in_folder(folder_path: String) -> Array:
	var files = []
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".png") or file_name.ends_with(".png.import"):
					var clean_name = file_name.replace(".import", "")
					var full_path = folder_path + clean_name
					if not files.has(full_path):
						files.append(full_path)
			file_name = dir.get_next()
	return files

func spawn_cloud_sprite(texture_path: String, spawn_pos: Vector2):
	var new_sprite = Sprite2D.new()
	new_sprite.texture = load(texture_path)
	new_sprite.position = spawn_pos
	
	var random_scale = randf_range(0.8, 1.2)
	new_sprite.scale = Vector2(random_scale, random_scale)
	
	add_child(new_sprite)
