extends CharacterBody3D


@export var player: CharacterBody3D
@export var xp_blob_scene: PackedScene
@onready var hurtbox = $HurtBox
@onready var nav_agent = $NavigationAgent3D
var move_speed = 6


func _ready():
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)


func _physics_process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	
	if is_on_floor():
		nav_agent.set_target_position(player.position)
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		var move_direction = (next_path_position - position).normalized()
		
		var delta_velocity = move_direction * move_speed
		var new_velocity = Vector3(delta_velocity.x, velocity.y, delta_velocity.z)
		nav_agent.set_velocity(new_velocity)
	elif !is_on_floor():
		nav_agent.set_velocity(Vector3(0, velocity.y, 0))


func _on_hurtbox_body_entered(body):
	if body.is_in_group("player"):
		get_tree().call_deferred("reload_current_scene")


func _on_nav_agent_velocity_computed(safe_velocity: Vector3):
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()


func die():
	var xp_blob = xp_blob_scene.instantiate()
	xp_blob.position = position
	xp_blob.position.y += 0.5
	xp_blob.player = player
	get_parent().add_child(xp_blob)
	
	queue_free()
