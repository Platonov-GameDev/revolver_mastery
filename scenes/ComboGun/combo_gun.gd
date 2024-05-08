extends Node3D


# GENERAL
@export var camera: Camera3D
@export var trail_scene: PackedScene
@export var ricochet_scene: PackedScene
@onready var down_timer = $DownTimer
@onready var auto_windup_timer = $AutoWindupTimer
@onready var auto_shoot_timer = $AutoShootTimer
@onready var fire_shoot_timer = $FireShootTimer
@onready var fire_wait_timer = $FireWaitTimer
@onready var fan_shoot_timer = $FanShootTimer
@onready var shotgun_shoot_timer = $ShotgunShootTimer
enum State {IDLE, DOWN, FIRE, AUTO, FAN}
enum ShotType {BASE, AUTO, RICOCHET, SHOTGUN}
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

# SHOTGUN
var shotgun_shots_fired = 0


func _ready():
	down_timer.timeout.connect(_on_down_timer_timeout)
	auto_windup_timer.timeout.connect(_on_auto_windup_timer_timeout)
	auto_shoot_timer.timeout.connect(_on_auto_shoot_timer_timeout)
	fan_shoot_timer.timeout.connect(_on_fan_shoot_timer_timeout)
	fire_shoot_timer.timeout.connect(_on_fire_shoot_timer_timeout)
	fire_wait_timer.timeout.connect(_on_fire_wait_timer_timeout)
	shotgun_shoot_timer.timeout.connect(_on_shotgun_shoot_timer_timeout)


func _process(_delta):
	process_dash()


func movement_pressed(direction):
	if get_parent().get_parent().current_movement_state == PlayerMovementState.DASHING: return
	last_movement_direction = direction
	last_movement_time = Time.get_unix_time_from_system()


func movement_released(direction):
	if get_parent().get_parent().current_movement_state == PlayerMovementState.DASHING: return
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
	get_parent().get_parent().dash(last_movement_direction)


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
		
		fire_shoot_timer.start()
	elif current_state == State.FAN:
		shoot_ray(30)
		fan_shoot_timer.start()
		
		fan_shots_fired += 1
		if fan_shots_fired == 5:
			current_state = State.DOWN
			down_timer.start()
	elif current_state == State.FIRE:
		shoot_ray(30, ShotType.RICOCHET)
		
		current_state = State.DOWN
		down_timer.start()
		
		fire_shoot_timer.stop()


func shoot_ray(damage_amount: int, shot_type = ShotType.BASE, is_shotgun_shell = false):
	var raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	if is_shotgun_shell || shot_type == ShotType.SHOTGUN:
		var shotgun_shell_deviation = .1
		raycast.rotation.x += randf_range(-shotgun_shell_deviation, shotgun_shell_deviation)
		raycast.rotation.y += randf_range(-shotgun_shell_deviation, shotgun_shell_deviation)
	raycast.set_collision_mask_value(1, true)
	raycast.set_collision_mask_value(2, true)
	get_parent().get_parent().get_parent().add_child(raycast)
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	if collider:
		if collider.is_in_group("enemy"):
			collider.receive_damage(damage_amount)
	
	var shot_trail = trail_scene.instantiate()
	shot_trail.scale.z = raycast.position.distance_to(raycast.get_collision_point()) / 100
	if shot_type == ShotType.AUTO || shot_type == ShotType.SHOTGUN || is_shotgun_shell:
		shot_trail.scale.x = 0.3
		shot_trail.scale.y = 0.3
	shot_trail.position = global_position
	shot_trail.rotation = raycast.rotation
	get_parent().get_parent().get_parent().add_child(shot_trail)
	
	if shot_type == ShotType.RICOCHET:
		var ricochet = ricochet_scene.instantiate()
		ricochet.position = raycast.get_collision_point()
		ricochet.bounces_remaining = 4
		get_parent().get_parent().get_parent().add_child(ricochet)
	
	raycast.queue_free()
	
	if shot_type == ShotType.SHOTGUN:
		for i in range(7):
			shoot_ray(10, ShotType.BASE, true)


func fire_released():
	auto_windup_timer.stop()
	auto_shoot_timer.stop()
	
	if current_state == State.AUTO:
		current_state = State.DOWN
		down_timer.start()


func alt_fire_pressed():
	if current_state == State.FIRE:
		shotgun_shots_fired += 1
		shoot_ray(10, ShotType.SHOTGUN)
		fire_shoot_timer.stop()
		shotgun_shoot_timer.start()
		
		if shotgun_shots_fired == 2:
			shotgun_shots_fired = 0
			shotgun_shoot_timer.stop()
			
			current_state = State.DOWN
			down_timer.start()


func alt_fire_released():
	pass


func _on_down_timer_timeout():
	current_state = State.IDLE


func _on_auto_windup_timer_timeout():
	current_state = State.AUTO
	auto_shoot_timer.start()


func _on_auto_shoot_timer_timeout():
	shoot_ray(10, ShotType.AUTO)


func _on_fire_shoot_timer_timeout():
	fire_wait_timer.start()
	current_state = State.DOWN


func _on_fire_wait_timer_timeout():
	current_state = State.FAN
	fan_shoot_timer.start()
	fan_shots_fired = 0


func _on_fan_shoot_timer_timeout():
	current_state = State.DOWN
	down_timer.start()


func _on_shotgun_shoot_timer_timeout():
	current_state = State.DOWN
	down_timer.start()
