extends Node3D


# GENERAL
@export var camera: Camera3D
@export var trail_scene: PackedScene
@export var ricochet_scene: PackedScene
@export var grenade_scene: PackedScene
@export var chain_pull_scene: PackedScene
@export var pierce_scene: PackedScene
@onready var down_timer = $DownTimer
@onready var alt_down_timer = $AltDownTimer
@onready var auto_windup_timer = $AutoWindupTimer
@onready var auto_shoot_timer = $AutoShootTimer
@onready var fire_shoot_timer = $FireShootTimer
@onready var fire_wait_timer = $FireWaitTimer
@onready var fan_shoot_timer = $FanShootTimer
@onready var shotgun_shoot_timer = $ShotgunShootTimer
@onready var alt_fire_wait_timer = $AltFireWaitTimer
@onready var alt_fire_shoot_timer = $AltFireShootTimer
@onready var charge_drain_timer = $ChargeDrainTimer
enum State {IDLE, DOWN, FIRE, AUTO, FAN, ALT_FIRE, ALT_FIRE_SHOOT, CHARGING_PIERCE}
enum ShotType {BASE, FAN, AUTO, RICOCHET, SHOTGUN, SHOTGUN_SHELL, BLAST, CHAIN_PULL}
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

# GRENADE
var grenade_launch_speed = 20

# PIERCING
var piercing_charge_start_time = 0
var piercing_max_charge_time = 3

# CHARGE
var current_charge = 0
var charge_max = 7
signal charge_changed(new_charge)
var is_charge_draining = false


func _ready():
	down_timer.timeout.connect(_on_down_timer_timeout)
	alt_down_timer.timeout.connect(_on_alt_down_timer_timeout)
	auto_windup_timer.timeout.connect(_on_auto_windup_timer_timeout)
	auto_shoot_timer.timeout.connect(_on_auto_shoot_timer_timeout)
	fan_shoot_timer.timeout.connect(_on_fan_shoot_timer_timeout)
	fire_shoot_timer.timeout.connect(_on_fire_shoot_timer_timeout)
	fire_wait_timer.timeout.connect(_on_fire_wait_timer_timeout)
	shotgun_shoot_timer.timeout.connect(_on_shotgun_shoot_timer_timeout)
	alt_fire_wait_timer.timeout.connect(_on_alt_fire_wait_timer_timeout)
	alt_fire_shoot_timer.timeout.connect(_on_alt_fire_shoot_timer_timeout)
	charge_drain_timer.timeout.connect(_on_charge_drain_timer_timeout)
	
	ChargeMoveQueue.charge_gained.connect(_on_charge_move_queue_charge_gained)


func _process(delta):
	process_dash()
	
	if is_charge_draining:
		change_charge(clampf(current_charge - delta / 3, 0, charge_max))


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
		shoot_ray(30, ShotType.FAN)
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
	elif current_state == State.ALT_FIRE:
		current_state = State.CHARGING_PIERCE
		piercing_charge_start_time = Time.get_unix_time_from_system()
		
		alt_fire_wait_timer.stop()
	elif current_state == State.ALT_FIRE_SHOOT:
		shoot_ray(0, ShotType.CHAIN_PULL)
		
		current_state = State.DOWN
		alt_down_timer.start()
		alt_fire_shoot_timer.stop()


func fire_released():
	auto_windup_timer.stop()
	auto_shoot_timer.stop()
	
	if current_state == State.AUTO:
		current_state = State.DOWN
		down_timer.start()
	elif current_state == State.CHARGING_PIERCE:
		var current_time = Time.get_unix_time_from_system()
		var pierce_power = clampf((current_time - piercing_charge_start_time) / piercing_max_charge_time, 0, 1)
		shoot_pierce(pierce_power)
		
		current_state = State.DOWN
		alt_down_timer.start()


