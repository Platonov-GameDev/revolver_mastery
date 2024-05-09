extends Area3D


@export var trail_scene: PackedScene
var bounces_remaining


func _ready():
	body_entered.connect(_on_body_entered)
	$LifetimeTimer.timeout.connect(_on_lifetime_timer_timeout)


func _on_body_entered(body):
	if bounces_remaining <= 0:
		queue_free()
		return
	
	var enemy = body
	var raycast = RayCast3D.new()
	raycast.position = global_position
	var lowered_position = global_position
	lowered_position.y -= 1
	raycast.target_position = enemy.global_position - lowered_position
	raycast.set_collision_mask_value(1, true)
	raycast.set_collision_mask_value(2, true)
	get_parent().add_child(raycast)
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	if collider: 
		if collider.is_in_group("enemy"):
			$LifetimeTimer.start()
			
			collider.receive_damage(30)
			
			var shot_trail = trail_scene.instantiate()
			shot_trail.scale.z = raycast.position.distance_to(raycast.get_collision_point()) / 100
			shot_trail.position = global_position
			get_parent().add_child(shot_trail)
			shot_trail.look_at(raycast.get_collision_point())
			
			position = raycast.get_collision_point()
			bounces_remaining -= 1
			
			ChargeMoveQueue.move_performed(MoveType.RICOCHET)
	raycast.queue_free()


func _on_lifetime_timer_timeout():
	queue_free()
	pass
