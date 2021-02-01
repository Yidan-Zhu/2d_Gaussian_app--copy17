extends Line2D

onready var param_node = get_node("../Line2D_Gaussian_Contour")
var list_parameters
var start
var rotation_matrix
var origin
var mean_x
var mean_z
var correlation_Gaussian
var std_deviation_x
var std_deviation_z
var ellipse_drawing_step = 500
var correction_point = 20
var mat = load("res://Shading/material_Gaussian.tres")
var delta
onready var camera = get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_camera/Viewport_camera/Camera")
var slope
var x_value_min
var y_value_min
var anti_aliasing_transparent = 0.2
var anti_aliasing_linewidth = 1.7
var position_3d_1
var position_3d_2
var shader_param = 20

var contour_space_index = 0.5
var each_contour_height
var number_of_contour = 0
var ellipse_x_next
var ellipse_z1_next
var ellipse_z2_next
var rotated_points
var draw1
var draw2
var reference_y_1
var reference_y_2
var time_array = Array()

var old_list_parameters
var old_rotation_matrix
var old_origin
var old_std_deviation_x
var old_std_deviation_z
var old_correlation_Gaussian

var camera_rotation
var old_camera_rotation
var camera_height
var old_camera_height

##############################

func _ready():
	list_parameters = param_node.list_parameters
	rotation_matrix = param_node.rotation_matrix
	mean_x = param_node.mean_x
	mean_z = param_node.mean_z
	origin = Vector3(mean_x.x, 0, mean_z.z)
	correlation_Gaussian = param_node.correlation_Gaussian
	std_deviation_x = param_node.std_deviation_x
	std_deviation_z = param_node.std_deviation_z
	position_3d_1 = param_node.position_3d_1
	position_3d_2 = param_node.position_3d_2
	camera_rotation = camera.camera_rotation
	camera_height = camera.camera_height
	
	old_list_parameters = list_parameters
	old_rotation_matrix = rotation_matrix
	old_origin = origin
	old_std_deviation_x = std_deviation_x
	old_std_deviation_z = std_deviation_z
	old_correlation_Gaussian = correlation_Gaussian
	old_camera_rotation = camera_rotation
	old_camera_height = camera_height

func _process(delta):
	list_parameters = param_node.list_parameters
	rotation_matrix = param_node.rotation_matrix
	mean_x = param_node.mean_x
	mean_z = param_node.mean_z
	origin = Vector3(mean_x.x, 0, mean_z.z)	
	correlation_Gaussian = param_node.correlation_Gaussian
	std_deviation_x = param_node.std_deviation_x
	std_deviation_z = param_node.std_deviation_z
	position_3d_1 = param_node.position_3d_1
	position_3d_2 = param_node.position_3d_2
	camera_rotation = camera.camera_rotation
	camera_height = camera.camera_height

	if old_list_parameters != list_parameters:
		update()
		old_list_parameters = list_parameters
	
	if old_rotation_matrix != rotation_matrix:
		update()
		old_rotation_matrix = rotation_matrix
	
	if old_origin != origin:
		update()
		old_origin = origin
	
	if old_std_deviation_x != std_deviation_x:
		update()
		old_std_deviation_x = std_deviation_x
	
	if old_std_deviation_z != std_deviation_z:
		update()
		old_std_deviation_z = std_deviation_z
	
	if old_correlation_Gaussian != correlation_Gaussian:
		update()
		old_correlation_Gaussian = correlation_Gaussian

	if camera_rotation != old_camera_rotation:
		update()
		old_camera_rotation = camera_rotation
		
	if old_camera_height != camera_height:
		update()
		old_camera_height = camera_height

