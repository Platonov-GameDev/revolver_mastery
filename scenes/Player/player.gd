extends CharacterBody3D


@onready var input_handler = $InputHandler
@onready var camera = $Camera3D
var player_move_speed = 5
var jump_speed = 5
var camera_sensitivity = 0.1


func _ready():
	input_handler.movement_inputted.connect(_on_input_handler_movement_inputted)
	input_handler.jump_pressed.connect(_on_input_handler_jump_pressed)
	input_handler.escape_pressed.connect(_on_input_handler_escape_pressed)
	input_handler.mouse_moved.connect(_on_input_handler_mouse_moved)
	input_handler.main_fire_pressed.connect(_on_input_handler_main_fire_pressed)
	input_handler.main_fire_released.connect(_on_input_handler_main_fire_released)
	input_handler.alt_fire_pressed.connect(_on_input_handler_alt_fire_pressed)
	input_handler.alt_fire_released.connect(_on_input_handler_alt_fire_released)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	
	move_and_slide()


func _on_input_handler_movement_inputted(input_vector: Vector2):
	input_vector = input_vector.rotated(get_rotation().y)
	input_vector = input_vector * player_move_speed
	velocity.x = input_vector.x
	velocity.z = -input_vector.y


func _on_input_handler_jump_pressed():
	if is_on_floor():
		velocity.y = jump_speed


func _on_input_handler_escape_pressed():
	get_tree().quit()


func _on_input_handler_mouse_moved(input_vector):
	input_vector *= camera_sensitivity
	rotate_y(deg_to_rad(-input_vector.x))
	
	var new_camera_rotation = camera.get_rotation()
	new_camera_rotation.x = (new_camera_rotation.x - deg_to_rad(input_vector.y))
	new_camera_rotation.x = clampf(new_camera_rotation.x, -PI/2, PI/2)
	camera.set_rotation(new_camera_rotation)


func _on_input_handler_main_fire_pressed():
	print("main fire pressed")


func _on_input_handler_main_fire_released():
	print("main fire released")


func _on_input_handler_alt_fire_pressed():
	print("alt fire pressed")


func _on_input_handler_alt_fire_released():
	print("alt fire released")
