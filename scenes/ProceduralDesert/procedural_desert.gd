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


func _ready():
	player_vision_area.body_entered.connect(_on_player_vision_area_body_entered)
	player_vision_area.body_exited.connect(_on_player_vision_area_body_exited)
	
	await noise_texture.changed
	noise_image = noise_texture.get_image()
	
	await big_noise_texture.changed
	big_noise_image = big_noise_texture.get_image()
	
	spawn_chunk(Vector2.ZERO)


func _process(_delta):
	player_vision_area.position.x = player.position.x
	player_vision_area.position.z = player.position.z


func spawn_chunk(new_position: Vector2, initiator_chunk = null) -> DesertChunk:
	for chunk in chunks.get_children():
		if chunk.position.x == new_position.x and chunk.position.z == new_position.y and is_instance_valid(chunk):
			return null
	
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
	
	if initiator_chunk:
		initiator_chunk.neighbour_chunks.append(new_chunk)
		new_chunk.neighbour_chunks.append(initiator_chunk)
	
	return new_chunk


func _on_player_vision_area_body_entered(body):
	var chunk = body
	var chunk_position = chunk.position
	
	var polygon_offset = 1 / chunk_resolution
	var chunk_offset = polygon_offset * chunk_size
	spawn_chunk(Vector2(chunk_position.x + chunk_offset, chunk_position.y), chunk)
	spawn_chunk(Vector2(chunk_position.x, chunk_position.y + chunk_offset), chunk)
	spawn_chunk(Vector2(chunk_position.x - chunk_offset, chunk_position.y), chunk)
	spawn_chunk(Vector2(chunk_position.x, chunk_position.y - chunk_offset), chunk)


func _on_player_vision_area_body_exited(body):
	var chunk = body
	
	for neighbour_chunk in chunk.neighbour_chunks:
		if not is_instance_valid(neighbour_chunk): continue
		if player_vision_area.overlaps_body(neighbour_chunk): continue
		neighbour_chunk.queue_free()
