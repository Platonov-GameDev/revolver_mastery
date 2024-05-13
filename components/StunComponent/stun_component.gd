extends Node


@onready var stun_timer = $StunTimer
var is_stunned = false
signal stun_changed(new_is_stunned)


func _ready():
	stun_timer.timeout.connect(_on_stun_timer_timeout)


func activate():
	change_stun(true)
	stun_timer.start()


func deactivate():
	change_stun(false)


func change_stun(new_is_stunned):
	is_stunned = new_is_stunned
	stun_changed.emit(is_stunned)


func _on_stun_timer_timeout():
	deactivate()
