extends CharacterBody3D


@export var explosion_scene: PackedScene
@export var enemy_toss_strength = 15
@export var player_toss_strength = 20
@export var max_player_toss_distance = 10
@onready var affect_area = $AffectArea
@onready var explode_timer = $ExplodeTimer
var move_type = MoveType.GRENADE


func _ready():
	explode_timer.timeout.connect(_on_explode_timer_timeout)


func _process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		if explode_timer.time_left == 0:
			explode()


func explode():
	explode_timer.start()


func implode():
	pass


func _on_explode_timer_timeout():
	var bodies = affect_area.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("enemy"):
			body.receive_damage(50)
			
			body.velocity.y = enemy_toss_strength
			
			var charge = ChargeMoveQueue.move_performed(move_type)
			ChargeMoveQueue.spawn_charge_label(body.position, charge)
		elif body.is_in_group("player"):
			var player_position = body.position
			player_position.y += 1
			var toss_direction = (player_position - position).normalized()
			var toss_goodness = clampf(
				1 - player_position.distance_to(position) / max_player_toss_distance, 0, 1)
			var toss_velocity = toss_direction * player_toss_strength * toss_goodness
			body.toss(toss_velocity)
	
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	get_parent().add_child(explosion)
	
	queue_free()
