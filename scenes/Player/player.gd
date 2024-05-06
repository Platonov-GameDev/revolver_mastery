extends CharacterBody3D


@onready var input_handler = $InputHandler
@onready var camera = $Camera3D
@onready var gun = $Gun
@onready var gun_rect = $GunRect
@onready var ammo_count = $AmmoCount
@onready var xp_bar = $XPBar
@onready var ricochet_count_label = $RicochetCount
var player_move_speed = 5
var jump_speed = 5
var camera_sensitivity = 0.1
var xp = 0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	input_handler.movement_inputted.connect(_on_input_handler_movement_inputted)
	input_handler.jump_pressed.connect(_on_input_handler_jump_pressed)
	input_handler.escape_pressed.connect(_on_input_handler_escape_pressed)
	input_handler.mouse_moved.connect(_on_input_handler_mouse_moved)
	input_handler.main_fire_pressed.connect(_on_input_handler_main_fire_pressed)
	input_handler.main_fire_released.connect(_on_input_handler_main_fire_released)
	input_handler.alt_fire_pressed.connect(_on_input_handler_alt_fire_pressed)
	input_handler.alt_fire_released.connect(_on_input_handler_alt_fire_released)
	input_handler.reload_pressed.connect(_on_input_handler_reload_pressed)
	
	gun.activation_changed.connect(_on_gun_activation_changed)
	gun.ammo_changed.connect(_on_gun_ammo_changed)
	gun.reload_state_changed.connect(_on_gun_reload_state_changed)


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


func _on_input_handler_reload_pressed():
	gun.reload()


func _on_input_handler_mouse_moved(input_vector):
	input_vector *= camera_sensitivity
	rotate_y(deg_to_rad(-input_vector.x))
	
	var new_camera_rotation = camera.get_rotation()
	new_camera_rotation.x = (new_camera_rotation.x - deg_to_rad(input_vector.y))
	new_camera_rotation.x = clampf(new_camera_rotation.x, -PI/2, PI/2)
	camera.set_rotation(new_camera_rotation)


func _on_input_handler_main_fire_pressed():
	gun.shoot()


func _on_input_handler_main_fire_released():
	print("main fire released")


func _on_input_handler_alt_fire_pressed():
	gun.alt_fire()


func _on_input_handler_alt_fire_released():
	print("alt fire released")


func _on_gun_activation_changed(is_active):
	if is_active:
		gun_rect.color = Color(1, 1, 1)
	elif !is_active:
		gun_rect.color = Color(.3, .3, .3)


func _on_gun_ammo_changed(new_ammo):
	ammo_count.text = str(new_ammo)


func _on_gun_reload_state_changed(is_reloading):
	if is_reloading:
		gun_rect.color = Color(1, 1, 0)
	elif !is_reloading:
		gun_rect.color = Color(1, 1, 1)


func collect_xp(value):
	xp += 5. * value / clampi(gun.ricochet_count, 1, 20)
	if xp >= 100:
		xp = 0
		gun.ricochet_count += 1
	
	xp_bar.value = xp
	ricochet_count_label.text = str(gun.ricochet_count)
