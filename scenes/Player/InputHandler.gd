extends Node


signal movement_inputted(input_vector)
signal jump_pressed
signal escape_pressed
signal reload_pressed
signal mouse_moved(input_vector)
signal main_fire_pressed
signal main_fire_released
signal alt_fire_pressed
signal alt_fire_released
signal enter_pressed


func _process(_delta):
	var movement_input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		movement_input_vector.y += 1
	if Input.is_action_pressed("move_back"):
		movement_input_vector.y -= 1
	if Input.is_action_pressed("move_right"):
		movement_input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		movement_input_vector.x -= 1
	movement_input_vector = movement_input_vector.normalized()
	movement_inputted.emit(movement_input_vector)
	
	if Input.is_action_just_pressed("jump"):
		jump_pressed.emit()
	
	if Input.is_action_just_pressed("ui_cancel"):
		escape_pressed.emit()
	
	if Input.is_action_just_pressed("reload"):
		reload_pressed.emit()
	
	if Input.is_action_just_pressed("main_fire"):
		main_fire_pressed.emit()
	if Input.is_action_just_released("main_fire"):
		main_fire_released.emit()
	if Input.is_action_just_pressed("alt_fire"):
		alt_fire_pressed.emit()
	if Input.is_action_just_released("alt_fire"):
		alt_fire_released.emit()
	
	if Input.is_action_just_pressed("ui_accept"):
		enter_pressed.emit()


func _input(event):
	if event is InputEventMouseMotion:
		if event.relative == Vector2.ZERO: return
		mouse_moved.emit(event.relative)
