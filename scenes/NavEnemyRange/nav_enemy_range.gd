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
		var raycast_to_player = RayCast3D.new()
		raycast_to_player.position = muzzle.global_position
		get_parent().add_child(raycast_to_player)
		var player_center_position = player.global_position
		player_center_position.y += 0.5
		var player_direction = (player_center_position - raycast_to_player.global_position).normalized()
		raycast_to_player.target_position = player_direction * 20
		raycast_to_player.set_collision_mask_value(3, true)
		raycast_to_player.force_raycast_update()
		var raycast_collider = raycast_to_player.get_collider()
		raycast_to_player.queue_free()
		
		var player_visible = false
		if is_instance_valid(raycast_collider):
			if raycast_collider.is_in_group("player"):
				player_visible = true
		
		if player_visible:
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
