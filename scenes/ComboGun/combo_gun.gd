extends Node3D


# GENERAL
@export var player: CharacterBody3D
@export var camera: Camera3D
@export var trail_scene: PackedScene
@export var ricochet_scene: PackedScene
@export var grenade_scene: PackedScene
@export var chain_pull_scene: PackedScene
@export var pierce_scene: PackedScene
@export var auto_slow_aura_scene: PackedScene
@export var shotgun_stun_aura_scene: PackedScene
@export var fan_wallbang_decal_scene: PackedScene
@export var ricochet_wave_scene: PackedScene
@export var auto_ricochet_detector_scene: PackedScene
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
@onready var level = player.get_parent().get_parent()
@onready var muzzle = $Position/Animation/Muzzle
@onready var animation_player = $AnimationPlayer
enum ShotType {BASE, FAN, AUTO, RICOCHET, SHOTGUN, SHOTGUN_SHELL, BLAST, CHAIN_PULL}
var current_state = ComboGunState.IDLE
signal state_changed(new_state)
var DOWN_TIMER_TIME = 0.5
var ALT_DOWN_TIMER_TIME = 1
var AUTO_WINDUP_TIMER_TIME = 0.3
var AUTO_SHOOT_TIMER_TIME = 0.1
var FIRE_SHOOT_TIMER_TIME = 0.4
var FIRE_WAIT_TIMER_TIME = 0.1
var FAN_SHOOT_TIMER_TIME = 0.3
var SHOTGUN_SHOOT_TIMER_TIME = 0.4
var ALT_FIRE_WAIT_TIMER_TIME = 0.3
var ALT_FIRE_SHOOT_TIMER_TIME = 0.3
var CHARGE_DRAIN_TIMER_TIME = 3

# DASH
var last_movement_time = 0
var last_movement_direction
var dash_move_tap_window = .1
var is_dash_move_done = false
var is_dash_shoot_done = false
var dash_prepared_time = 0
var dash_preparation_window = .2

# FAN
var fan_shots_fired = 0

# SHOTGUN
var shotgun_shots_fired = 0
var shotgun_toss_force = 15
var shotgun_spread_goodness = 0

# GRENADE
var grenade_launch_speed = 20

# PIERCING
var piercing_charge_start_time = 0
var piercing_max_charge_time = 3
var is_charging_piercing = false

# CHARGE
var current_charge = 0
var charge_max = 4
signal charge_changed(new_charge)
var is_charge_draining = false
var grenade_charge_cost = 1
var blast_charge_cost = 1
var chain_pull_charge_cost = 3
var pierce_charge_cost = 6


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
	
	change_charge(0)


func _process(delta):
	process_dash()
	
	if is_charge_draining:
		change_charge(clampf(current_charge - delta / 2, 0, charge_max))


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
	#is_dash_move_done = false
	#is_dash_shoot_done = false
	#get_parent().get_parent().dash(last_movement_direction)
	pass


func fire_pressed():
	if current_state == ComboGunState.IDLE:
		if is_dash_move_done:
			dash()
		else:
			dash_prepared_time = Time.get_unix_time_from_system()
			is_dash_shoot_done = true
		
		shoot_ray(30)
		
		auto_windup_timer.start()
		
		change_state(ComboGunState.FIRE)
		
		fire_shoot_timer.start()
		
		player.knockup()
		
		animation_player.play("fire")
	elif current_state == ComboGunState.FAN:
		shoot_ray(30, ShotType.FAN)
		fan_shoot_timer.start()
		
		animation_player.play("RESET")
		animation_player.play("fan")
		
		fan_shots_fired += 1
		if fan_shots_fired == 5:
			change_state(ComboGunState.DOWN)
			down_timer.start()
			animation_player.play("RESET")
			animation_player.play("fan")
			
		player.knockup()
	elif current_state == ComboGunState.ALT_FIRE:
		change_state(ComboGunState.CHARGING_PIERCE)
		piercing_charge_start_time = Time.get_unix_time_from_system()
		
		alt_fire_wait_timer.stop()
		
		is_charging_piercing = true
		
		animation_player.play("RESET")
		animation_player.play("pierce_charge")
	elif current_state == ComboGunState.ALT_FIRE_SHOOT:
		shoot_ray(0, ShotType.CHAIN_PULL)
		
		change_state(ComboGunState.DOWN)
		alt_down_timer.start()
		alt_fire_shoot_timer.stop()
		
		player.knockup()
		animation_player.play("RESET")
		animation_player.play("grenade")