func _draw():
	draw_circle(camera.unproject_position(Vector3(origin.x,calculate_Gaussian_probability(origin.x, origin.z, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z),origin.z)),\
		2.0, ColorN("Yellow"))
			
	if list_parameters[2] == 1 or list_parameters[2] == 2:
		# find points behind Gaussian
		start = rotation_matrix * Vector2(-abs(list_parameters[0]),0)
		delta = abs(2*list_parameters[0]) / (ellipse_drawing_step-1)
		var identifier = find_points_behind_Gaussian(start,delta,"non_circular")
		slope = identifier[0]
		x_value_min = identifier[1]
		y_value_min = identifier[2]
		
		# draw contour
		start = rotation_matrix * Vector2(-abs(list_parameters[0]),0)
		var ellipse_x_pre = start.x
		var ellipse_z1_pre = start.y

		# calculate the number of contours to draw on the Gaussian
		number_of_contour=0
		var height = calculate_Gaussian_probability(origin.x + contour_space_index*ellipse_x_pre, origin.z + contour_space_index*ellipse_z1_pre, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z)
		while height > 0.5:
			number_of_contour += 1
			height = calculate_Gaussian_probability(origin.x + contour_space_index*(number_of_contour+1)*ellipse_x_pre, origin.z + contour_space_index*(number_of_contour+1)*ellipse_z1_pre, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z)
		var contour_back_bending_index = 6
														
		for n in range(1, ellipse_drawing_step+correction_point):
			ellipse_x_next = -list_parameters[0] + delta*n
			ellipse_z1_next = sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z1_next)
			draw1 = camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z1_pre)) 
			draw2 = camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y))
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2 - contour_back_bending_index && draw1.y >= reference_y_1 - contour_back_bending_index:
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*ellipse_x_pre, origin.z + contour_space_index*m*ellipse_z1_pre, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z)
						if number_of_contour < 2:
							if get_node_or_null("Label_a"):							
								get_node("Label_a").queue_free()
								get_node("Label_b").queue_free() # delete labels when contour is out of range
						if m!=2:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0,0.635,0.91,1), 1.5, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0,0.635,0.91,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0.39,0,1), 1.5, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z1_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0.39,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)								
							# draw axes markers on the 1-dev-contour
							draw_line(camera.unproject_position(origin+ 0.9*position_3d_1 + Vector3(0,each_contour_height,0)), camera.unproject_position(origin -0.9*position_3d_1+ Vector3(0,each_contour_height,0)), Color(0.91,0.73,0.75,1), 1.5, true)			
							draw_line(camera.unproject_position(origin+ 0.9*position_3d_2 + Vector3(0,each_contour_height,0)), camera.unproject_position(origin -0.9*position_3d_2+ Vector3(0,each_contour_height,0)), Color(0.91,0.73,0.75,1), 1.5, true)

							if !get_node_or_null("Label_a"):
								var node = Label.new()
								node.name = "Label_a"
								add_child(node)	
							get_node("Label_a").set_global_position(camera.unproject_position(origin + 1.2*position_3d_1 + Vector3(0,each_contour_height+0.5,0)))
							get_node("Label_a").text = "2a"
							get_node("Label_a").add_color_override("font_color", Color(0.91,0.73,0.75,1))						
							if !get_node_or_null("Label_b"):
								var node = Label.new()
								node.name = "Label_b"
								add_child(node)	
							get_node("Label_b").set_global_position(camera.unproject_position(origin + 1.2*position_3d_2 + Vector3(0,each_contour_height+0.5,0)))
							get_node("Label_b").text = "2b"
							get_node("Label_b").add_color_override("font_color", Color(0.91,0.73,0.75,1))

							var dynamic_font = DynamicFont.new()
							dynamic_font.font_data = load("res://Fonts/BebasNeue_Bold.ttf")
							dynamic_font.size = 18
							get_node("Label_a").add_font_override("font",dynamic_font)
							get_node("Label_b").add_font_override("font",dynamic_font)
									
			ellipse_x_pre = rotated_points.x
			ellipse_z1_pre = rotated_points.y

