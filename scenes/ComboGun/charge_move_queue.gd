extends Node

var charge_label_scene = load("res://scenes/ChargeLabel3D/charge_label_3d.tscn")
var move_queue: Array[ChargeComboQueueItem]
var move_coefficients = {
	MoveType.FAN: 5,
	MoveType.DASH: 1,
	MoveType.AUTO: 10,
	MoveType.RICOCHET: 5,
	MoveType.SHOTGUN: 10,
	MoveType.GRENADE: 7,
	MoveType.BLAST: 7,
	MoveType.CHAIN_PULL: 10,
	MoveType.PIERCE: 15
}
signal charge_gained(charge_amount)


func move_performed(move_type, hits = 1):
	var is_move_found = false
	var move_index = 0
	for i in range(move_queue.size()):
		if move_queue[i].move_type == move_type:
			is_move_found = true
			move_index = i
			break
	
	var charge = 0
	if is_move_found:
		charge = add_hits(move_index, move_type, hits)
	else:
		var new_move_item = ChargeComboQueueItem.new()
		new_move_item.move_type = move_type
		
		move_queue.append(new_move_item)
		if move_queue.size() >= 4:
			move_queue = move_queue.slice(-3)
		charge = add_hits(-1, move_type, hits)
	
	return charge


func add_hits(move_index, move_type, hits):
	var charge = 0
	for i in range(hits):
		move_queue[move_index].hit_count += 1
		if move_queue[move_index].hit_count <= move_coefficients[move_type]:
			charge += 1. / move_coefficients[move_type]
		elif (
			move_queue[move_index].hit_count > move_coefficients[move_type] and
			move_queue[move_index].hit_count <= move_coefficients[move_type] * 2
		):
			charge += 1. / move_coefficients[move_type] / 2
	
	charge /= 2
	
	if charge > 0:
		charge_gained.emit(charge)
	
	return charge


func clear_queue():
	move_queue.clear()


func spawn_charge_label(position, charge_amount):
	if charge_amount == 0: return
	
	var charge_label = charge_label_scene.instantiate()
	charge_label.position = position
	charge_label.charge_amount = charge_amount
	
	add_child(charge_label)
