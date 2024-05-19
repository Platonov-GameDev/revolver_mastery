extends Area3D


@onready var damage_timer = $DamageTimer
var did_damage = false


func _ready():
	damage_timer.timeout.connect(_on_damage_timer_timeout)


func _on_damage_timer_timeout():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		body.receive_damage(50)
		
		var charge = ChargeMoveQueue.move_performed(MoveType.RICOCHET_WAVE)
		ChargeMoveQueue.spawn_charge_label(body.position, charge)
