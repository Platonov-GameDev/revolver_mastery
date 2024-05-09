extends CharacterBody3D


@export var explosion_scene: PackedScene
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
	
	for i in range(bodies.size()):
		bodies[i].velocity.x = 30
		bodies[i].velocity.z = 30
		bodies[i].velocity.y = 15
		
		if bodies[i].is_in_group("enemy"):
			bodies[i].receive_damage(50)
			
			ChargeMoveQueue.move_performed(move_type)
	
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	get_parent().add_child(explosion)
	
	queue_free()
