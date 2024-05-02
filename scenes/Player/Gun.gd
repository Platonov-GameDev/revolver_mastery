extends Node3D


@export var camera: Camera3D
@onready var ray_cast_timer = $RayCastTimer
@onready var pre_fan_timer = $PreFanTimer
@onready var fan_timer = $FanTimer
@onready var recharge_timer = $RechargeTimer
@onready var reload_timer = $ReloadTimer
var raycast: RayCast3D
var is_active = true
var current_ammo = 6
var max_ammo = 6
signal activation_changed(new_is_active)
signal ammo_changed(new_ammo)
signal reload_state_changed(is_reloading)


func _ready():
	ray_cast_timer.timeout.connect(_on_ray_cast_timer_timeout)
	
	pre_fan_timer.timeout.connect(_on_pre_fan_timer_timeout)
	fan_timer.timeout.connect(_on_fan_timer_timeout)
	recharge_timer.timeout.connect(_on_recharge_timer_timeout)
	reload_timer.timeout.connect(_on_reload_timer_timeout)


func shoot():
	if current_ammo == 0:
		return
	
	if !is_active:
		pre_fan_timer.stop()
		recharge_timer.start()
		return
	
	raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	get_parent().get_parent().add_child(raycast)
	
	ray_cast_timer.start()
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	if collider: 
		if collider.is_in_group("enemy"):
			collider.queue_free()
	
	fan_timer.stop()
	change_ammo(current_ammo - 1)
	change_activation(false)
	if current_ammo != 0:
		pre_fan_timer.start()


func _on_ray_cast_timer_timeout():
	raycast.queue_free()


func _on_pre_fan_timer_timeout():
	change_activation(true)
	fan_timer.start()


func _on_fan_timer_timeout():
	change_activation(false)
	recharge_timer.start()


func _on_recharge_timer_timeout():
	change_activation(true)


func change_activation(new_activation):
	is_active = new_activation
	activation_changed.emit(new_activation)


func change_ammo(new_ammo):
	current_ammo = new_ammo
	ammo_changed.emit(new_ammo)


func reload():
	if current_ammo == max_ammo: return
	
	pre_fan_timer.stop()
	fan_timer.stop()
	recharge_timer.stop()
	
	change_activation(false)
	reload_timer.start()
	
	reload_state_changed.emit(true)


func _on_reload_timer_timeout():
	change_ammo(max_ammo)
	change_activation(true)
	
	reload_state_changed.emit(false)
