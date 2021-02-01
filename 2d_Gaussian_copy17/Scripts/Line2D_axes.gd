extends Line2D

###################
#    PARAMS
###################

# axis
var	x_end = Vector3(5,0,0)
var	y_end = Vector3(0,4,0)
var	z_end = Vector3(0,0,5)
var origin = Vector3(0,0,0)

onready var camera = get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_camera/Viewport_camera/Camera")

# axes scales
var x_scale = Vector3(1,0,0)
var x_scale_length = Vector3(0,-0.3,0)
var number_on_x_one_side = floor((x_end.x - 0.2) / x_scale.x)
var z_scale = Vector3(0,0,1)
var z_scale_length = Vector3(0,-0.3,0)
var number_on_z_one_side = floor((z_end.z - 0.2) / z_scale.z)

##################################

func _draw():
	
	# drawing the axes on Canvas
	var origin_on_canvas = camera.unproject_position(origin)
		
	draw_line(origin_on_canvas, camera.unproject_position(y_end), Color(0.75,0.75,0.75,1),1.5,true)	
	draw_line(origin_on_canvas, camera.unproject_position(x_end), Color(0.75,0.75,0.75,1),1.5,true)
	draw_line(origin_on_canvas, camera.unproject_position(z_end), Color(0.75,0.75,0.75,1),1.5,true)
	draw_line(origin_on_canvas, camera.unproject_position(-x_end), Color(0.75,0.75,0.75,1),1.5,true)
	draw_line(origin_on_canvas, camera.unproject_position(-z_end), Color(0.75,0.75,0.75,1),1.5,true)
		
	draw_line(origin_on_canvas, camera.unproject_position(x_scale), Color(0.75,0.75,0.75,1),1.5,true)	
	draw_line(origin_on_canvas, camera.unproject_position(z_scale), Color(0.75,0.75,0.75,1),1.5,true)	
	draw_line(origin_on_canvas, camera.unproject_position(-x_scale),Color(0.75,0.75,0.75,1),1.5,true)
	draw_line(origin_on_canvas, camera.unproject_position(-z_scale),Color(0.75,0.75,0.75,1),1.5,true)		

	# redrawing the axes by each scale unit, antialiasing
	for i in range(0,number_on_x_one_side):
		draw_line(camera.unproject_position(x_scale*i),camera.unproject_position(x_scale*(i+1)),Color(0.75,0.75,0.75,1),1.5,true)
	for i in range(0,-number_on_x_one_side,-1):
		draw_line(camera.unproject_position(x_scale*i),camera.unproject_position(x_scale*(i-1)),Color(0.75,0.75,0.75,1),1.5,true)
	for i in range(0,number_on_z_one_side):
		draw_line(camera.unproject_position(z_scale*i),camera.unproject_position(z_scale*(i+1)),Color(0.75,0.75,0.75,1),1.5,true)
	for i in range(0,-number_on_z_one_side,-1):
		draw_line(camera.unproject_position(z_scale*i),camera.unproject_position(z_scale*(i-1)),Color(0.75,0.75,0.75,1),1.5,true)		

	# drawing the ticks
	var scale_start
	var scale_end
	for i in range(1,number_on_x_one_side+1):
		scale_start = camera.unproject_position(x_scale*i)
		scale_end = camera.unproject_position(x_scale*i + x_scale_length)
		draw_line(scale_start, scale_end, Color(0.75,0.75,0.75,1),1.5, true)
	for i in range(-1,-number_on_x_one_side-1,-1):
		scale_start = camera.unproject_position(x_scale*i)
		scale_end = camera.unproject_position(x_scale*i + x_scale_length)
		draw_line(scale_start, scale_end, Color(0.75,0.75,0.75,1),1.5, true)
	for i in range(1,number_on_z_one_side+1):
		scale_start = camera.unproject_position(z_scale*i)
		scale_end = camera.unproject_position(z_scale*i + z_scale_length)
		draw_line(scale_start, scale_end, Color(0.75,0.75,0.75,1),1.5, true)
	for i in range(-1,-number_on_z_one_side-1,-1):
		scale_start = camera.unproject_position(z_scale*i)
		scale_end = camera.unproject_position(z_scale*i + z_scale_length)
		draw_line(scale_start, scale_end, Color(0.75,0.75,0.75,1),1.5, true)

	# draw two markers for camera control region
	draw_line(Vector2(0,50),Vector2(5,50),ColorN("Black"),2.0,true)
	draw_line(Vector2(0,200),Vector2(5,200),ColorN("Black"),2.0,true)
	draw_line(Vector2(766,50),Vector2(761,50),ColorN("Black"),2.0,true)
	draw_line(Vector2(766,200),Vector2(761,200),ColorN("Black"),2.0,true)

func _process(_delta):
	update()
