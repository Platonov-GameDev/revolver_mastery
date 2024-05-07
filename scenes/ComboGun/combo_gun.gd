extends Node3D


@onready var down_timer = $DownTimer
var last_movement_time = 0
var last_movement_direction
var dash_move_tap_window = .1
var is_dash_move_done = false
var is_dash_shoot_done = false
var dash_prepared_time = 0
var dash_preparation_window = .1
enum State {IDLE, DASHING}
var current_state = State.IDLE


func _ready():
	down_timer.timeout.connect(_on_down_timer_timeout)


func _process(_delta):
	process_dash()


func movement_pressed(direction):
	last_movement_direction = direction
	last_movement_time = Time.get_unix_time_from_system()


func movement_released(direction):
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
	if current_state != State.IDLE: return
	is_dash_move_done = false
	is_dash_shoot_done = false
	get_parent().dash(last_movement_direction)
	current_state = State.DASHING
	down_timer.start()


func fire_pressed():
	if is_dash_move_done:
		dash()
	else:
		dash_prepared_time = Time.get_unix_time_from_system()
		is_dash_shoot_done = true


func fire_released():
	pass


func alt_fire_pressed():
	pass


func alt_fire_released():
	pass


func _on_down_timer_timeout():
	current_state = State.IDLE