# draw another half contour	
#		var time_start = OS.get_ticks_msec()
		
		ellipse_x_pre = start.x
		var ellipse_z2_pre = start.y

		for n in range(1, ellipse_drawing_step+correction_point):
			ellipse_x_next = -list_parameters[0] + delta*n
			ellipse_z2_next = -sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z2_next)
			draw1 = camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z2_pre))
			draw2 = camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y))
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2-contour_back_bending_index && draw1.y >= reference_y_1-contour_back_bending_index:
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*ellipse_x_pre, origin.z + contour_space_index*m*ellipse_z2_pre, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z)
						if number_of_contour < 2:
							if get_node_or_null("Label_a"):							
								get_node("Label_a").queue_free()
								get_node("Label_b").queue_free() # delete labels when contour is out of range
						if m!=2:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0,0.635,0.91,1), 1.5, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(0,0.635,0.91,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0.39,0,1), 1.5, true)
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*ellipse_x_pre, each_contour_height, contour_space_index*m*ellipse_z2_pre)), \
								camera.unproject_position(origin + Vector3(contour_space_index*m*rotated_points.x, each_contour_height, contour_space_index*m*rotated_points.y)), Color(1,0.39,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)										
							# draw axes markers on the 1-dev-contour
							draw_line(camera.unproject_position(origin+ 0.9*position_3d_1 + Vector3(0,each_contour_height,0)), camera.unproject_position(origin -0.9*position_3d_1+ Vector3(0,each_contour_height,0)), Color(0.91,0.73,0.75,1), 1.5, true)			
							draw_line(camera.unproject_position(origin+ 0.9*position_3d_2 + Vector3(0,each_contour_height,0)), camera.unproject_position(origin -0.9*position_3d_2+ Vector3(0,each_contour_height,0)), Color(0.91,0.73,0.75,1), 1.5, true)							
							if !get_node_or_null("Label_a"):
								var node = Label.new()
								node.name = "Label_a"
								add_child(node)	
							get_node("Label_a").set_global_position(camera.unproject_position(origin + 1.2*position_3d_1 + Vector3(0,each_contour_height+0.5,0)))
							get_node("Label_a").text = "2a"
							get_node("Label_a").add_color_override("font_color", Color(0.91,0.73,0.75,1))	

							if !get_node_or_null("Label_b"):
								var node = Label.new()
								node.name = "Label_b"
								add_child(node)	
							get_node("Label_b").set_global_position(camera.unproject_position(origin + 1.2*position_3d_2 + Vector3(0,each_contour_height+0.5,0)))
							get_node("Label_b").text = "2b"
							get_node("Label_b").add_color_override("font_color", Color(0.91,0.73,0.75,1))

							var dynamic_font = DynamicFont.new()
							dynamic_font.font_data = load("res://Fonts/BebasNeue_Bold.ttf")
							dynamic_font.size = 18
							get_node("Label_a").add_font_override("font",dynamic_font)
							get_node("Label_b").add_font_override("font",dynamic_font)

			ellipse_x_pre = rotated_points.x
			ellipse_z2_pre = rotated_points.y

#		var time_end = OS.get_ticks_msec()
#		if time_array.size() < 1000:
#			time_array.append(time_end-time_start)
#			print(str(time_array.size())+": "+str(time_end-time_start))

########################################################
func calculate_Gaussian_probability(x, z, correlation, deviation_x, deviation_z, center_x, center_z):
	var coefficient = 1.0/(2*PI*deviation_x*deviation_z*sqrt(1-correlation*correlation))
	var power_index_coefficient = -1.0/(2*(1-correlation*correlation))
	var power_index_main = pow(x-center_x,2.0)/pow(deviation_x,2.0) - \
						   2.0*correlation*(x-center_x)*(z-center_z)/(deviation_x*deviation_z) + \
						   pow(z-center_z,2.0)/pow(deviation_z,2.0)
	var probability_density = coefficient*exp(power_index_coefficient*power_index_main)
	return probability_density*shader_param

func reference_y_value(slope, x, x_value_min, y_value_min):
	return slope * (x - x_value_min) + y_value_min

func find_points_behind_Gaussian(start,delta, mode):
	var canvas_contour_bottom = PoolVector2Array()
	if mode == "non_circular":
		var ellipse_x_pre = start.x
		var ellipse_z1_pre = start.y
		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z1_pre)))
		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z1_next = sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z1_next)
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
			ellipse_x_pre = rotated_points.x
			ellipse_z1_pre = rotated_points.y
	
		ellipse_x_pre = start.x
		var ellipse_z2_pre = start.y
		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z2_pre)))
	
		for n in range(1, ellipse_drawing_step+correction_point):
			var ellipse_x_next = -list_parameters[0] + delta*n
			var ellipse_z2_next = -sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z2_next)
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
			ellipse_x_pre = rotated_points.x
			ellipse_z2_pre = rotated_points.y

#	elif mode == "circular":
#		canvas_contour_bottom.append(camera.unproject_position(origin + start))
#
#		for n in range(1, ellipse_drawing_step+correction_point):
#			var theta = 0 + n*delta
#			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(list_parameters[0] * cos(theta), 0, list_parameters[0] * sin(theta))))


	var x_value_min = canvas_contour_bottom[0].x
	var x_value_max = canvas_contour_bottom[0].x
	var y_value_min = canvas_contour_bottom[0].y
	var y_value_max = canvas_contour_bottom[0].y
	for j in range(canvas_contour_bottom.size()-1):
		if !is_nan(canvas_contour_bottom[j+1].x):
			if canvas_contour_bottom[j+1].x < x_value_min:
				x_value_min = canvas_contour_bottom[j+1].x
				y_value_min = canvas_contour_bottom[j+1].y
		if !is_nan(canvas_contour_bottom[j+1].x):
			if canvas_contour_bottom[j+1].x > x_value_max:
				x_value_max = canvas_contour_bottom[j+1].x
				y_value_max = canvas_contour_bottom[j+1].y
	var slope = (y_value_max - y_value_min) / (x_value_max - x_value_min)
	
	return [slope, x_value_min, y_value_min]
