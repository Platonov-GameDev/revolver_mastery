extends CharacterBody3D


@export var player: CharacterBody3D
@export var xp_blob_scene: PackedScene
@onready var nav_agent = $NavigationAgent3D
@onready var health_component = $HealthComponent
@onready var player_detection_area = $PlayerDetectionArea
@onready var hurtbox = $Hurtbox
@onready var hurtbox_show_timer = $Hurtbox/HurtboxShowTimer
@onready var hurtbox_mesh = $Hurtbox/HurtboxMesh
@onready var marked_component = $MarkedComponent
@onready var mesh = $MeshInstance3D
@onready var slowed_component = $SlowedComponent
@onready var stun_component = $StunComponent
var move_speed = 10
var xp_drop = 1
var current_state = EnemyState.BASE


func _ready():
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)
	health_component.died.connect(_on_health_component_died)
	hurtbox_show_timer.timeout.connect(_on_hurtbox_show_timer_timeout)
	stun_component.stun_changed.connect(_on_stun_component_stun_changed)


func _physics_process(delta):
	if current_state == EnemyState.BASE:
		velocity.y -= Global.gravity_acceleration * delta
		
		if is_on_floor():
			if nav_agent.target_position.distance_to(player.position) >= 1:
				nav_agent.set_target_position(player.position)
			
			var next_path_position: Vector3 = nav_agent.get_next_path_position()
			var move_direction = (next_path_position - position).normalized()
			
			var delta_velocity = move_direction * move_speed
			if slowed_component.is_slowed:
				delta_velocity *= slowed_component.slow_ratio
			var new_velocity = Vector3(delta_velocity.x, velocity.y, delta_velocity.z)
			nav_agent.set_velocity(new_velocity)
			
			var new_rotation = move_direction.dot(Vector3.FORWARD.rotated(Vector3.UP, rotation.y))
			rotate_y(new_rotation)
			
			var detected_bodies = player_detection_area.get_overlapping_bodies()
			if detected_bodies.size() == 1:
				attack()
		elif !is_on_floor():
			nav_agent.set_velocity(Vector3(0, velocity.y, 0))
	elif current_state == EnemyState.PULLED:
		nav_agent.set_velocity(velocity)
	elif current_state == EnemyState.MELEE_ATTACK:
		nav_agent.set_velocity(Vector3(0, velocity.y, 0))
	elif current_state == EnemyState.STUNNED:
		nav_agent.set_velocity(Vector3(0, velocity.y, 0))


func _on_nav_agent_velocity_computed(safe_velocity: Vector3):
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	move_and_slide()


func _on_health_component_died():
	GameManager.record_enemy_died()
	queue_free()


func receive_damage(damage_amount):
	if marked_component.is_marked:
		damage_amount *= 2
	health_component.receive_damage(damage_amount)


func attack():
	var bodies = hurtbox.get_overlapping_bodies()
	if bodies.size() == 0: return
	
	var player_body = bodies[0]
	player_body.health_component.receive_damage(20)
	
	hurtbox_mesh.show()
	hurtbox_show_timer.start()
	
	current_state = EnemyState.MELEE_ATTACK


func _on_hurtbox_show_timer_timeout():
	hurtbox_mesh.hide()
	current_state = EnemyState.BASE


func _on_stun_component_stun_changed(new_is_stunned):
	if new_is_stunned:
		current_state = EnemyState.STUNNED
	else:
		current_state = EnemyState.BASE
