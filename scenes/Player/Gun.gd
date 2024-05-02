extends Node3D


@export var camera: Camera3D
@onready var ray_cast_timer = $RayCastTimer
@onready var pre_fire_timer = $PreFireTimer
@onready var fire_timer = $FireTimer
@onready var recharge_timer = $RechargeTimer
@onready var reload_timer = $ReloadTimer
var raycast: RayCast3D
var current_ammo = 6
var max_ammo = 6
var is_active = true
var is_reloading = false
signal ammo_changed(new_ammo)
signal activation_changed(new_is_active)
signal reload_state_changed(new_is_reloading)


func _ready():
	ray_cast_timer.timeout.connect(_on_ray_cast_timer_timeout)
	pre_fire_timer.timeout.connect(_on_pre_fire_timer_timeout)
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	recharge_timer.timeout.connect(_on_recharge_timer_timeout)
	reload_timer.timeout.connect(_on_reload_timer_timeout)


func press():
	if !is_active: reset()
	if is_reloading: return
	
	change_activation(false)
	pre_fire_timer.start()


func release():
	if !is_active: reset()
	if is_reloading: return
	
	if fire_timer.time_left == 0: return
	
	shoot()


func reset():
	pre_fire_timer.stop()
	fire_timer.stop()
	recharge_timer.start()
	change_activation(false)


func shoot():
	if current_ammo == 0: return
	
	raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	get_parent().get_parent().add_child(raycast)
	
	ray_cast_timer.start()
	
	change_ammo(current_ammo - 1)
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	if collider:
		if collider.is_in_group("enemy"):
			collider.queue_free()
	
	fire_timer.stop()
	change_activation(false)
	
	if current_ammo != 0:
		recharge_timer.start()


func _on_ray_cast_timer_timeout():
	raycast.queue_free()


func change_ammo(new_ammo):
	current_ammo = new_ammo
	ammo_changed.emit(new_ammo)


func change_activation(new_is_active):
	is_active = new_is_active
	activation_changed.emit(new_is_active)


func change_reload_state(new_is_reloading):
	is_reloading = new_is_reloading
	reload_state_changed.emit(new_is_reloading)


func _on_pre_fire_timer_timeout():
	change_activation(true)
	fire_timer.start()


func _on_fire_timer_timeout():
	print("fire_timer_timeout")
	change_activation(false)
	recharge_timer.start()


func _on_recharge_timer_timeout():
	change_activation(true)


func reload():
	change_reload_state(true)
	reload_timer.start()


func _on_reload_timer_timeout():
	change_reload_state(false)
	change_ammo(max_ammo)
	change_activation(true)
