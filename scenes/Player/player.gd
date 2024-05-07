extends CharacterBody3D


@onready var input_handler = $InputHandler
@onready var camera = $Camera3D
@onready var gun = $Gun
@onready var gun_rect = $GunRect
@onready var ammo_count = $AmmoCount
@onready var xp_bar = $XPBar
@onready var ricochet_count_label = $RicochetCount
@onready var timer_label = $TimerLabel
@onready var death_screen = $DeathScreen
@onready var combo_gun = $ComboGun
@onready var dash_timer = $DashTimer
var player_move_speed = 5
var jump_speed = 5
var camera_sensitivity = 0.1
var xp = 0
var start_time = Time.get_unix_time_from_system()
var is_dead = false
var current_movement_state = PlayerMovementState.DEFAULT
var dash_speed = 80


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	input_handler.movement_inputted.connect(_on_input_handler_movement_inputted)
	input_handler.movement_pressed.connect(_on_input_handler_movement_pressed)
	input_handler.movement_released.connect(_on_input_handler_movement_released)
	input_handler.jump_pressed.connect(_on_input_handler_jump_pressed)
	input_handler.escape_pressed.connect(_on_input_handler_escape_pressed)
	input_handler.mouse_moved.connect(_on_input_handler_mouse_moved)
	input_handler.main_fire_pressed.connect(_on_input_handler_main_fire_pressed)
	input_handler.main_fire_released.connect(_on_input_handler_main_fire_released)
	input_handler.alt_fire_pressed.connect(_on_input_handler_alt_fire_pressed)
	input_handler.alt_fire_released.connect(_on_input_handler_alt_fire_released)
	input_handler.reload_pressed.connect(_on_input_handler_reload_pressed)
	input_handler.enter_pressed.connect(_on_input_handler_enter_pressed)
	
	gun.activation_changed.connect(_on_gun_activation_changed)
	gun.ammo_changed.connect(_on_gun_ammo_changed)
	gun.reload_state_changed.connect(_on_gun_reload_state_changed)
	
	dash_timer.timeout.connect(_on_dash_timer_timeout)


func _process(delta):
	if is_dead: return
	if current_movement_state == PlayerMovementState.DEFAULT:
		velocity.y -= Global.gravity_acceleration * delta
	elif current_movement_state == PlayerMovementState.DASHING:
		velocity.y = 0
	
	move_and_slide()
	
	var elapsed_time = Time.get_unix_time_from_system() - start_time
	timer_label.text = str(snapped(elapsed_time, 0.01))


func _on_input_handler_movement_inputted(input_vector: Vector2):
	if is_dead: return
	if current_movement_state == PlayerMovementState.DASHING: return
	
	input_vector = input_vector.rotated(get_rotation().y)
	input_vector = input_vector * player_move_speed
	velocity.x = input_vector.x
	velocity.z = -input_vector.y


func _on_input_handler_movement_pressed(direction):
	combo_gun.movement_pressed(direction)


func _on_input_handler_movement_released(direction):
	combo_gun.movement_released(direction)


func _on_input_handler_jump_pressed():
	if is_dead: return
	if is_on_floor():
		velocity.y = jump_speed


func _on_input_handler_escape_pressed():
	get_tree().quit()


func _on_input_handler_reload_pressed():
	if is_dead: return
	#gun.reload()


func _on_input_handler_mouse_moved(input_vector):
	if is_dead: return
	input_vector *= camera_sensitivity
	rotate_y(deg_to_rad(-input_vector.x))
	
	var new_camera_rotation = camera.get_rotation()
	new_camera_rotation.x = (new_camera_rotation.x - deg_to_rad(input_vector.y))
	new_camera_rotation.x = clampf(new_camera_rotation.x, -PI/2, PI/2)
	camera.set_rotation(new_camera_rotation)


func _on_input_handler_main_fire_pressed():
	if is_dead: return
	#gun.shoot()
	combo_gun.fire_pressed()


func _on_input_handler_main_fire_released():
	if is_dead: return
	combo_gun.fire_released()


func _on_input_handler_alt_fire_pressed():
	if is_dead: return
	#gun.alt_fire()
	combo_gun.alt_fire_pressed()


func _on_input_handler_alt_fire_released():
	if is_dead: return
	combo_gun.alt_fire_released()


func _on_input_handler_enter_pressed():
	if is_dead:
		get_tree().reload_current_scene()


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


func die():
	is_dead = true
	death_screen.show()


func dash(direction):
	current_movement_state = PlayerMovementState.DASHING
	
	var dash_vector: Vector3
	if direction == MovementDirection.FORWARD:
		dash_vector = Vector3.FORWARD
	elif direction == MovementDirection.BACK:
		dash_vector = Vector3.BACK
	elif direction == MovementDirection.RIGHT:
		dash_vector = Vector3.RIGHT
	elif direction == MovementDirection.LEFT:
		dash_vector = Vector3.LEFT
	dash_vector = dash_vector.rotated(Vector3.UP, rotation.y) * dash_speed
	
	velocity.x = dash_vector.x
	velocity.z = dash_vector.z
	dash_timer.start()


func _on_dash_timer_timeout():
	current_movement_state = PlayerMovementState.DEFAULT
