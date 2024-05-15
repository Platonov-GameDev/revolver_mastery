extends Node


@export var red_scene: PackedScene
@export var purple_scene: PackedScene
@export var player: CharacterBody3D
@export var nav_region: NavigationRegion3D
@export var spawn_points: Array[Node3D]
@onready var spawn_timer = $SpawnTimer
@onready var impulse_timer = $ImpulseTimer
@onready var spawn_impulses = $SpawnImpulses
var current_impulse_index = 0
var last_impulse_index = 0
var red_left = 0
var purple_left = 0


func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	impulse_timer.timeout.connect(_on_impulse_timer_timeout)
	
	_on_impulse_timer_timeout()


func _on_spawn_timer_timeout():
	for i in range(spawn_points.size()):
		var enemy
		if red_left != 0:
			enemy = red_scene.instantiate()
			red_left -= 1
		elif purple_left != 0:
			enemy = purple_scene.instantiate()
			purple_left -= 1
		if enemy != null:
			enemy.player = player
			enemy.position = spawn_points[i].global_position
			add_child(enemy)


func _on_impulse_timer_timeout():
	var current_impulse = spawn_impulses.get_child(current_impulse_index)
	if current_impulse != null:
		red_left = current_impulse.red_count
		purple_left = current_impulse.purple_count
		last_impulse_index = current_impulse_index
	elif current_impulse == null:
		current_impulse = spawn_impulses.get_child(last_impulse_index)
		red_left = current_impulse.red_count
		purple_left = current_impulse.purple_count
	current_impulse_index += 1
