extends Node3D


@export var bullet_shell_scene: PackedScene
@export var trail_scene: PackedScene
@export var camera: Camera3D
@export var shell_spawner: Node3D
@export var ricochet_scene: PackedScene
@onready var ray_cast_timer = $RayCastTimer
@onready var pre_fan_timer = $PreFanTimer
@onready var fan_timer = $FanTimer
@onready var recharge_timer = $RechargeTimer
@onready var reload_timer = $ReloadTimer
var raycast: RayCast3D
var shot_trail
var is_active = true
var current_ammo = 6
var max_ammo = 6
var bullet_shell_eject_impulse = 5
var air_shot_push_impulse = 3
var ricochet_count = 2
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
	
	if !get_parent().is_on_floor():
		get_parent().velocity.y = air_shot_push_impulse
	
	raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	raycast.set_collision_mask_value(1, true)
	raycast.set_collision_mask_value(2, true)
	raycast.set_collision_mask_value(4, true)
	raycast.collide_with_areas = true
	get_parent().get_parent().add_child(raycast)
	
	ray_cast_timer.start()
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	if collider:
		if collider.is_in_group("enemy"):
			var ricochet = ricochet_scene.instantiate()
			ricochet.position = raycast.get_collision_point()
			ricochet.bounces_remaining = ricochet_count
			get_parent().get_parent().add_child(ricochet)
			
			collider.queue_free()
		elif collider.is_in_group("bullet_shell") && collider.is_class("Area3D"):
			collider.get_parent().explode()
	
	shot_trail = trail_scene.instantiate()
	shot_trail.scale.z = raycast.position.distance_to(raycast.get_collision_point()) / 100
	shot_trail.position = global_position
	shot_trail.rotation = camera.global_rotation
	get_parent().get_parent().add_child(shot_trail)
	
	var bullet_shell = bullet_shell_scene.instantiate() as RigidBody3D
	bullet_shell.position = shell_spawner.global_position
	bullet_shell.rotation = shell_spawner.global_rotation
	var bullet_shell_eject_direction = Vector3.UP + Vector3.RIGHT
	bullet_shell_eject_direction = bullet_shell_eject_direction.rotated(Vector3.UP, shell_spawner.global_rotation.y)
	bullet_shell.apply_impulse(bullet_shell_eject_direction * bullet_shell_eject_impulse)
	bullet_shell.apply_torque(Vector3(1, 0, 1))
	get_parent().get_parent().add_child(bullet_shell)
	
	fan_timer.stop()
	change_ammo(current_ammo - 1)
	change_activation(false)
	if current_ammo != 0:
		pre_fan_timer.start()


func _on_ray_cast_timer_timeout():
	raycast.queue_free()
	shot_trail.queue_free()


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
