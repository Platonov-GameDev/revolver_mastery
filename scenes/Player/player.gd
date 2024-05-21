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
@onready var combo_gun = $Camera3D/ComboGun
@onready var charge_bar_1 = $ChargeBars/ChargeBar1
@onready var charge_bar_2 = $ChargeBars/ChargeBar2
@onready var charge_bar_3 = $ChargeBars/ChargeBar3
@onready var charge_bar_4 = $ChargeBars/ChargeBar4
@onready var downtime_indicator = $DowntimeIndicator
@onready var indicator_1 = $ChargeIndicators/Indicator1
@onready var indicator_2 = $ChargeIndicators/Indicator2
@onready var indicator_3 = $ChargeIndicators/Indicator3
@onready var indicator_4 = $ChargeIndicators/Indicator4
@onready var health_bar = $HealthBar
@onready var health_component = $HealthComponent
@onready var damage_overlay_timer = $DamageOverlayTimer
@onready var damage_overlay = $DamageOverlay
@onready var kpm_label = $KPMLabel
@onready var new_record_label = $DeathScreen/Control/NewRecordLabel
@onready var highest_kpm_label = $HighestKPMLabel
@onready var all_time_highest_kpm_label = $AllTimeHighestKPMLabel
@onready var fps_label = $FPSLabel
var jump_speed = 10
var camera_sensitivity = 0.1
var xp = 0
var start_time = Time.get_unix_time_from_system()
var is_dead = false
var current_movement_state = PlayerMovementState.DEFAULT

var default_move_speed = 200
var slide_move_speed = 1
var player_move_speed = default_move_speed

var player_airborne_delta_speed = 30
var player_hover_delta_speed = 10
var movement_input_vector = Vector2.ZERO

var default_ground_deceleration = 90
var slide_ground_deceleration = 10
var ground_deceleration = default_ground_deceleration
var slide_impulse = 30
var slide_floor_acceleration = 0.05

var max_ground_speed = 10

var initial_airborne_horizontal_velocity_magnitude = 0
var is_hovering = false

var fps_counter_frames := 0
var fps_counter_timer := 0.


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
	input_handler.restart_pressed.connect(_on_input_handler_restart_pressed)
	
	input_handler.slide_pressed.connect(_on_input_handler_slide_pressed)
	input_handler.slide_released.connect(_on_input_handler_slide_released)
	
	gun.activation_changed.connect(_on_gun_activation_changed)
	gun.ammo_changed.connect(_on_gun_ammo_changed)
	gun.reload_state_changed.connect(_on_gun_reload_state_changed)
	
	combo_gun.charge_changed.connect(_on_combo_gun_charge_changed)
	combo_gun.state_changed.connect(_on_combo_gun_state_changed)
	
	health_component.died.connect(die)
	health_component.damage_received.connect(_on_health_component_damage_received)
	health_component.health_changed.connect(_on_health_component_health_changed)
	
	GameManager.kpm_changed.connect(_on_game_manager_kpm_changed)
	GameManager.got_new_record.connect(_on_game_manager_got_new_record)
	GameManager.highest_kpm_changed.connect(_on_game_manager_highest_kpm_changed)
	
	all_time_highest_kpm_label.text = "All-Time Highest KPM: " + str(GameManager.all_time_highest_kpm)


func _process(delta):
	fps_counter_timer += delta
	fps_counter_frames += 1
	if fps_counter_timer >= .05:
		fps_label.text = str(snapped(fps_counter_frames / fps_counter_timer, 1))
		fps_counter_timer = 0.
		fps_counter_frames = 0
	
	if is_dead: return
	
	if !combo_gun.is_charging_piercing:
		velocity.y -= Global.gravity_acceleration * delta
	elif combo_gun.is_charging_piercing:
		velocity.y -= Global.gravity_acceleration * delta * 0.1
	
	var movement_vector = movement_input_vector.rotated(get_rotation().y)
	movement_vector.y *= -1
	
	var current_horizontal_velocity = Vector2(velocity.x, velocity.z)
	
	if is_on_floor():
		initial_airborne_horizontal_velocity_magnitude = Vector2(velocity.x, velocity.z).length()
		if velocity.y < 0:
			velocity.y = 0
		
		if current_movement_state == PlayerMovementState.DEFAULT:
			if movement_vector.length() == 0:
				var deceleration_velocity = (current_horizontal_velocity.normalized()
					* ground_deceleration * delta)
				var velocity_after_deceleration = current_horizontal_velocity - deceleration_velocity
				if velocity_after_deceleration.angle_to(current_horizontal_velocity) >= 0.01:
					velocity_after_deceleration = Vector2.ZERO
				
				velocity_after_deceleration = velocity_after_deceleration.limit_length(max_ground_speed)
				
				velocity.x = velocity_after_deceleration.x
				velocity.z = velocity_after_deceleration.y
			else:
				var new_horizontal_velocity = (current_horizontal_velocity
					+ movement_vector * player_move_speed * delta)
				new_horizontal_velocity = new_horizontal_velocity.limit_length(max_ground_speed)
				
				velocity.x = new_horizontal_velocity.x
				velocity.z = new_horizontal_velocity.y
		elif current_movement_state == PlayerMovementState.SLIDING:
			if current_horizontal_velocity != Vector2.ZERO:
				var deceleration_velocity = (current_horizontal_velocity.normalized()
					* ground_deceleration * delta)
				
				var floor_normal = get_floor_normal()
				
				var floor_velocity = (floor_normal.dot(velocity) / velocity.length()
					* velocity.normalized() * slide_floor_acceleration)
				
				var final_velocity = current_horizontal_velocity
				final_velocity -= deceleration_velocity
				final_velocity += Vector2(floor_velocity.x, floor_velocity.z)
				
				velocity.x = final_velocity.x
				velocity.z = final_velocity.y
	elif !is_on_floor():
		var new_horizontal_velocity = current_horizontal_velocity
		if !is_hovering:
			new_horizontal_velocity += movement_vector * player_airborne_delta_speed * delta
		elif is_hovering:
			new_horizontal_velocity += movement_vector * player_hover_delta_speed * delta
		new_horizontal_velocity = new_horizontal_velocity.limit_length(
			initial_airborne_horizontal_velocity_magnitude)
		
		if new_horizontal_velocity.length() <= max_ground_speed:
			initial_airborne_horizontal_velocity_magnitude = max_ground_speed
		
		velocity.x = new_horizontal_velocity.x
		velocity.z = new_horizontal_velocity.y
	
	move_and_slide()
	
	var elapsed_time = Time.get_unix_time_from_system() - start_time
	timer_label.text = str(snapped(elapsed_time, 0.01))
	
	damage_overlay.modulate.a = damage_overlay_timer.time_left / damage_overlay_timer.wait_time
	
	health_component.regen_health(delta)


