extends MeshInstance3D


@onready var lifetime_timer = $LifetimeTimer


func _ready():
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	scale = Vector3(.1, .1, .1)


func _process(delta):
	var grow_speed = 6
	scale += Vector3(delta, delta, delta) * grow_speed


func _on_lifetime_timer_timeout():
	queue_free()
