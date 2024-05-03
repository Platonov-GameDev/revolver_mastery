extends RigidBody3D


@export var explosion_scene: PackedScene
@onready var explode_area = $ExplodeArea
@onready var shot_area = $ShotArea
var push_impulse = 10


func _ready():
	body_entered.connect(_on_body_entered)


func explode():
	var bodies_to_push = explode_area.get_overlapping_bodies()
	
	for i in range(bodies_to_push.size()):
		bodies_to_push[i].velocity.y += push_impulse
	
	var explosion = explosion_scene.instantiate()
	explosion.position = global_position
	get_parent().add_child(explosion)
	
	queue_free()


func _on_body_entered(_body):
	if is_instance_valid(shot_area):
		shot_area.queue_free()
