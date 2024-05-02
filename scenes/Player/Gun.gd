extends Node3D


@export var camera: Camera3D
@onready var ray_cast_timer = $RayCastTimer
var raycast: RayCast3D


func _ready():
	ray_cast_timer.timeout.connect(_on_ray_cast_timer_timeout)


func shoot():
	raycast = RayCast3D.new()
	raycast.position = global_position
	raycast.rotation = camera.global_rotation
	raycast.target_position = Vector3(0, 0, -100)
	get_parent().get_parent().add_child(raycast)
	
	ray_cast_timer.start()
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	print(collider)
	if !collider: return
	if collider.is_in_group("enemy"):
		collider.queue_free()


func _on_ray_cast_timer_timeout():
	raycast.queue_free()
