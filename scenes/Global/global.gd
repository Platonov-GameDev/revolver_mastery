extends Node


var gravity_acceleration = 18


func get_random_nav_mesh_point(nav_mesh: NavigationMesh) -> Vector3:
	var vertices_array = nav_mesh.vertices
	var random_index = randi_range(0, vertices_array.size() - 1)
	
	return vertices_array[random_index]
