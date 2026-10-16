extends Node2D

@onready var tile_map_layer: TileMapLayer = $IslandLayer

@export var map_width: int = 80
@export var map_height: int = 80
@export_range(0.0, 1.0) var tree_density: float = 0.06

var noise: FastNoiseLite

const BIOMES = {
	"DESERT": 0,
	"TAIGA": 1,
	"TUNDRA": 2
}

const TILE_WATER = Vector2i(4, 7)           

const CACTUS_SCENE = preload("res://scenes/cactus.tscn")
const TAIGA_TREE_SCENE = preload("res://scenes/taiga_tree.tscn")
const TUNDRA_TREE_SCENE = preload("res://scenes/tundra_tree.tscn")

const TREE_SCENES = {
	0: CACTUS_SCENE,
	1: TAIGA_TREE_SCENE,
	2: TUNDRA_TREE_SCENE
}

var chosen_biome_id: int
var tree_health_pool = {}

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.03 
	
	chosen_biome_id = BIOMES.values().pick_random()

func generate_island() -> Array[Vector2i]:
	var land_cells: Array[Vector2i] = []
	clear_old_trees()
	
	tile_map_layer.clear()
	tree_health_pool.clear()
	
	var floor_cells: Array[Vector2i] = []
	var vertical_offset: float = -0.2 
	
	for x in range(map_width):
		for y in range(map_height):
			var noise_val = noise.get_noise_2d(x, y)
			
			var nx = 2.0 * x / map_width - 1.0
			var ny = 2.0 * y / map_height - 1.0 + vertical_offset
			
			var distance = max(abs(nx), abs(ny)) 
			var center_gradient = 1.0 - distance
			var final_value = (center_gradient * 0.8) + (noise_val * 0.3)
			
			var cell_pos = Vector2i(x, y)
			
			if final_value > 0.4:
				floor_cells.append(cell_pos)
			else:
				tile_map_layer.set_cell(cell_pos, chosen_biome_id, TILE_WATER)
				
	tile_map_layer.set_cells_terrain_connect(floor_cells, chosen_biome_id, 0, chosen_biome_id)
	
	spawn_trees(floor_cells)
	return floor_cells

func spawn_trees(floor_cells: Array[Vector2i]) -> void:
	var active_tree_scene = TREE_SCENES[chosen_biome_id]
	
	if active_tree_scene == null:
		return
		
	for cell_pos in floor_cells:
		if randf() < tree_density:
			var tree_instance = active_tree_scene.instantiate()
			
			var pixel_position = tile_map_layer.map_to_local(cell_pos)
			tree_instance.position = pixel_position
			
			tree_instance.add_to_group("spawned_trees")
			
			add_child(tree_instance)

func clear_old_trees() -> void:
	var old_trees = get_tree().get_nodes_in_group("spawned_trees")
	for tree in old_trees:
		tree.queue_free()
