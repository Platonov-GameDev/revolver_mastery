extends Node


@onready var slow_timer = $SlowTimer
var is_slowed = false
var slow_ratio = 0.5
signal slow_changed(new_is_slowed)


func _ready():
	slow_timer.timeout.connect(_on_slow_timer_timeout)


func activate():
	slow_timer.start()
	is_slowed = true
	slow_changed.emit(is_slowed)


func _on_slow_timer_timeout():
	is_slowed = false
	slow_changed.emit(is_slowed)