func fire_released():
	auto_windup_timer.stop()
	auto_shoot_timer.stop()
	
	if current_state == ComboGunState.AUTO:
		change_state(ComboGunState.DOWN)
		down_timer.start()
		player.is_hovering = false
		animation_player.play("down")
	elif current_state == ComboGunState.CHARGING_PIERCE:
		var current_time = Time.get_unix_time_from_system()
		var pierce_power = clampf((current_time - piercing_charge_start_time) / piercing_max_charge_time, 0, 1)
		shoot_pierce(pierce_power)
		
		change_state(ComboGunState.DOWN)
		alt_down_timer.start()
		
		is_charging_piercing = false
		player.knockup()
		
		animation_player.play("RESET")
		animation_player.play("pierce_shot")


func alt_fire_pressed():
	auto_windup_timer.stop()
	
	if current_state == ComboGunState.IDLE:
		var grenade = grenade_scene.instantiate()
		grenade.position = global_position
		grenade.velocity = -camera.global_basis.z * grenade_launch_speed
		level.add_child(grenade)
		
		change_state(ComboGunState.ALT_FIRE)
		alt_fire_wait_timer.start()
		animation_player.play("grenade")
	elif current_state == ComboGunState.FIRE:
		if fire_shoot_timer.time_left != 0:
			shotgun_spread_goodness = 1 - fire_shoot_timer.time_left / fire_shoot_timer.wait_time
		elif shotgun_shoot_timer.time_left != 0:
			shotgun_spread_goodness = 1 - shotgun_shoot_timer.time_left / shotgun_shoot_timer.wait_time
		
		shotgun_shots_fired += 1
		shoot_ray(10, ShotType.SHOTGUN)
		fire_shoot_timer.stop()
		shotgun_shoot_timer.start()
		animation_player.play("shotgun")
		
		if !player.is_on_floor():
			var toss_direction = camera.global_basis.z
			var toss_velocity = toss_direction * shotgun_toss_force
			player.toss(toss_velocity, true)
		
		if shotgun_shots_fired == 2:
			shotgun_shots_fired = 0
			shotgun_shoot_timer.stop()
			
			change_state(ComboGunState.DOWN)
			down_timer.start()
			animation_player.play("RESET")
			animation_player.play("shotgun")
	elif current_state == ComboGunState.ALT_FIRE_SHOOT:
		shoot_ray(0, ShotType.BLAST)
		
		change_state(ComboGunState.DOWN)
		alt_down_timer.start()
		alt_fire_shoot_timer.stop()
		animation_player.play("RESET")
		animation_player.play("grenade")
	elif current_state == ComboGunState.AUTO:
		var raycast = RayCast3D.new()
		raycast.position = global_position
		raycast.rotation = camera.global_rotation
		raycast.target_position = Vector3(0, 0, -100)
		var auto_deviation = .02
		raycast.rotate_x(randf_range(-auto_deviation, auto_deviation))
		raycast.rotate_y(randf_range(-auto_deviation, auto_deviation))
		raycast.rotate_z(randf_range(-auto_deviation, auto_deviation))
		raycast.set_collision_mask_value(1, true)
		raycast.set_collision_mask_value(2, true)
		level.add_child(raycast)
		raycast.force_raycast_update()
		
		var collision_normal = raycast.get_collision_normal().normalized()
		var raycast_direction = -raycast.transform.basis.z
		var ricochet_direction = (
			raycast_direction - 2 * raycast_direction.dot(collision_normal) * collision_normal)
		
		var ricochet_raycast = RayCast3D.new()
		ricochet_raycast.look_at_from_position(Vector3.ZERO, ricochet_direction)
		ricochet_raycast.position = raycast.get_collision_point()
		ricochet_raycast.target_position = Vector3(0, 0, -100)
		ricochet_raycast.set_collision_mask_value(1, true)
		level.add_child(ricochet_raycast)
		ricochet_raycast.force_raycast_update()
		
		var ricochet_wave = ricochet_wave_scene.instantiate()
		var ricochet_scale = ricochet_raycast.position.distance_to(ricochet_raycast.get_collision_point())
		ricochet_wave.scale = Vector3(ricochet_scale, ricochet_scale, ricochet_scale)
		ricochet_wave.position = ricochet_raycast.position
		ricochet_wave.rotation = ricochet_raycast.rotation
		level.add_child(ricochet_wave)
		
		change_state(ComboGunState.DOWN)
		down_timer.start()
		player.is_hovering = false
		auto_shoot_timer.stop()
		
		player.knockup()
		animation_player.play("down")


func alt_fire_released():
	pass


