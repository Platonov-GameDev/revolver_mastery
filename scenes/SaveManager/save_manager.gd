extends Node


var SAVE_FILENAME = "user://save"


func _ready():
	load_game()


func save_game():
	var save_file = FileAccess.open(SAVE_FILENAME, FileAccess.WRITE)
	
	var save_data = {
		"all_time_highest_kpm": GameManager.highest_kpm
	}
	var save_json = JSON.stringify(save_data)
	
	save_file.store_line(save_json)


func load_game():
	if !FileAccess.file_exists(SAVE_FILENAME): return
	
	var save_file = FileAccess.open(SAVE_FILENAME, FileAccess.READ)
	
	var save_json = save_file.get_as_text()
	var save_data = JSON.parse_string(save_json)
	
	GameManager.all_time_highest_kpm = save_data.all_time_highest_kpm
