extends Node3D


@onready var pierce_timer = $PierceTimer
@onready var lifetime_timer = $LifetimeTimer
@onready var affect_area = $AffectArea
var power = 0


func _ready():
	pierce_timer.timeout.connect(_on_pierce_timer_timeout)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)


func _on_pierce_timer_timeout():
	var bodies = affect_area.get_overlapping_bodies()
	for body in bodies:
		body.receive_damage(power * 200)
		
		var charge = ChargeMoveQueue.move_performed(MoveType.PIERCE)
		var label_position = body.global_position
		label_position.y += 1
		ChargeMoveQueue.spawn_charge_label(label_position, charge)


func _on_lifetime_timer_timeout():
	queue_free()
