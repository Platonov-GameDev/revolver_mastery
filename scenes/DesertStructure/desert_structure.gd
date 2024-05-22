extends Node3D


@export var basic_enemy_scene: PackedScene
@export var range_enemy_scene: PackedScene
@export var structure_array: Array[PackedScene]
@onready var spawn_impulse_timer = $SpawnImpulseTimer
@onready var player_detection_area = $PlayerDetectionArea
@onready var chunk: NavigationRegion3D = get_parent()
var spawn_points: Array[Node3D]
var enemies_left_to_spawn = {
	"basic": 0,
	"range": 0
}
var structure: NavigationRegion3D
var player: CharacterBody3D


func _ready():
	spawn_impulse_timer.timeout.connect(_on_spawn_impulse_timer_timeout)
	player_detection_area.body_entered.connect(_on_player_detection_area_body_entered)
	player_detection_area.body_exited.connect(_on_player_detection_area_body_exited)
	
	var structure_scene = structure_array.pick_random()
	structure = structure_scene.instantiate() as Node3D
	structure.rotation.y = randi()
	add_child(structure)
	
	for spawn_point in structure.spawn_points.get_children():
		spawn_points.append(spawn_point as Node3D)
	
	var kills = GameManager.total_enemies_killed
	if kills < 10:
		enemies_left_to_spawn.basic = 10
	elif kills < 30:
		enemies_left_to_spawn.basic = 20
	elif kills < 45:
		enemies_left_to_spawn.basic = 10
		enemies_left_to_spawn.range = 5
	else:
		enemies_left_to_spawn.basic = 20
		enemies_left_to_spawn.range = 10


func _on_spawn_impulse_timer_timeout():
	for spawn_point in spawn_points:
		var enemy
		if enemies_left_to_spawn.basic > 0:
			enemy = basic_enemy_scene.instantiate()
			enemies_left_to_spawn.basic -= 1
		elif enemies_left_to_spawn.range > 0:
			enemy = range_enemy_scene.instantiate()
			enemies_left_to_spawn.range -= 1
		else:
			spawn_impulse_timer.stop()
			remove_spawn_points()
			break
		
		add_child(enemy)
		enemy.global_position = spawn_point.global_position
		enemy.player = player


func _on_player_detection_area_body_entered(body):
	player = body
	spawn_impulse_timer.start()
	
	#structure.enabled = true
	chunk.enabled = true


func _on_player_detection_area_body_exited(body):
	#structure.enabled = false
	chunk.enabled = false


func remove_spawn_points():
	for spawn_point in spawn_points:
		if is_instance_valid(spawn_point):
			spawn_point.queue_free()
