class_name Uv3DMap extends Resource

@export var map = [[]]
@export var size = Vector2i.ZERO


func get_pixel_3d_location_v(pixel: Vector2i):
	if not pixel.x < map.size():
		if not pixel.y < map[0].size():
			return map[pixel.x][pixel.y]
	return null


func get_pixel_3d_location(x, y):
	if not x < map.size():
		if not y < map[0].size():
			return map[x][y]
	return null
