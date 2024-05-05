extends CharacterBody3D


@export var player: CharacterBody3D
@export var projectile_scene: PackedScene
@onready var hurtbox = $HurtBox
@onready var nav_agent = $NavigationAgent3D
@onready var shoot_timer = $ShootTimer
@onready var muzzle = $Muzzle
var move_speed = 5
var projectile_speed = 15
var is_reloading = false


func _ready():
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)


func _physics_process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	
	if is_on_floor():
		if position.distance_to(player.position) <= 20:
			if !is_reloading:
				var projectile = projectile_scene.instantiate()
				projectile.position = muzzle.global_position
				projectile.velocity = (player.position - position).normalized() * projectile_speed
				get_parent().add_child(projectile)
				
				is_reloading = true
				shoot_timer.start()
			else:
				nav_agent.set_velocity(Vector3(0, velocity.y, 0))
		else:
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


func _on_shoot_timer_timeout():
	is_reloading = false
