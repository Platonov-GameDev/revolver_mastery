extends Node


@export var entity_mesh: MeshInstance3D
@export var marked_material: StandardMaterial3D
@onready var mark_timer = $MarkTimer
var is_marked = false


func _ready():
	mark_timer.timeout.connect(_on_mark_timer_timeout)


func activate():
	entity_mesh.material_overlay = marked_material
	is_marked = true
	mark_timer.start()


func deactivate():
	entity_mesh.material_overlay = null
	is_marked = false


func _on_mark_timer_timeout():
	deactivate()