func _on_input_handler_movement_inputted(input_vector: Vector2):
	if is_dead: return
	
	movement_input_vector = input_vector


func _on_input_handler_movement_pressed(direction):
	combo_gun.movement_pressed(direction)


func _on_input_handler_movement_released(direction):
	combo_gun.movement_released(direction)


func _on_input_handler_jump_pressed():
	if is_dead: return
	if is_on_floor():
		velocity.y = jump_speed
		
		var horizontal_velocity = Vector2(velocity.x, velocity.z)


func _on_input_handler_escape_pressed():
	get_tree().quit()


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


func _on_input_handler_restart_pressed():
	GameManager.reset()
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


func _on_combo_gun_charge_changed(new_charge):
	var charged_color = Color("#ff2a00")
	var charging_color = Color("#ff9500")
	var uncharged_color = Color("#ffffff")
	
	charge_bar_1.value = new_charge * 100
	charge_bar_2.value = (new_charge - 1) * 100
	charge_bar_3.value = (new_charge - 2) * 100
	charge_bar_4.value = (new_charge - 3) * 100
	
	if new_charge >= 1:
		indicator_1.modulate = charged_color
		charge_bar_1.tint_progress = charged_color
	else:
		indicator_1.modulate = uncharged_color
		charge_bar_1.tint_progress = charging_color
	if new_charge >= 2:
		indicator_2.modulate = charged_color
		charge_bar_2.tint_progress = charged_color
	else:
		indicator_2.modulate = uncharged_color
		charge_bar_2.tint_progress = charging_color
	if new_charge >= 3:
		indicator_3.modulate = charged_color
		charge_bar_3.tint_progress = charged_color
	else:
		indicator_3.modulate = uncharged_color
		charge_bar_3.tint_progress = charging_color
	if new_charge >= 4:
		indicator_4.modulate = charged_color
		charge_bar_4.tint_progress = charged_color
	else:
		indicator_4.modulate = uncharged_color
		charge_bar_4.tint_progress = charging_color


func _on_combo_gun_state_changed(new_state):
	if new_state == ComboGunState.DOWN:
		downtime_indicator.hide()
	else:
		downtime_indicator.show()


func _on_health_component_damage_received():
	damage_overlay_timer.start()


func _on_health_component_health_changed(new_health):
	health_bar.value = new_health


func toss(toss_velocity: Vector3, resets_velocity = false):
	if resets_velocity:
		velocity = toss_velocity
	elif !resets_velocity:
		velocity += toss_velocity
	var horizontal_velocity = Vector2(velocity.x, velocity.z)


func hover():
	velocity.y = clampf(velocity.y, 0, 9999)


func knockup():
	if !is_on_floor():
		velocity.y = clampf(velocity.y, 3, 9999)


func _on_game_manager_kpm_changed(new_kpm):
	kpm_label.text = "KPM: " + str(new_kpm)


func _on_game_manager_got_new_record():
	new_record_label.show()


func _on_game_manager_highest_kpm_changed(new_highest_kpm):
	highest_kpm_label.text = "Highest KPM: " + str(new_highest_kpm)


func _on_input_handler_slide_pressed():
	current_movement_state = PlayerMovementState.SLIDING
	ground_deceleration = slide_ground_deceleration
	player_move_speed = slide_move_speed
	camera.position.y -= 1
	camera.rotation.z += .1
	combo_gun.rotation.z += 1
	combo_gun.position.y -= .5
	
	if is_on_floor():
		var new_horizontal_velocity = Vector2(velocity.x, velocity.z).normalized() * slide_impulse
		velocity.x = new_horizontal_velocity.x
		velocity.z = new_horizontal_velocity.y


func _on_input_handler_slide_released():
	if current_movement_state == PlayerMovementState.SLIDING:
		current_movement_state = PlayerMovementState.DEFAULT
		ground_deceleration = default_ground_deceleration
		player_move_speed = default_move_speed
		camera.position.y += 1
		camera.rotation.z -= .1
		combo_gun.rotation.z -= 1
		combo_gun.position.y += .5
