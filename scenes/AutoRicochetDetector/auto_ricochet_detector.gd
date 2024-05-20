extends Area3D


@export var trail_scene: PackedScene
@onready var detection_timer = $DetectionTimer
var level


func _ready():
	detection_timer.timeout.connect(_on_detection_timer_timeout)


func _on_detection_timer_timeout():
	var bodies = get_overlapping_bodies()
	if bodies.is_empty():
		queue_free()
		return
	
	var enemy = bodies.pick_random()
	
	var check_raycast = RayCast3D.new()
	check_raycast.position = position
	var enemy_center = enemy.position
	enemy_center.y += 1
	check_raycast.target_position = enemy_center - position
	level.add_child(check_raycast)
	check_raycast.set_collision_mask_value(1, true)
	check_raycast.set_collision_mask_value(2, true)
	check_raycast.force_raycast_update()
	
	if !check_raycast.get_collider():
		queue_free()
		return
	
	if check_raycast.get_collider().is_in_group("enemy"):
		var hit_enemy = check_raycast.get_collider()
		var ricochet_shot_trail = trail_scene.instantiate()
		ricochet_shot_trail.scale.z = position.distance_to(check_raycast.get_collision_point()) / 100
		ricochet_shot_trail.scale.x = 0.3
		ricochet_shot_trail.scale.y = 0.3
		ricochet_shot_trail.position = position
		ricochet_shot_trail.look_at_from_position(position, check_raycast.target_position + position)
		level.add_child(ricochet_shot_trail)
	
		var charge = ChargeMoveQueue.move_performed(MoveType.RICOCHET)
		ChargeMoveQueue.spawn_charge_label(check_raycast.get_collision_point(), charge)
		
		hit_enemy.receive_damage(10)
	
	check_raycast.queue_free()
	queue_free()
