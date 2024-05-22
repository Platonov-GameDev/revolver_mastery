extends NavigationRegion3D
class_name DesertChunk


@export var structure_scene: PackedScene
@onready var collision_shape_3d = $StaticBody3D/CollisionShape3D
@onready var static_body_3d = $StaticBody3D
@onready var player_detection_area = $PlayerDetectionArea

var chunk_size: int
var chunk_resolution: float
var material: Material
var noise_image: Image
var big_noise_image: Image

var st = SurfaceTool.new()
var has_structure := false
var structure


func _ready():
	player_detection_area.body_entered.connect(_on_player_detection_area_body_entered)
	player_detection_area.body_exited.connect(_on_player_detection_area_body_exited)
	
	static_body_3d.set_collision_layer_value(6, true)
	var mesh_instance = MeshInstance3D.new()
	static_body_3d.add_child(mesh_instance)
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			var polygon_offset = 1 / chunk_resolution
			var mult_x = (x - chunk_size / 2.) * polygon_offset
			var mult_y = (y - chunk_size / 2.) * polygon_offset
			
			add_vertex(mult_x, mult_y)
			add_vertex(mult_x + polygon_offset, mult_y)
			add_vertex(mult_x, mult_y + polygon_offset)
			
			add_vertex(mult_x, mult_y + polygon_offset)
			add_vertex(mult_x + polygon_offset, mult_y)
			add_vertex(mult_x + polygon_offset, mult_y + polygon_offset)
	
	var new_mesh = st.commit()
	mesh_instance.mesh = new_mesh
	mesh_instance.material_override = material
	
	var new_collision_shape = ConcavePolygonShape3D.new()
	new_collision_shape.set_faces(new_mesh.get_faces())
	collision_shape_3d.shape = new_collision_shape


func add_vertex(x: int, y: int):
	st.set_normal(Vector3(0, 1, 0))
	
	var noise_x = int(x + position.x)
	var noise_y = int(y + position.z)
	
	var small_offset = get_noise_image_pixel_height(noise_image, noise_x, noise_y) * 10 - 10
	var big_offset = get_noise_image_pixel_height(big_noise_image, noise_x, noise_y) * 50 - 30
	
	st.add_vertex(Vector3(x, small_offset + big_offset, y))


func get_noise_image_pixel_height(image: Image, x, y):
	var width = image.get_width() - 1
	var height = image.get_height() - 1
	
	if x <= 0: x = width + x % width
	elif x >= width: x = x % width
	if y <= 0: y = height + y % width
	elif y >= height: y = y % width
	
	return image.get_pixel(x, y).r


func try_generate_structure():
	#if randi() % 100 < 10:
	has_structure = true
	
	structure = structure_scene.instantiate()
	add_child(structure)
	
	return has_structure


func _on_player_detection_area_body_entered(body):
	var player = body
	if has_structure:
		structure.spawn_impulse_timer.start()
		structure.player = player
	
	enabled = true


func _on_player_detection_area_body_exited(_body):
	enabled = false
