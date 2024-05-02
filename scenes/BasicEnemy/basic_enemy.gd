extends CharacterBody3D


@export var player: CharacterBody3D
@onready var hurtbox = $HurtBox
var move_speed = 3


func _ready():
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)


func _process(delta):
	velocity.y -= Global.gravity_acceleration * delta
	
	var player_direction = player.position - position
	player_direction.y = 0
	player_direction = player_direction.normalized() * move_speed
	velocity.x = player_direction.x
	velocity.z = player_direction.z
	
	move_and_slide()


func _on_hurtbox_body_entered(body):
	if body.is_in_group("player"):
		get_tree().reload_current_scene()
