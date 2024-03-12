## vertex_utils.gd
## some of the code is from https://alfredbaudisch.com/blog/gamedev/godot-engine/godot-engine-in-game-splat-map-texture-painting-dirt-removal-effect/

extends Node


signal finished_map
signal finished_face(face: Dictionary)


var percent = 0
var map = []
var map_size:Vector2i

## Main method ##

func get_uv_to_3d_coordinates_array(mesh:Mesh, uv_map_size:Vector2i, sphere_radius := 0):
	
	map_size = uv_map_size
	_initialize_map()
	
	var faces = _get_uv_triangles_array(mesh)
	
	for face_id in faces.size():
		_add_face_pixels_to_map(faces[face_id])
		call_thread_safe("emit_signal", "finished_face", faces[face_id])
		_set_and_print_percents(face_id, faces.size())
	
	if sphere_radius != 0:
		_spherise_map(sphere_radius)
	
	call_thread_safe("emit_signal", "finished_map")



## Barycentric functions ##

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


func is_point_in_triangle(point:Vector2, v1:Vector2, v2:Vector2, v3:Vector2, tolerance := 0.0) -> bool:
	var bc = cart2bary2d(point, v1, v2, v3)
	
	var t = tolerance
	if (bc.x < 0-t or bc.x > 1+t) or (bc.y < 0-t or bc.y > 1+t) or (bc.z < 0-t or bc.z > 1+t):
		return false
	return true



## Other functions ##

func get_distance_from_line(p:Vector2, l1:Vector2, l2:Vector2) -> float:
	var top = abs((l2.x - l1.x) * (l1.y - p.y) - (l1.x - p.x) * (l2.y - l1.y))
	var bot = sqrt(pow((l2.x - l1.x), 2) + pow((l2.y - l1.y), 2))
	return top/bot


## Private methods ##

func _initialize_map():
	for x in map_size.x:
		map.append([])
		for y in map_size.y:
			map[x].append(0)


# faces.face:
#	verticies.vertex:
#		location: *location of the vertex in 3D space*
#		uv: *location of the vertex on uv plane*
#	max_x: *highest x coordinate of triangle verticies on the UV map*
#	min_x: *lowest x coordinate of triangle verticies on the UV map*
#	max_y: *highest y coordinate of triangle verticies on the UV map*
#	min_y: *lowest y coordinate of triangle verticies on the UV map*
func _get_uv_triangles_array(mesh:Mesh) -> Array:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	
	var faces = []
	for face_id in mesh_tool.get_face_count():
		var face = {
			"verticies": [],
			"max_x": 0,
			"min_x": 0,
			"max_y": 0,
			"min_y": 0
		}
		for i in 3:
			var vertex_id = mesh_tool.get_face_vertex(face_id, i)
			var vertex = {
				"location": mesh_tool.get_vertex(vertex_id),
				"uv": mesh_tool.get_vertex_uv(vertex_id)
			}
			#make coordinates relative to given image size
			vertex.uv.x = vertex.uv.x * map_size.x
			vertex.uv.y = vertex.uv.y * map_size.y
			face.verticies.append(vertex)
		
		face.max_x = max(face.verticies[0].uv.x, face.verticies[1].uv.x, face.verticies[2].uv.x) + 1
		face.min_x = min(face.verticies[0].uv.x, face.verticies[1].uv.x, face.verticies[2].uv.x) - 1
		face.max_y = max(face.verticies[0].uv.y, face.verticies[1].uv.y, face.verticies[2].uv.y) + 1
		face.min_y = min(face.verticies[0].uv.y, face.verticies[1].uv.y, face.verticies[2].uv.y) - 1
		
		# cut them so they won't exceed map size
		face.max_x = min(face.max_x, map_size.x)
		face.min_x = max(face.min_x, 0)
		face.max_y = min(face.max_y, map_size.y)
		face.min_y = max(face.min_y, 0)
		
		
		faces.append(face)
	return faces


func _add_face_pixels_to_map(face):
	var x_range = range(face.min_x, face.max_x)
	var y_range = range(face.min_y, face.max_y)
	
	for x in x_range:
		for y in y_range:
			
			var pixel = Vector2(x, y)
			
			if _is_pixel_in_face(pixel, face):
				var loc3d = _get_pixel_3d_location(pixel, face)
				_add_pixel_to_map(pixel, loc3d)
				
			elif _is_pixel_close_enough(pixel, face):
				var loc3d = _get_pixel_3d_location(pixel, face)
				_add_pixel_to_map(pixel, loc3d)


func _is_pixel_in_face(pixel, face):
	return is_point_in_triangle(pixel, face.verticies[0].uv, face.verticies[1].uv, face.verticies[2].uv)


func _is_pixel_close_enough(pixel, face):
	var distance_1 = get_distance_from_line(pixel, face.verticies[0].uv, face.verticies[1].uv)
	var distance_2 = get_distance_from_line(pixel, face.verticies[1].uv, face.verticies[2].uv)
	var distance_3 = get_distance_from_line(pixel, face.verticies[0].uv, face.verticies[2].uv)
	var min_distance = min(distance_1, distance_2, distance_3)
	
	if min_distance <= sqrt(2):
		return true
	return false


func _get_pixel_3d_location(pixel, face) -> Vector3:
	var bary = cart2bary2d(pixel, face.verticies[0].uv, face.verticies[1].uv, face.verticies[2].uv)
	var location = bary2cart(face.verticies[0].location, face.verticies[1].location, face.verticies[2].location, bary)
	return location


func _add_pixel_to_map(pixel:Vector2, loc3d:Vector3):
	var x = pixel.x
	var y = pixel.y
	if map[x][y] is Vector3:
		map[x][y] = loc3d.lerp(map[x][y], 0.5)
	else:
		map[x][y] = loc3d
	
	#call_thread_safe("emit_signal", "added_coordinate", map[x][y])


# If the mesh is a sphere, then normalize all coordinates,
# and multiply them by given radius.
func _spherise_map(sphere_radius):
	for x in map_size.x:
		for y in map_size.y:
			if not map[x][y] is int:
				map[x][y] = map[x][y].normalized() * sphere_radius


func _set_and_print_percents(current, maximum):
	@warning_ignore("narrowing_conversion")
	var new_percent = Utils.get_percent(current, maximum, 0.1) + 0.1
	if percent != new_percent:
		percent = new_percent
		print(str(percent) + '%')