func shoot_ray(damage_amount: int, shot_type = ShotType.BASE, is_shotgun_shell = false):
	var raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	if is_shotgun_shell || shot_type == ShotType.SHOTGUN:
		var shotgun_shell_deviation = .03 + (1 - shotgun_spread_goodness) * 0.25
		raycast.rotate_x(randf_range(-shotgun_shell_deviation, shotgun_shell_deviation))
		raycast.rotate_y(randf_range(-shotgun_shell_deviation, shotgun_shell_deviation))
		raycast.rotate_z(randf_range(-shotgun_shell_deviation, shotgun_shell_deviation))
	elif shot_type == ShotType.AUTO:
		var auto_deviation = .02
		raycast.rotate_x(randf_range(-auto_deviation, auto_deviation))
		raycast.rotate_y(randf_range(-auto_deviation, auto_deviation))
		raycast.rotate_z(randf_range(-auto_deviation, auto_deviation))
		
	raycast.set_collision_mask_value(1, true)
	raycast.set_collision_mask_value(2, true)
	level.add_child(raycast)
	
	raycast.force_raycast_update()
	if shot_type != ShotType.BLAST && shot_type != ShotType.CHAIN_PULL:
		var collider = raycast.get_collider()
		if collider:
			if collider.is_in_group("enemy"):
				collider.receive_damage(damage_amount)
				
				if shot_type == ShotType.FAN:
					var charge = ChargeMoveQueue.move_performed(MoveType.FAN)
					ChargeMoveQueue.spawn_charge_label(raycast.get_collision_point(), charge)
					collider.marked_component.activate()
				elif shot_type == ShotType.AUTO:
					var charge = ChargeMoveQueue.move_performed(MoveType.AUTO)
					ChargeMoveQueue.spawn_charge_label(raycast.get_collision_point(), charge)
				elif shot_type == ShotType.RICOCHET:
					var charge = ChargeMoveQueue.move_performed(MoveType.RICOCHET)
					ChargeMoveQueue.spawn_charge_label(raycast.get_collision_point(), charge)
				elif shot_type == ShotType.SHOTGUN or shot_type == ShotType.SHOTGUN_SHELL:
					var charge = ChargeMoveQueue.move_performed(MoveType.SHOTGUN)
					ChargeMoveQueue.spawn_charge_label(raycast.get_collision_point(), charge)
			elif !collider.is_in_group("enemy"):
				if shot_type == ShotType.FAN:
					var did_hit_wall = true
					while did_hit_wall:
						raycast.add_exception(collider)
						raycast.force_raycast_update()
						collider = raycast.get_collider()
						
						var fan_wallbang_decal = fan_wallbang_decal_scene.instantiate()
						fan_wallbang_decal.position = raycast.get_collision_point()
						level.add_child(fan_wallbang_decal)
						fan_wallbang_decal.look_at(-raycast.transform.basis.z)
						
						if !collider:
							did_hit_wall = false
						elif collider.is_in_group("enemy"):
							collider.receive_damage(damage_amount)
							
							var charge = ChargeMoveQueue.move_performed(MoveType.FAN)
							ChargeMoveQueue.spawn_charge_label(raycast.get_collision_point(), charge)
							collider.marked_component.activate()
							
							did_hit_wall = false
				elif shot_type == ShotType.AUTO:
					var collision_normal = raycast.get_collision_normal().normalized()
					var raycast_direction = -raycast.transform.basis.z
					var ricochet_direction = (
						raycast_direction - 2 * raycast_direction.dot(collision_normal) * collision_normal)
					
					var auto_ricochet_detector = auto_ricochet_detector_scene.instantiate()
					auto_ricochet_detector.look_at_from_position(Vector3.ZERO, ricochet_direction)
					auto_ricochet_detector.position = raycast.get_collision_point()
					auto_ricochet_detector.level = level
					level.add_child(auto_ricochet_detector)
	
	var shot_trail = trail_scene.instantiate()
	if raycast.get_collider():
		shot_trail.scale.z = muzzle.global_position.distance_to(raycast.get_collision_point()) / 100
	if shot_type == ShotType.AUTO || shot_type == ShotType.SHOTGUN || is_shotgun_shell:
		shot_trail.scale.x = 0.3
		shot_trail.scale.y = 0.3
	if raycast.get_collision_point():
		shot_trail.look_at_from_position(muzzle.global_position, raycast.get_collision_point())
	else:
		shot_trail.position = muzzle.global_position
		shot_trail.rotation = raycast.global_rotation
	level.add_child(shot_trail)
	
	if shot_type == ShotType.RICOCHET:
		var ricochet = ricochet_scene.instantiate()
		ricochet.position = raycast.get_collision_point()
		ricochet.bounces_remaining = 4
		level.add_child(ricochet)
	
	if shot_type == ShotType.SHOTGUN:
		for i in range(15):
			shoot_ray(10, ShotType.SHOTGUN_SHELL, true)
		
		var shotgun_stun_aura = shotgun_stun_aura_scene.instantiate()
		shotgun_stun_aura.position = global_position
		level.add_child(shotgun_stun_aura)
	
	if shot_type == ShotType.BLAST:
		var grenade = grenade_scene.instantiate()
		grenade.position = raycast.get_collision_point()
		grenade.move_type = MoveType.BLAST
		level.add_child(grenade)
		grenade.explode()
	
	if shot_type == ShotType.CHAIN_PULL:
		var chain_pull = chain_pull_scene.instantiate()
		chain_pull.position = raycast.get_collision_point()
		level.add_child(chain_pull)
	
	if shot_type == ShotType.AUTO:
		var auto_slow_aura = auto_slow_aura_scene.instantiate()
		auto_slow_aura.position = global_position
		level.add_child(auto_slow_aura)
	
	raycast.queue_free()


