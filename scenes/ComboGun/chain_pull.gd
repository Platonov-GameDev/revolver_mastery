extends Node3D


@export var chain_mesh_scene: PackedScene
@onready var pull_timer = $PullTimer
@onready var pulling_timer = $PullingTimer
@onready var affect_area = $AffectArea
var pulled_bodies: Array[Node3D]
var chain_meshes: Array[StaticBody3D]
var is_pulling = false
var pull_speed = 10


func _ready():
	pull_timer.timeout.connect(_on_pull_timer_timeout)
	pulling_timer.timeout.connect(_on_pulling_timer_timeout)


func _process(_delta):
	if !is_pulling: return
	
	for chain_mesh in chain_meshes:
		chain_mesh.queue_free()
	chain_meshes.clear()
	
	for body in pulled_bodies:
		if !is_instance_valid(body): continue
		var pull_vector = body.position - position
		body.velocity = -pull_vector * pull_speed
		
		var chain_mesh = chain_mesh_scene.instantiate() as StaticBody3D
		add_child(chain_mesh)
		chain_mesh.look_at(body.position)
		chain_mesh.scale.z = pull_vector.length() / 100
		chain_meshes.append(chain_mesh)


func _on_pull_timer_timeout():
	pulled_bodies = affect_area.get_overlapping_bodies()
	for body in pulled_bodies:
		body.current_state = EnemyState.PULLED
	
	is_pulling = true
	pulling_timer.start()
	
	ChargeMoveQueue.move_performed(MoveType.CHAIN_PULL, pulled_bodies.size())


func _on_pulling_timer_timeout():
	for body in pulled_bodies:
		body.current_state = EnemyState.BASE
	
	queue_free()
