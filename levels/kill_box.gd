extends Area3D


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.die()
	else:
		GameManager.record_enemy_died()
		body.queue_free()
