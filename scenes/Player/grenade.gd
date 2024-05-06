extends CharacterBody3D


@export var explosion_scene: PackedScene
@onready var affect_area = $AffectArea


func _process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		explode()


func explode():
	var bodies = affect_area.get_overlapping_bodies()
	
	for i in range(bodies.size()):
		bodies[i].velocity.x = 30
		bodies[i].velocity.z = 30
		bodies[i].velocity.y += 10
	
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	get_parent().add_child(explosion)
	
	queue_free()


func implode():
	pass