func shoot_pierce(pierce_power):
	var pierce = pierce_scene.instantiate()
	pierce.position = global_position
	pierce.rotation = camera.global_rotation
	pierce.scale.x = pierce_power
	pierce.scale.y = pierce_power
	pierce.power = pierce_power
	level.add_child(pierce)


func _on_down_timer_timeout():
	change_state(ComboGunState.IDLE)
	animation_player.play("idle")


func _on_alt_down_timer_timeout():
	change_state(ComboGunState.IDLE)
	animation_player.play("idle")


func _on_auto_windup_timer_timeout():
	change_state(ComboGunState.AUTO)
	fire_shoot_timer.stop()
	fire_wait_timer.stop()
	auto_shoot_timer.start()
	animation_player.play("RESET")
	animation_player.play("auto")


func _on_auto_shoot_timer_timeout():
	shoot_ray(10, ShotType.AUTO)
	
	player.hover()
	player.is_hovering = true
	
	animation_player.play("RESET")
	animation_player.play("auto")


func _on_fire_shoot_timer_timeout():
	fire_wait_timer.start()
	change_state(ComboGunState.DOWN)


func _on_fire_wait_timer_timeout():
	change_state(ComboGunState.FAN)
	fan_shoot_timer.start()
	fan_shots_fired = 0


func _on_fan_shoot_timer_timeout():
	change_state(ComboGunState.DOWN)
	down_timer.start()
	animation_player.play("down")
	animation_player.play("down")


func _on_shotgun_shoot_timer_timeout():
	change_state(ComboGunState.DOWN)
	down_timer.start()
	
	shotgun_shots_fired = 0
	animation_player.play("down")


func _on_alt_fire_wait_timer_timeout():
	change_state(ComboGunState.ALT_FIRE_SHOOT)
	alt_fire_shoot_timer.start()


func _on_alt_fire_shoot_timer_timeout():
	change_state(ComboGunState.DOWN)
	down_timer.start()
	animation_player.play("down")


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
	
	if 0 <= new_charge and new_charge < 1:
		update_timers(0)
	elif 1 <= new_charge and new_charge < 2:
		update_timers(1)
	elif 2 <= new_charge and new_charge < 3:
		update_timers(2)
	elif 3 <= new_charge and new_charge < 4:
		update_timers(3)
	elif 4 == new_charge:
		update_timers(4)


func update_timers(charge_stage: int):
	var stage_gain = 0.1
	var time_ratio = 1 - stage_gain * charge_stage
	
	animation_player.speed_scale = 1 + stage_gain * charge_stage
	
	down_timer.wait_time = DOWN_TIMER_TIME * time_ratio
	alt_down_timer.wait_time = ALT_DOWN_TIMER_TIME * time_ratio
	auto_windup_timer.wait_time = AUTO_WINDUP_TIMER_TIME * time_ratio
	auto_shoot_timer.wait_time = AUTO_SHOOT_TIMER_TIME * time_ratio
	fire_shoot_timer.wait_time = FIRE_SHOOT_TIMER_TIME * time_ratio
	fire_wait_timer.wait_time = FIRE_WAIT_TIMER_TIME * time_ratio
	fan_shoot_timer.wait_time = FAN_SHOOT_TIMER_TIME * time_ratio
	shotgun_shoot_timer.wait_time = SHOTGUN_SHOOT_TIMER_TIME * time_ratio
	alt_fire_wait_timer.wait_time = ALT_FIRE_WAIT_TIMER_TIME * time_ratio
	alt_fire_shoot_timer.wait_time = ALT_FIRE_SHOOT_TIMER_TIME * time_ratio
	charge_drain_timer.wait_time = CHARGE_DRAIN_TIMER_TIME * time_ratio


func _on_charge_drain_timer_timeout():
	is_charge_draining = true


func change_state(new_state):
	current_state = new_state
	state_changed.emit(new_state)
