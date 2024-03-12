class_name Uv3DMap extends Resource

@export var map = [[]]
@export var size = Vector2i.ZERO


class Pixel:
	# Variables
	var _true_location_2d: Vector2i
	var location_3d: Vector3
	var is_set := false
	
	# Fake variables
	var location_2d: Vector2i:
		set(val):
			_warning_message()
		get:
			return _true_location_2d
	var x2d: int:
		set(val):
			_warning_message()
		get:
			return location_2d.x
	var y2d: int:
		set(val):
			_warning_message()
		get:
			return location_2d.y
	var x3d: float:
		get:
			return location_3d.x
	var y3d: float:
		get:
			return location_3d.y
	var z3d: float:
		get:
			return location_3d.z
	
	
	# Constructor
	func _init(p_location_2d: Vector2i, p_location_3d := Vector3.ZERO, p_is_set = false):
		_true_location_2d = p_location_2d
		location_3d = p_location_3d
		is_set = p_is_set
	
	
	# Warning shown when trying to change unchangable variable 
	func _warning_message():
		print("Warning! Attempting to change variable that shouldn't be changed.")
	
	
	# If the pixel has no 3D location, it sets it.
	# Otherwise, it interpolates between the old and new value and uses the result.
	func set_or_interpolate(p_location_3d:Vector3):
		if is_set:
			location_3d = location_3d.lerp(p_location_3d, 0.5)
		else:
			location_3d = p_location_3d
			is_set = true
			


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
