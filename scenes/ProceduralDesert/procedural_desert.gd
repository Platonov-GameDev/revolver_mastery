extends StaticBody3D


@export var noise_texture: NoiseTexture2D
@export var big_noise_texture: NoiseTexture2D
@export var player: CharacterBody3D
@export var material: Material
@export var desert_chunk_scene: PackedScene
@onready var nav_region: NavigationRegion3D = get_parent()
@onready var player_vision_area = $PlayerVisionArea
@onready var chunks = $Chunks
var noise_image: Image
var big_noise_image: Image
var chunk_size = 5
var chunk_resolution = .05
var polygon_offset = 1 / chunk_resolution
var chunk_offset = polygon_offset * chunk_size
var chunk_grid = {}


func _ready():
	player_vision_area.body_entered.connect(_on_player_vision_area_body_entered)
	player_vision_area.body_exited.connect(_on_player_vision_area_body_exited)
	
	await noise_texture.changed
	noise_image = noise_texture.get_image()
	
	await big_noise_texture.changed
	big_noise_image = big_noise_texture.get_image()
	
	var new_chunk = spawn_chunk(Vector2.ZERO)


func _process(_delta):
	player_vision_area.position.x = player.position.x
	player_vision_area.position.z = player.position.z


func spawn_chunk(new_position: Vector2) -> DesertChunk:
	if chunk_grid.has(new_position): return
	
	var new_chunk = desert_chunk_scene.instantiate()
	new_chunk.position.x = new_position.x
	new_chunk.position.z = new_position.y
	new_chunk.chunk_size = chunk_size
	new_chunk.chunk_resolution = chunk_resolution
	new_chunk.material = material
	new_chunk.nav_region = nav_region
	new_chunk.noise_image = noise_image
	new_chunk.big_noise_image = big_noise_image
	
	chunks.add_child(new_chunk)
	chunk_grid[new_position] = new_chunk
	
	return new_chunk


func _on_player_vision_area_body_entered(body):
	var chunk = body
	var chunk_position = chunk.position
	
	spawn_chunk(Vector2(chunk_position.x + chunk_offset, chunk_position.z))
	spawn_chunk(Vector2(chunk_position.x, chunk_position.z + chunk_offset))
	spawn_chunk(Vector2(chunk_position.x - chunk_offset, chunk_position.z))
	spawn_chunk(Vector2(chunk_position.x, chunk_position.z - chunk_offset))


func _on_player_vision_area_body_exited(body):
	var chunk = body
	var chunk_position = chunk.position
	
	try_delete_chunk(Vector2(chunk_position.x + chunk_offset, chunk_position.z))
	try_delete_chunk(Vector2(chunk_position.x, chunk_position.z + chunk_offset))
	try_delete_chunk(Vector2(chunk_position.x - chunk_offset, chunk_position.z))
	try_delete_chunk(Vector2(chunk_position.x, chunk_position.z - chunk_offset))


func try_delete_chunk(chunk_position: Vector2):
	if not chunk_grid.has(chunk_position): return
	if player_vision_area.overlaps_body(chunk_grid[chunk_position]): return
	
	chunk_grid[chunk_position].queue_free()
	chunk_grid.erase(chunk_position)
