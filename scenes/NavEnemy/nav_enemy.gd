extends CharacterBody3D


@export var player: CharacterBody3D
@onready var hurtbox = $HurtBox
@onready var nav_agent = $NavigationAgent3D
var move_speed = 7
var max_velocity = 7


func _ready():
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)


func _physics_process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	
	if is_on_floor():
		nav_agent.set_target_position(player.position)
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		var move_direction = (next_path_position - position).normalized() * move_speed
		
		#var delta_velocity = move_direction * delta
		#var new_velocity = Vector3(velocity.x + delta_velocity.x, 0, velocity.z + delta_velocity.z)
		var delta_velocity = move_direction * delta * 3000
		var new_velocity = Vector3(delta_velocity.x, 0, delta_velocity.z)
		new_velocity = new_velocity.limit_length(max_velocity)
		velocity.x = new_velocity.x
		velocity.z = new_velocity.z
	elif !is_on_floor():
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()


func _on_hurtbox_body_entered(body):
	if body.is_in_group("player"):
		get_tree().call_deferred("reload_current_scene")


func _on_nav_agent_velocity_computed(safe_velocity: Vector3):
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()
