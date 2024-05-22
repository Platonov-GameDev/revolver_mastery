extends StaticBody3D


@export var noise_texture: NoiseTexture2D
@export var big_noise_texture: NoiseTexture2D
@export var player: CharacterBody3D
@export var material: Material
@export var desert_chunk_scene: PackedScene
@onready var player_vision_area = $PlayerVisionArea
@onready var chunks = $Chunks
var noise_image: Image
var big_noise_image: Image
var chunk_size = 3
var chunk_resolution = .02
var polygon_offset = 1 / chunk_resolution
var chunk_offset = polygon_offset * chunk_size
var chunk_grid = {}


func _ready():
	player_vision_area.body_entered.connect(_on_player_vision_area_body_entered)
	player_vision_area.body_exited.connect(_on_player_vision_area_body_exited)
	
	noise_texture.noise.seed = randi()
	big_noise_texture.noise.seed = randi()
	
	if not noise_texture.get_image():
		await noise_texture.changed
	noise_image = noise_texture.get_image()
	
	if not big_noise_texture.get_image():
		await big_noise_texture.changed
	big_noise_image = big_noise_texture.get_image()
	
	spawn_chunk(Vector2.ZERO)


func _process(_delta):
	player_vision_area.position.x = player.position.x
	player_vision_area.position.z = player.position.z


func spawn_chunk(new_position: Vector2) -> DesertChunk:
	if chunk_grid.has(new_position): return
	
	var new_chunk = desert_chunk_scene.instantiate() as DesertChunk
	new_chunk.position.x = new_position.x
	new_chunk.position.z = new_position.y
	new_chunk.chunk_size = chunk_size
	new_chunk.chunk_resolution = chunk_resolution
	new_chunk.material = material
	new_chunk.noise_image = noise_image
	new_chunk.big_noise_image = big_noise_image
	
	chunks.add_child(new_chunk)
	chunk_grid[new_position] = new_chunk
	
	var has_structure = new_chunk.try_generate_structure()
	
	NavigationBaker.add_chunk(new_chunk)
	
	return new_chunk


func _on_player_vision_area_body_entered(body):
	var chunk = body.get_parent()
	var chunk_position = chunk.position
	
	spawn_chunk(Vector2(chunk_position.x + chunk_offset, chunk_position.z))
	spawn_chunk(Vector2(chunk_position.x, chunk_position.z + chunk_offset))
	spawn_chunk(Vector2(chunk_position.x - chunk_offset, chunk_position.z))
	spawn_chunk(Vector2(chunk_position.x, chunk_position.z - chunk_offset))


func _on_player_vision_area_body_exited(body):
	var chunk = body.get_parent()
	var chunk_position = chunk.position
	
	try_delete_chunk(Vector2(chunk_position.x + chunk_offset, chunk_position.z))
	try_delete_chunk(Vector2(chunk_position.x, chunk_position.z + chunk_offset))
	try_delete_chunk(Vector2(chunk_position.x - chunk_offset, chunk_position.z))
	try_delete_chunk(Vector2(chunk_position.x, chunk_position.z - chunk_offset))


func try_delete_chunk(chunk_position: Vector2):
	if not chunk_grid.has(chunk_position): return
	if player_vision_area.overlaps_body(chunk_grid[chunk_position].static_body_3d): return
	
	var chunk = chunk_grid[chunk_position]
	
	NavigationBaker.remove_chunk(chunk)
	chunk.queue_free()
	chunk_grid.erase(chunk_position)
