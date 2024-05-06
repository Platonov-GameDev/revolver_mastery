extends Node


@export var max_health = 100
@export var mesh: MeshInstance3D
@export var damaged_material: Material
@onready var mesh_glow_timer = $MeshGlowTimer
var current_health
signal died


func _ready():
	current_health = max_health
	mesh_glow_timer.timeout.connect(_on_mesh_glow_timer_timeout)


func receive_damage(damage_amount: int):
	current_health -= damage_amount
	mesh.set_surface_override_material(0, damaged_material)
	mesh_glow_timer.start()
	
	var enemy = get_parent()
	if !enemy.is_on_floor():
		enemy.velocity.y = 3
	
	if current_health <= 0:
		died.emit()


func _on_mesh_glow_timer_timeout():
	mesh.set_surface_override_material(0, null)
