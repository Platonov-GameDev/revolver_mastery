extends Node


@export var max_enemy_count = 100
@export var enemy_scene: PackedScene
@export var player: CharacterBody3D
@export var nav_region: NavigationRegion3D
@export var spawn_points: Array[Node3D]
@onready var timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout():
	if get_child_count() - 1 >= max_enemy_count:
		return
	
	var random_point_index = randi_range(0, spawn_points.size() - 1)
	var spawn_point = spawn_points[random_point_index].global_position
	
	var enemy = enemy_scene.instantiate()
	enemy.player = player
	enemy.position = spawn_point
	add_child(enemy)
