extends CharacterBody3D


@onready var lifetime_timer = $LifetimeTimer
@onready var mesh = $MeshInstance3D
var player: CharacterBody3D
var suck_speed = 40


func _ready():
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)


func _process(delta):
	var lifetime = lifetime_timer.time_left / lifetime_timer.wait_time
	if lifetime <= 0.5:
		var new_scale = lifetime * 2
		mesh.scale = Vector3(new_scale, new_scale, new_scale)
	
	if !player.is_on_floor():
		velocity.y -= Global.gravity_acceleration * delta
		velocity.x = 0
		velocity.z = 0
	else:
		var target_position = player.position
		target_position.y += 0.5
		velocity = (target_position - position).normalized() * suck_speed
	
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			player.collect_xp()
			queue_free()
			break


func _on_lifetime_timer_timeout():
	queue_free()
