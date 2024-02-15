# vertex_utils.gd
# some of the code is from https://alfredbaudisch.com/blog/gamedev/godot-engine/godot-engine-in-game-splat-map-texture-painting-dirt-removal-effect/

extends Node


signal finished_map
signal added_coordinate(coordinate: Vector3)


var percent = 0
var map = []
func get_uv_to_3d_coordinates_array(mesh:Mesh, uv_map_size:Vector2i, sphere_radius := 0):
	
	var faces = _get_uv_triangles_array(mesh, uv_map_size)

	for x in uv_map_size.x:
		map.append([])
		_set_and_print_percents(x, uv_map_size.x)
		
		for y in uv_map_size.y:
			_uv_to_3d_step(x, y, faces)
	
	if sphere_radius != 0:
		_spherise_map(sphere_radius, uv_map_size)
	
	call_thread_safe("emit_signal", "finished_map")


func cart2bary(p : Vector3, a : Vector3, b : Vector3, c: Vector3) -> Vector3:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	return Vector3(u, v, w)


func bary2cart(a : Vector3, b : Vector3, c: Vector3, barycentric: Vector3) -> Vector3:
	return barycentric.x * a + barycentric.y * b + barycentric.z * c


func cart2bary2d(p : Vector2, a : Vector2, b : Vector2, c: Vector2) -> Vector3:
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	return Vector3(u, v, w)


func bary2cart2d(a : Vector2, b : Vector2, c: Vector2, barycentric: Vector3) -> Vector2:
	return barycentric.x * a + barycentric.y * b + barycentric.z * c


func is_point_in_triangle(point, v1, v2, v3, tolerance = 0.001):
	var bc
	if point is Vector3:
		bc = cart2bary(point, v1, v2, v3)
	elif point is Vector2:
		bc = cart2bary2d(point, v1, v2, v3)
	else:
		return null
	
	var t = tolerance
	if (bc.x < 0-t or bc.x > 1+t) or (bc.y < 0-t or bc.y > 1+t) or (bc.z < 0-t or bc.z > 1+t):
		return null
		
	return bc


func _get_uv_triangles_array(mesh:Mesh, uv_map_size:Vector2i) -> Array:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	
	var faces = []
	for face_id in mesh_tool.get_face_count():
		var face = []
		for i in 3:
			var vertex_id = mesh_tool.get_face_vertex(face_id, i)
			var vertex = {
				"location" = mesh_tool.get_vertex(vertex_id),
				"uv" = mesh_tool.get_vertex_uv(vertex_id)
			}
			vertex.uv.x = vertex.uv.x * uv_map_size.x
			vertex.uv.y = vertex.uv.y * uv_map_size.y
			face.append(vertex)
		faces.append(face)
	
	return faces


func _uv_to_3d(uv, faces, tolerance):
	for face in faces:
		var bary = is_point_in_triangle(uv, face[0].uv, face[1].uv, face[2].uv, tolerance)
		if bary != null:
			var uv_3d_coords = bary2cart(face[0].location, face[1].location, face[2].location, bary)
			return uv_3d_coords
	
	return 0


func _uv_to_3d_step(x, y, faces):
	map[x].append(0)
	
	# Try 3 times to remove visible seams.
	# I know it's not the best solution, but it's good enough.
	map[x][y] = _uv_to_3d(Vector2(x, y), faces, 0.001)
	
	if map[x][y] is int:
		map[x][y] = _uv_to_3d(Vector2(x, y), faces, 0.01)
	
	if map[x][y] is int:
		map[x][y] = _uv_to_3d(Vector2(x, y), faces, 0.1)
	
	if not map[x][y] is int:
		call_thread_safe("emit_signal", "added_coordinate", map[x][y])

# If the mesh is a sphere, then normalize all coordinates,
# and multiply them by given radius.
func _spherise_map(sphere_radius, uv_map_size):
	for x in uv_map_size.x:
		for y in uv_map_size.y:
			if not map[x][y] is int:
				map[x][y] = map[x][y].normalized() * sphere_radius


func _set_and_print_percents(current, maximum):
	@warning_ignore("narrowing_conversion")
	var new_percent = Utils.get_percent(current, maximum, 0.1) + 0.1
	if percent != new_percent:
		percent = new_percent
		print(str(percent) + '%')
