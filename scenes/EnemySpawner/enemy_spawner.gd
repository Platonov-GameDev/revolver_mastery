extends Node


@export var enemy_scene: PackedScene
@export var player: CharacterBody3D
@export var spawn_path_follow: PathFollow3D
@onready var timer = $Timer


# Called when the node enters the scene tree for the first time.
func _ready():
	timer.timeout.connect(_on_timer_timeout)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	spawn_path_follow.progress_ratio = randf()
	var spawn_position = spawn_path_follow.position
	
	var enemy = enemy_scene.instantiate()
	enemy.player = player
	enemy.position = spawn_position
	add_child(enemy)