func alt_fire_pressed():
	if current_state == State.IDLE:
		var grenade = grenade_scene.instantiate()
		grenade.position = global_position
		grenade.velocity = -camera.global_basis.z * grenade_launch_speed
		get_parent().get_parent().get_parent().add_child(grenade)
		
		current_state = State.ALT_FIRE
		alt_fire_wait_timer.start()
	elif current_state == State.FIRE:
		shotgun_shots_fired += 1
		shoot_ray(10, ShotType.SHOTGUN)
		fire_shoot_timer.stop()
		shotgun_shoot_timer.start()
		
		if shotgun_shots_fired == 2:
			shotgun_shots_fired = 0
			shotgun_shoot_timer.stop()
			
			current_state = State.DOWN
			down_timer.start()
	elif current_state == State.ALT_FIRE_SHOOT:
		shoot_ray(0, ShotType.BLAST)
		
		current_state = State.DOWN
		alt_down_timer.start()
		alt_fire_shoot_timer.stop()


func alt_fire_released():
	pass


func shoot_ray(damage_amount: int, shot_type = ShotType.BASE, is_shotgun_shell = false):
	var raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	if is_shotgun_shell || shot_type == ShotType.SHOTGUN:
		var shotgun_shell_deviation = .1
		raycast.rotation.x += randf_range(-shotgun_shell_deviation, shotgun_shell_deviation)
		raycast.rotation.y += randf_range(-shotgun_shell_deviation, shotgun_shell_deviation)
	elif shot_type == ShotType.AUTO:
		var auto_deviation = .02
		raycast.rotation.x += randf_range(-auto_deviation, auto_deviation)
		raycast.rotation.y += randf_range(-auto_deviation, auto_deviation)
	raycast.set_collision_mask_value(1, true)
	raycast.set_collision_mask_value(2, true)
	get_parent().get_parent().get_parent().add_child(raycast)
	
	raycast.force_raycast_update()
	if shot_type != ShotType.BLAST && shot_type != ShotType.CHAIN_PULL:
		var collider = raycast.get_collider()
		if collider:
			if collider.is_in_group("enemy"):
				collider.receive_damage(damage_amount)
				
				if shot_type == ShotType.FAN:
					ChargeMoveQueue.move_performed(MoveType.FAN)
				elif shot_type == ShotType.AUTO:
					ChargeMoveQueue.move_performed(MoveType.AUTO)
				elif shot_type == ShotType.RICOCHET:
					ChargeMoveQueue.move_performed(MoveType.RICOCHET)
				elif shot_type == ShotType.SHOTGUN or shot_type == ShotType.SHOTGUN_SHELL:
					ChargeMoveQueue.move_performed(MoveType.SHOTGUN)
	
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
	
	if shot_type == ShotType.SHOTGUN:
		for i in range(15):
			shoot_ray(10, ShotType.SHOTGUN_SHELL, true)
	
	if shot_type == ShotType.BLAST:
		var grenade = grenade_scene.instantiate()
		grenade.position = raycast.get_collision_point()
		grenade.move_type = MoveType.BLAST
		get_parent().get_parent().get_parent().add_child(grenade)
		grenade.explode()
	
	if shot_type == ShotType.CHAIN_PULL:
		var chain_pull = chain_pull_scene.instantiate()
		chain_pull.position = raycast.get_collision_point()
		get_parent().get_parent().get_parent().add_child(chain_pull)
	
	raycast.queue_free()


func shoot_pierce(pierce_power):
	var pierce = pierce_scene.instantiate()
	pierce.position = global_position
	pierce.rotation = camera.global_rotation
	pierce.scale.x = pierce_power
	pierce.scale.y = pierce_power
	pierce.power = pierce_power
	get_parent().get_parent().get_parent().add_child(pierce)


func _on_down_timer_timeout():
	current_state = State.IDLE


func _on_alt_down_timer_timeout():
	current_state = State.IDLE


func _on_auto_windup_timer_timeout():
	current_state = State.AUTO
	fire_wait_timer.stop()
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


func _on_alt_fire_wait_timer_timeout():
	current_state = State.ALT_FIRE_SHOOT
	alt_fire_shoot_timer.start()


func _on_alt_fire_shoot_timer_timeout():
	current_state = State.DOWN
	down_timer.start()


func _on_charge_move_queue_charge_gained(charge_amount):
	var new_charge = clampf(current_charge + charge_amount, 0, charge_max)
	change_charge(new_charge)
	is_charge_draining = false
	charge_drain_timer.start()


func change_charge(new_charge):
	current_charge = new_charge
	charge_changed.emit(current_charge)
	if current_charge == 0:
		ChargeMoveQueue.clear_queue()


func _on_charge_drain_timer_timeout():
	is_charge_draining = true
