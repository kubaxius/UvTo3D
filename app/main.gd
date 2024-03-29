extends Node3D

@export_node_path("MeshInstance3D") var mesh_node

@onready var mesh:Mesh = get_node(mesh_node).mesh
@onready var thread = Thread.new()


var map = Uv3DMap.new()


func _ready():
	VertexUtils.finished_face.connect(_face_finished)
	VertexUtils.finished_map.connect(_map_finished)


func _on_menu_start_pressed():
	_make_mesh_transparent()
	var function: Callable
	if $Menu.sphere_mode:
		function = VertexUtils.get_uv_to_3d_coordinates_array.bind(mesh, $Menu.uv_map_size)
	else:
		function = VertexUtils.get_uv_to_3d_coordinates_array.bind(mesh, $Menu.uv_map_size, $Menu.sphere_radius)
	
	if $Menu.use_threading:
		thread.start(function, Thread.PRIORITY_HIGH)
	else:
		function.call()


func _process(_delta):
	$Menu.progress_bar.value = VertexUtils.percent


func _face_finished(face:Dictionary):
	$Draw3D.draw_line([face.verticies[0].location, face.verticies[1].location, face.verticies[2].location, face.verticies[0].location], Color.GREEN)


func _map_finished():
	save_uv_3d_map()
	create_and_apply_noise_material()
	# remove the green dots
	$Draw3D.queue_free()
	$Menu.finished()
	# toggle rotation back on
	$Menu._on_check_box_toggled(true)


func _exit_tree():
	thread.wait_to_finish()


func _make_mesh_transparent():
	var material := StandardMaterial3D.new()
	material.transparency = 1
	material.albedo_color = Color(1, 1, 1, 0.75)
	mesh.surface_set_material(0, material)


func save_uv_3d_map():
	map.map = VertexUtils.map.duplicate(true)
	map.size = $Menu.uv_map_size
	ResourceSaver.save(map, "res://output/"+$Menu.output_file_name)


## Use this function if you want to restore arry from file.
func load_uv_3d_map():
	var map_resource = ResourceLoader.load("res://"+$Menu.output_file_name).duplicate(true)
	return map_resource


## Converts 3D noise to 2D map using info generated by this program.
## It just shows what can be done with this.
func create_and_apply_noise_material():
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.5
	
	var uv_3d = map.map
	var image := Image.create(map.size.x, map.size.y, false, Image.FORMAT_RGB8)
	
	for x in uv_3d.size():
		for y in uv_3d[x].size():
			if typeof(uv_3d[x][y]) == TYPE_VECTOR3:
				var noise_val = noise.get_noise_3dv(uv_3d[x][y])
				var color = Color(noise_val, noise_val, noise_val)
				image.set_pixel(x, y, color)
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	mesh.surface_set_material(0, material)


# not finished
func create_images():
	# I thought I could encode positions into this image format, but I have no idea if it's
	# even possible from GDScript, lol
	var _image = Image.create($Menu.uv_map_size.x, $Menu.uv_map_size.y, false, Image.FORMAT_RGBF)
