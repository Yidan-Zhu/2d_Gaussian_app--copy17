extends Spatial

###################
#    PARAMS
###################
# axis
var p = Array()
onready var draw_line_geometry = get_node("ImmediateGeometry_draw_3dlines")
var	x_end = Vector3(5,0,0)
var	y_end = Vector3(0,4,0)
var	z_end = Vector3(0,0,5)
var origin = Vector3(0,0,0)

# axes labels
onready var camera = get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_camera/Viewport_camera/Camera")
export var x_end_projection_pos = Vector2()
export var x_end_projection_neg = Vector2()
export var y_end_projection = Vector2()
export var z_end_projection_pos = Vector2()
export var z_end_projection_neg = Vector2()
export var origin_projection = Vector2()
onready var label_x = get_node("Label_x")
onready var label_z = get_node("Label_z ")
onready var label_negx = get_node("Label_-x")
onready var label_negz = get_node("Label_-z")
onready var label_Pxz = get_node("Label_P(x,z)")
var text_space_xz = Vector2(0,10)
var text_space_y = Vector2(-45,0)

# axes scales
var x_scale = Vector3(1,0,0)
var x_scale_length = Vector3(0,0,0.5)
var number_on_x_one_side = floor((x_end.x - 0.2) / x_scale.x)
var z_scale = Vector3(0,0,1)
var z_scale_length = Vector3(0.5,0,0)
var number_on_z_one_side = floor((z_end.z - 0.2) / z_scale.z)



func _ready():

	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://Fonts/BebasNeue_Bold.ttf")
	dynamic_font.size = 18
	
	label_x.text = "X"
	label_z.text = "Z"
	label_negx.text = "-X"
	label_negz.text = "-Z"
	label_Pxz.text = "P(x,z)"
	label_x.add_color_override("font_color", Color(0.75,0.75,0.75,1))
	label_z.add_color_override("font_color", Color(0.75,0.75,0.75,1))
	label_negx.add_color_override("font_color", Color(0.75,0.75,0.75,1))
	label_negz.add_color_override("font_color", Color(0.75,0.75,0.75,1))
	label_Pxz.add_color_override("font_color", Color(0.75,0.75,0.75,1))
	label_x.add_font_override("font",dynamic_font)	
	label_z.add_font_override("font",dynamic_font)	
	label_negx.add_font_override("font",dynamic_font)	
	label_negz.add_font_override("font",dynamic_font)	
	label_Pxz.add_font_override("font",dynamic_font)	

	
func _process(_delta):
	x_end_projection_pos = camera.unproject_position(x_end)
	x_end_projection_neg = camera.unproject_position(-x_end)
	z_end_projection_pos = camera.unproject_position(z_end)
	z_end_projection_neg = camera.unproject_position(-z_end)
	y_end_projection = camera.unproject_position(y_end)
	origin_projection = camera.unproject_position(origin)
		
	label_x.set_global_position(x_end_projection_pos + text_space_xz)
	label_z.set_global_position(z_end_projection_pos + text_space_xz)
	label_negx.set_global_position(x_end_projection_neg + text_space_xz)
	label_negz.set_global_position(z_end_projection_neg + text_space_xz)
	label_Pxz.set_global_position(y_end_projection + text_space_y)	
	
	# add scale labels
	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://Fonts/BebasNeue_Bold.ttf")
	dynamic_font.size = 18
	
	for n in [number_on_x_one_side, -number_on_x_one_side]:
		if !get_node_or_null("Label_(" + str(n)+",0)"):
			var node = Label.new()
			node.name = "Label_(" + str(n)+",0)"
			add_child(node)	
		get_node("Label_(" + str(n)+",0)").set_global_position(camera.unproject_position(origin + x_scale*n) + text_space_xz)
		get_node("Label_(" + str(n)+",0)").text = str(n)
		get_node("Label_(" + str(n)+",0)").add_color_override("font_color", Color(0.75,0.75,0.75,1))	
		get_node("Label_(" + str(n)+",0)").add_font_override("font",dynamic_font)

	for n in [number_on_z_one_side, -number_on_z_one_side]:
		if !get_node_or_null("Label_(" + str(n)+",1)"):
			var node = Label.new()
			node.name = "Label_(" + str(n)+",1)"
			add_child(node)	
		get_node("Label_(" + str(n)+",1)").set_global_position(camera.unproject_position(origin + z_scale*n) + text_space_xz)
		get_node("Label_(" + str(n)+",1)").text = str(n)	
		get_node("Label_(" + str(n)+",1)").add_color_override("font_color", Color(0.75,0.75,0.75,1))
		get_node("Label_(" + str(n)+",1)").add_font_override("font",dynamic_font)
