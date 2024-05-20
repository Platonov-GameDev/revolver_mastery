extends Label3D


var charge_amount = 0
var is_fading_out = false


func _ready():
	$FadeoutStartTimer.timeout.connect(_on_fadeout_start_timer_timeout)
	$FadeoutTimer.timeout.connect(_on_fadeout_timer_timeout)
	
	text = str(snapped(charge_amount * 1000, 1))


func _process(delta):
	position.y += delta / 2
	
	if is_fading_out:
		modulate.a -= delta * 2
		outline_modulate.a -= delta * 2


func _on_fadeout_start_timer_timeout():
	$FadeoutTimer.start()
	is_fading_out = true


func _on_fadeout_timer_timeout():
	queue_free()
