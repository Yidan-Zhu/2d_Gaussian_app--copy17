extends MeshInstance

####################
#    PARAMS
####################
# mesh
var tmpMesh = Mesh.new()
var vertices = PoolVector3Array()
var st = SurfaceTool.new()
var mat = load("res://Shading/material_Gaussian.tres")

# vertices
onready var script_parameter_axes = get_node("../..")
var x_coord_1_origin
var x_coord_1
var x_coord_2
var z_coord_origin
var z_coord
var number_of_vertices_in_row = 81

##################################

func _process(_delta):
	# params to draw vertices
	x_coord_1_origin = -script_parameter_axes.x_end.x+1
	x_coord_1 = x_coord_1_origin
	z_coord_origin = -script_parameter_axes.z_end.z+1
	z_coord = z_coord_origin
	
	# draw vertices by surface tool
	st = SurfaceTool.new()
	tmpMesh = Mesh.new()	
	
	# vertex coordinates
	vertices = PoolVector3Array()

	var step_x = 2.0*abs(x_coord_1) / (number_of_vertices_in_row - 1)
	var step_z = 2.0*abs(z_coord) / (number_of_vertices_in_row - 1)
	var value_y_1
	var value_y_2

	for n in range(number_of_vertices_in_row-2):
		x_coord_1 = x_coord_1_origin + n*step_x
		x_coord_2 = x_coord_1 + step_x
		for m in range(number_of_vertices_in_row-1):
			z_coord = z_coord_origin + m*step_z
			value_y_1 = 0
			value_y_2 = 0
			vertices.push_back(Vector3(x_coord_1, value_y_1, z_coord))
			vertices.push_back(Vector3(x_coord_2, value_y_2, z_coord))

	# add vertices by triangle_strip rule
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	for v in vertices.size():
		st.add_vertex(vertices[v])

	st.set_material(mat)
	st.commit(tmpMesh)
	mesh = tmpMesh
