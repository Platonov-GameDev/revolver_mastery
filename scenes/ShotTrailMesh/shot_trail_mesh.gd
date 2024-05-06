extends StaticBody3D


func _ready():
	$LifetimeTimer.timeout.connect(_on_lifetime_timer_timeout)


func _on_lifetime_timer_timeout():
	queue_free()
