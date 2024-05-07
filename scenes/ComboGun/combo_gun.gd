extends Node3D


# GENERAL
@export var camera: Camera3D
@export var trail_scene: PackedScene
@onready var down_timer = $DownTimer
enum State {IDLE, DOWN}
var current_state = State.IDLE

# DASH
var last_movement_time = 0
var last_movement_direction
var dash_move_tap_window = .1
var is_dash_move_done = false
var is_dash_shoot_done = false
var dash_prepared_time = 0
var dash_preparation_window = .1


func _ready():
	down_timer.timeout.connect(_on_down_timer_timeout)


func _process(_delta):
	process_dash()


func movement_pressed(direction):
	if get_parent().current_movement_state == PlayerMovementState.DASHING: return
	last_movement_direction = direction
	last_movement_time = Time.get_unix_time_from_system()


func movement_released(direction):
	if get_parent().current_movement_state == PlayerMovementState.DASHING: return
	if direction != last_movement_direction: return
	var current_time = Time.get_unix_time_from_system()
	var time_since_movement_press = current_time - last_movement_time
	if time_since_movement_press < dash_move_tap_window:
		if is_dash_shoot_done:
			dash()
		else:
			dash_prepared_time = Time.get_unix_time_from_system()
			is_dash_move_done = true


func process_dash():
	var current_time = Time.get_unix_time_from_system()
	var time_since_dash_preparation = current_time - dash_prepared_time
	if time_since_dash_preparation > dash_preparation_window:
		is_dash_move_done = false
		is_dash_shoot_done = false


func dash():
	is_dash_move_done = false
	is_dash_shoot_done = false
	get_parent().dash(last_movement_direction)


func fire_pressed():
	if current_state != State.IDLE: return
	
	if is_dash_move_done:
		dash()
	else:
		dash_prepared_time = Time.get_unix_time_from_system()
		is_dash_shoot_done = true
	
	var raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	raycast.set_collision_mask_value(1, true)
	raycast.set_collision_mask_value(2, true)
	get_parent().get_parent().add_child(raycast)
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	if collider:
		if collider.is_in_group("enemy"):
			collider.receive_damage(30)
	
	var shot_trail = trail_scene.instantiate()
	shot_trail.scale.z = raycast.position.distance_to(raycast.get_collision_point()) / 100
	shot_trail.position = global_position
	shot_trail.rotation = camera.global_rotation
	get_parent().get_parent().add_child(shot_trail)
	
	raycast.queue_free()
	
	current_state = State.DOWN
	down_timer.start()


func fire_released():
	pass


func alt_fire_pressed():
	pass


func alt_fire_released():
	pass


func _on_down_timer_timeout():
	current_state = State.IDLE
