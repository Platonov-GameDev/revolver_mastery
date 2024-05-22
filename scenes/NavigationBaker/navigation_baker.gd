extends Node


var chunks_to_bake: Array[DesertChunk] = []
var is_baking_chunk := false


func _process(_delta):
	if chunks_to_bake.size() > 0 and not is_baking_chunk:
		var chunk = chunks_to_bake[0]
		chunk.bake_navigation_mesh()
		is_baking_chunk = true
		chunk.bake_finished.connect(_on_chunk_bake_finished)


func add_chunk(chunk: DesertChunk):
	chunks_to_bake.append(chunk)


func remove_chunk(chunk: DesertChunk):
	var found_index = chunks_to_bake.find(chunk)
	if found_index != -1:
		chunks_to_bake.remove_at(found_index)


func _on_chunk_bake_finished():
	chunks_to_bake.remove_at(0)
	is_baking_chunk = false
