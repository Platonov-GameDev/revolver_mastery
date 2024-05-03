extends CharacterBody3D


@export var player: CharacterBody3D
@onready var hurtbox = $HurtBox
var move_speed = 7
var max_velocity = 7


func _ready():
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	
	if is_on_floor():
		var player_direction = player.position - position
		player_direction.y = 0
		player_direction = player_direction.normalized() * move_speed
		var delta_velocity = player_direction * delta
		var new_velocity = Vector3(velocity.x + delta_velocity.x, 0, velocity.z + delta_velocity.z)
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
