extends MeshInstance3D


func _ready():
	$Timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout():
	queue_free()
