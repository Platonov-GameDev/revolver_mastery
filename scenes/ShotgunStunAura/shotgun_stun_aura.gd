extends Area3D


@onready var lifetime_timer = $LifetimeTimer


func _ready():
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	body_entered.connect(_on_body_entered)


func _process(delta):
	var new_scale = scale.x + delta * 100
	scale = Vector3(new_scale, new_scale, new_scale)


func _on_body_entered(body):
	body.stun_component.activate()


func _on_lifetime_timer_timeout():
	queue_free()
