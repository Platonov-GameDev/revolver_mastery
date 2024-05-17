extends Node


var all_time_highest_kpm := 0
var highest_kpm := 0
var current_kpm := 0
var kill_timestamps: Array[float] = []
signal kpm_changed(new_kpm)
signal highest_kpm_changed(new_highest_kpm)
signal got_new_record()


func _process(_delta):
	if kill_timestamps.size() == 0: return
	
	var current_time = Time.get_unix_time_from_system()
	var minute_ago_time = current_time - 60
	
	var did_kill_timestamps_change := false
	while kill_timestamps[0] < minute_ago_time:
		kill_timestamps.pop_front()
		did_kill_timestamps_change = true
		if kill_timestamps.size() == 0: break
	
	if did_kill_timestamps_change:
		update_kpm()


func record_enemy_died():
	var kill_time = Time.get_unix_time_from_system()
	kill_timestamps.append(kill_time)
	update_kpm()


func update_kpm():
	current_kpm = kill_timestamps.size()
	if current_kpm > highest_kpm:
		highest_kpm = current_kpm
		highest_kpm_changed.emit(highest_kpm)
		if highest_kpm > all_time_highest_kpm:
			SaveManager.save_game()
			got_new_record.emit()
	kpm_changed.emit(current_kpm)


func reset():
	current_kpm = 0
	highest_kpm = 0
	SaveManager.load_game()
	kill_timestamps.clear()
