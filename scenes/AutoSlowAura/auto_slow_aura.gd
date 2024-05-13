extends Area3D


@onready var lifetime_timer = $LifetimeTimer
@onready var mesh_instance_3d = $MeshInstance3D
@onready var collision_shape_3d = $CollisionShape3D


# Called when the node enters the scene tree for the first time.
func _ready():
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var new_scale = collision_shape_3d.scale.x + delta * 900
	collision_shape_3d.scale = Vector3(new_scale, new_scale, new_scale)
	
	new_scale = mesh_instance_3d.scale.x + delta * 100
	mesh_instance_3d.scale = Vector3(new_scale, new_scale, new_scale)


func _on_body_entered(body):
	body.slowed_component.activate()


func _on_lifetime_timer_timeout():
	queue_free()
