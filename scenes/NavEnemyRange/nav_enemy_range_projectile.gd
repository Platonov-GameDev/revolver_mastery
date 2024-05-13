extends CharacterBody3D


func _ready():
	$LifetimeTimer.timeout.connect(_on_lifetime_timer_timeout)


func _process(_delta):
	move_and_slide()
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			collider.health_component.receive_damage(15)
		
		queue_free()


func _on_lifetime_timer_timeout():
	queue_free()
