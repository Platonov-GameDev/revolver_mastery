extends Node3D


# GENERAL
@export var camera: Camera3D
@export var trail_scene: PackedScene
@onready var down_timer = $DownTimer
@onready var auto_windup_timer = $AutoWindupTimer
@onready var auto_shoot_timer = $AutoShootTimer
@onready var fan_wait_timer = $FanWaitTimer
@onready var fan_shoot_timer = $FanShootTimer
enum State {IDLE, DOWN, FIRE, AUTO, FAN}
var current_state = State.IDLE

# DASH
var last_movement_time = 0
var last_movement_direction
var dash_move_tap_window = .1
var is_dash_move_done = false
var is_dash_shoot_done = false
var dash_prepared_time = 0
var dash_preparation_window = .1

# FAN
var fan_shots_fired = 0


func _ready():
	down_timer.timeout.connect(_on_down_timer_timeout)
	auto_windup_timer.timeout.connect(_on_auto_windup_timer_timeout)
	auto_shoot_timer.timeout.connect(_on_auto_shoot_timer_timeout)
	fan_wait_timer.timeout.connect(_on_fan_wait_timer_timeout)
	fan_shoot_timer.timeout.connect(_on_fan_shoot_timer_timeout)


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
	if current_state == State.IDLE:
		if is_dash_move_done:
			dash()
		else:
			dash_prepared_time = Time.get_unix_time_from_system()
			is_dash_shoot_done = true
		
		shoot_ray(30)
		
		auto_windup_timer.start()
		
		current_state = State.FIRE
		
		fan_wait_timer.start()
	elif current_state == State.FAN:
		shoot_ray(30)
		fan_shoot_timer.start()
		
		fan_shots_fired += 1
		if fan_shots_fired == 3:
			current_state = State.DOWN
			down_timer.start()


func shoot_ray(damage_amount: int, small_ray = false):
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
			collider.receive_damage(damage_amount)
	
	var shot_trail = trail_scene.instantiate()
	shot_trail.scale.z = raycast.position.distance_to(raycast.get_collision_point()) / 100
	if small_ray:
		shot_trail.scale.x = 0.3
		shot_trail.scale.y = 0.3
	shot_trail.position = global_position
	shot_trail.rotation = camera.global_rotation
	get_parent().get_parent().add_child(shot_trail)
	
	raycast.queue_free()


func fire_released():
	auto_windup_timer.stop()
	auto_shoot_timer.stop()
	
	if current_state == State.AUTO:
		current_state = State.DOWN
		down_timer.start()


func alt_fire_pressed():
	pass


func alt_fire_released():
	pass


func _on_down_timer_timeout():
	current_state = State.IDLE


func _on_auto_windup_timer_timeout():
	current_state = State.AUTO
	auto_shoot_timer.start()


func _on_auto_shoot_timer_timeout():
	shoot_ray(10, true)


func _on_fan_wait_timer_timeout():
	current_state = State.FAN
	fan_shoot_timer.start()
	fan_shots_fired = 0


func _on_fan_shoot_timer_timeout():
	current_state = State.DOWN
	down_timer.start()
