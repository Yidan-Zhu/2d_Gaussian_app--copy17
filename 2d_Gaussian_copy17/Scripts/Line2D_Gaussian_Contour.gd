extends Line2D

########################
#     PARAMS
########################

# LAYOUT PARAMS
onready var script_parameter_axes = get_node("../..")

var origin = Vector3()

# key parameters
export var correlation_Gaussian = 0
export (float) var std_deviation_x = 0.5  # the real std deviation, half of width
export (float) var std_deviation_z = 0.5
export var mean_x = Vector3(0.5,0,0)
export var mean_z = Vector3(0,0,0.5)   # the value of real mean * scale
export (float) var a = 1
export (float) var b = 1

# drawing parameters
var ellipse_drawing_step = 500
var correction_point = 20
var ellipse_x_array = Array()
var ellipse_z_array = Array()

var anti_aliasing_transparent = 0.2
var anti_aliasing_linewidth = 1.7

var margin_right_viewport = get_viewport_rect().size.x
var list_parameters = [1.0,1.0,3]
export var contour_theta = 0

# shading and contour decoration
var mat = load("res://Shading/material_Gaussian.tres")
var shader_param = 20

# screen-world coordinate switch
var position10 = Vector2()
var position11 = Vector2()
var position20 = Vector2()
var position21 = Vector2()

onready var camera = get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_camera/Viewport_camera/Camera")
var intersection_plane = Plane(Vector3(0,1,0), 0)
var ray_length = 3000

var position_3d_1 = Vector3()
var position_3d_2 = Vector3()

# multi-input parameter
var events = {}

# one-input parameters
var location_mean_2d
var location_mean_3d

# drawing parameter
var drawing_type_flag = "mean_change"
var calculate_2d_origin
var finger_vector1
var finger_vector2
var covariance_matrix
var rotation_matrix
var middle_matrix = Transform2D()
var slope
var x_value_min
var y_value_min
var start
var delta

# animation control
onready var animation_signal_script = get_node("../../CanvasLayer_start_instruction/Line2D_drawAnimation")
var animation_signal = false

var time_array = Array()

#####################################

func _ready():
	origin = Vector3(mean_x.x, 0, mean_z.z)  # the drawing origin
	position_3d_1 = Vector3(std_deviation_x, 0,0)
	position_3d_2 = Vector3(0,0,std_deviation_z)
	
	# change the Gaussian scale_up param
	mat.set_shader_param("Gaussian_scale_up",shader_param)
	
func _process(_delta):
	# animation signal
	animation_signal = animation_signal_script.animation_finish
	
	# the origin of mesh
	origin = Vector3(mean_x.x, 0, mean_z.z)
	position_3d_1 = Vector3(a*cos(contour_theta),0,a*sin(contour_theta))
	position_3d_2 = Vector3(-b*sin(contour_theta),0,b*cos(contour_theta))

	mat.set_shader_param("variance_x", std_deviation_x)
	mat.set_shader_param("variance_z", std_deviation_z)
	mat.set_shader_param("mean_x", mean_x.x)
	mat.set_shader_param("mean_z", mean_z.z)
	mat.set_shader_param("correlation", correlation_Gaussian)

func _input(event):
	var x_limit = script_parameter_axes.x_end.x # a 3d value
	var z_limit = script_parameter_axes.z_end.z
# take the most recent two finger-touch inputs
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
		else:
			events.erase(event.index)
	
#	if event.position.x < margin_right_viewport:
	if event.position.x < 766 and event.position.y > 50 \
		and animation_signal:  # avoid having no intersecting point with (0,1,0) plane
		if event is InputEventScreenDrag:
			events[event.index] = event
			# one-finger mean change
			if events.size() == 1:
				#if events[0].position.y > 200:
				location_mean_2d = events[0].position
				
				var ray_from = camera.project_ray_origin(location_mean_2d)
				var ray_to = ray_from + camera.project_ray_normal(location_mean_2d)*ray_length
				location_mean_3d = intersection_plane.intersects_ray(ray_from, ray_to)					
				if typeof(location_mean_3d) != 0:  # is not null
					if location_mean_3d.x > -x_limit+2.5 and location_mean_3d.x < x_limit-2.5 and \
						location_mean_3d.z > -z_limit+2.5 and location_mean_3d.z < z_limit-2.5:
						mean_x.x = 1.0*location_mean_3d.x
						mean_z.z = 1.0*location_mean_3d.z 
						mat.set_shader_param("mean_x", mean_x.x)
						mat.set_shader_param("mean_z", mean_z.z)
				
						drawing_type_flag = "mean_change"
						update()
					
					else:
					# rotation the camera
						var current_height = get_tree().get_root().\
							find_node("Viewport_camera", true, false).get_node("Camera").camera_height
						if event.position.y < 200:  # not overlapping with the Gaussian plane
							var direction_angle = rad2deg(atan2(events[0].relative.x, \
								events[0].relative.y)) - 90   # atan2 returns an angle with (0,1) downwards
							# to the right
							if direction_angle <= 30 and direction_angle >= -30:
								get_tree().get_root().find_node("Viewport_camera", \
									true, false).get_node("Camera").camera_rotation += 10 
							# to the left
							elif direction_angle >= -210 and direction_angle <= -150:
								get_tree().get_root().find_node("Viewport_camera", \
									true, false).get_node("Camera").camera_rotation -= 10 
							# camera lower
							elif direction_angle >= -120 and direction_angle <= -60:
								if current_height - 0.5 > 3.0:
									get_tree().get_root().find_node("Viewport_camera", \
										true, false).get_node("Camera").camera_height -= 0.5
							# camera higher
							elif (direction_angle >= 60 and direction_angle <= 90) or \
								(direction_angle >= -270 and direction_angle <= -240):
								if current_height + 0.5 < 7.5:
									get_tree().get_root().find_node("Viewport_camera", \
										true, false).get_node("Camera").camera_height += 0.5																	
				
			# two-finger contour change	
			elif events.size() == 2:	
				position10 = events[0].position
				position20 = events[1].position
	
				ellipse_x_array.clear()
				ellipse_z_array.clear()
				# convert position1 and position2 to 3d space.
				var ray_from = camera.project_ray_origin(position10)
				var ray_to = ray_from + camera.project_ray_normal(position10)*ray_length
				position_3d_1 = intersection_plane.intersects_ray(ray_from, ray_to)			
			
				ray_from = camera.project_ray_origin(position20)
				ray_to = ray_from + camera.project_ray_normal(position20)*ray_length
				position_3d_2 = intersection_plane.intersects_ray(ray_from, ray_to)			
			
				if position_3d_1.x > -x_limit and position_3d_1.x < x_limit and position_3d_1.z > - z_limit and position_3d_1.z < z_limit \
				   and position_3d_2.x > -x_limit and position_3d_2.x < x_limit and position_3d_2.z > - z_limit and position_3d_2.z < z_limit:
					drawing_type_flag = "two-finger-input"
					update()
			
	update()   # when it is not one-finger/two-finger input
			   # for UI inputs

# use two finger-touch positions to draw
func _draw():
#	var time_start = OS.get_ticks_msec()
	
	calculate_2d_origin = Vector2(origin.x, origin.z)
			
	initialize_drawing_param(drawing_type_flag)	  # the a,b,start_vector,etc.					
	
	middle_matrix.x.x = pow(list_parameters[0],2) 
	middle_matrix.x.y = 0
	middle_matrix.y.x = 0
	middle_matrix.y.y = pow(list_parameters[1],2)

# three scenarios, index of finger as the main axis of ellipse
###################################################################
	if list_parameters[2] != 3: # non-circular
		var cos_rotation
		
		if list_parameters[2] == 1: 
		# calculate rotation matrix
			if finger_vector1.x < 0 and finger_vector1.y > 0:
				finger_vector1 = - finger_vector1
			if finger_vector1.x > 0 and finger_vector1.y > 0:
				finger_vector1 = - finger_vector1
			
			cos_rotation = finger_vector1.dot(Vector2(1,0)) / length_of_vector(finger_vector1)
			if drawing_type_flag == "slider_change_ab_theta" or drawing_type_flag ==  "slider_change_rho":
				cos_rotation = cos(contour_theta)  # the new theta in this frame

		elif list_parameters[2] == 2:
		# calculate rotation matrix
			if finger_vector2.x < 0 and finger_vector2.y > 0:
				finger_vector2 = - finger_vector2
			if finger_vector2.x > 0 and finger_vector2.y > 0:
				finger_vector2 = - finger_vector2
			
			cos_rotation = finger_vector2.dot(Vector2(1,0)) / length_of_vector(finger_vector2)
			if drawing_type_flag == "slider_change_ab_theta" or drawing_type_flag ==  "slider_change_rho":
				cos_rotation = cos(contour_theta)  # the new theta in this frame
	
# the following drawing is the same for non_circular situations.
		
		var matrix = calculate_covariance_matrix(cos_rotation)
		covariance_matrix = matrix[0]
		rotation_matrix = matrix[1]
		correlation_Gaussian = covariance_matrix.x.y  # haven't divided sigmas
		std_deviation_x = stepify(sqrt(covariance_matrix.x.x),0.01)
		std_deviation_z = stepify(sqrt(covariance_matrix.y.y),0.01)
		correlation_Gaussian = stepify(correlation_Gaussian/(std_deviation_x*std_deviation_z),0.01)

		mat.set_shader_param("variance_x", std_deviation_x)	
		mat.set_shader_param("variance_z", std_deviation_z)
		mat.set_shader_param("correlation", correlation_Gaussian)
		
		# use the above parameters to draw in another script...

######################################################################################3
			
	elif list_parameters[2] == 3:
		var pre_vector = Vector3(list_parameters[0],0,0)
		delta = 2*PI/(ellipse_drawing_step - 1)

	# find points behind Gaussian
		var identifier = find_points_behind_Gaussian(pre_vector,delta,"circular")
		slope = identifier[0]
		x_value_min = identifier[1]
		y_value_min = identifier[2]

		# draw the contour
		# calculate the number of contours to draw on the Gaussian
		var contour_space_index = 0.5
		var each_contour_height
		var number_of_contour = 0
		var height = calculate_Gaussian_probability(origin.x + contour_space_index*list_parameters[0], origin.z, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z)
		while height > 0.5:
			number_of_contour += 1
			height = calculate_Gaussian_probability(origin.x + contour_space_index*(number_of_contour+1)*list_parameters[0], origin.z, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z)
		var contour_back_bending_index = 6

		for n in range(0, ellipse_drawing_step+correction_point):
			var theta = 0 + n*delta
			var draw1 = camera.unproject_position(origin + Vector3(list_parameters[0] * cos(theta), 0, list_parameters[0] * sin(theta)))
			var draw2 = camera.unproject_position(origin + pre_vector)
			if !is_nan(draw1.x) && !is_nan(draw2.x):
				var reference_y_1 = reference_y_value(slope, draw1.x, x_value_min, y_value_min)
				var reference_y_2 = reference_y_value(slope, draw2.x, x_value_min, y_value_min)
				if draw2.y >= reference_y_2 && draw1.y-contour_back_bending_index >= reference_y_1-contour_back_bending_index:		
					# draw the other contours
					for m in range(1,number_of_contour+1):
						each_contour_height = calculate_Gaussian_probability(origin.x + contour_space_index*m*list_parameters[0], origin.z, correlation_Gaussian, std_deviation_x, std_deviation_z, mean_x.x, mean_z.z)
						if number_of_contour < 2:
							if get_node_or_null("Label_a"):							
								get_node("Label_a").queue_free()
								get_node("Label_b").queue_free() # delete labels when contour is out of range
						if m!=2:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(0,0.635,0.91,1), 1.5, true)
							draw_line(camera.unproject_position(origin+Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(0,0.635,0.91,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
						else:
							draw_line(camera.unproject_position(origin + Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(1,0.39,0,1), 1.5, true)
							draw_line(camera.unproject_position(origin+Vector3(contour_space_index*m*list_parameters[0] * cos(theta), each_contour_height, contour_space_index*m*list_parameters[0] * sin(theta))), \
								camera.unproject_position(origin + contour_space_index*m*pre_vector+Vector3(0,each_contour_height,0)), Color(1,0.39,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)									
							# draw axes markers on the 1-dev-contour
							draw_line(camera.unproject_position(origin+ 0.9*position_3d_1 + Vector3(0,each_contour_height,0)), camera.unproject_position(origin -0.9*position_3d_1+ Vector3(0,each_contour_height,0)), Color(0.91,0.73,0.75,1), 1.5, true)			
							draw_line(camera.unproject_position(origin+ 0.9*position_3d_2 + Vector3(0,each_contour_height,0)), camera.unproject_position(origin -0.9*position_3d_2+ Vector3(0,each_contour_height,0)), Color(0.91,0.73,0.75,1), 1.5, true)
#							if !get_node_or_null("Label_a"):
#								var node = Label.new()
#								node.name = "Label_a"
#								add_child(node)	
#							get_node("Label_a").set_global_position(camera.unproject_position(origin + 1.2*position_3d_1 + Vector3(0,each_contour_height+0.5,0)))
#							get_node("Label_a").text = "2a"
#							get_node("Label_a").add_color_override("font_color", Color(0.91,0.73,0.75,1))	
#
#							if !get_node_or_null("Label_b"):
#								var node = Label.new()
#								node.name = "Label_b"
#								add_child(node)	
#							get_node("Label_b").set_global_position(camera.unproject_position(origin + 1.2*position_3d_2 + Vector3(0,each_contour_height+0.5,0)))
#							get_node("Label_b").text = "2b"
#							get_node("Label_b").add_color_override("font_color", Color(0.91,0.73,0.75,1))
#
#							var dynamic_font = DynamicFont.new()
#							dynamic_font.font_data = load("res://Fonts/BebasNeue_Bold.ttf")
#							dynamic_font.size = 18
#							get_node("Label_a").add_font_override("font",dynamic_font)
#							get_node("Label_b").add_font_override("font",dynamic_font)
#
			pre_vector = Vector3(list_parameters[0] * cos(theta),0, list_parameters[0]*sin(theta))

		correlation_Gaussian = 0
		std_deviation_x = stepify(list_parameters[0],0.01)   # full width=2sigma
		std_deviation_z = std_deviation_x

		mat.set_shader_param("variance_x", std_deviation_x)	
		mat.set_shader_param("variance_z", std_deviation_z)
		mat.set_shader_param("correlation", correlation_Gaussian)

#	var time_end = OS.get_ticks_msec()
#	if animation_signal and time_array.size() < 100:
#		time_array.append(time_end-time_start)
#		print(str(time_array.size())+": "+str(time_end-time_start))

###############################################################################################

# function to get the length of a vector
func length_of_vector(vector):
	var length = sqrt(pow(vector.x,2)+pow(vector.y,2))
	return length
	
# calculate b of an ellipse, and the main axis index
func calculate_ab_of_ellipse(finger_vector1, finger_vector2):
	var dist1 = length_of_vector(finger_vector1)
	var dist2 = length_of_vector(finger_vector2)
	var cos_angle = finger_vector1.dot(finger_vector2) / (dist1 * dist2)
	var sin_angle = sqrt(1 - pow(cos_angle,2))
	if dist1 > dist2 and abs(dist1-dist2) > 0.2:
		var a_value = dist1
		var main_axis_index = 1
		
		var new_x = dist2 * cos_angle
		var new_y = dist2 * sin_angle
		
		var b_value = sqrt(pow(new_y,2) / (1 - pow(new_x,2)/pow(a,2)))
		
		return [stepify(a_value,0.01),stepify(b_value,0.01),main_axis_index] # 1 for finger 1 as longer axis
		
	elif dist1 < dist2 and abs(dist1-dist2) > 0.2:
		var a_value = dist2
		var main_axis_index = 2
		
		var new_x = dist1 * cos_angle
		var new_y = dist1 * sin_angle
		
		var b_value = sqrt(pow(new_y,2) / (1 - pow(new_x,2)/pow(a,2)))
		
		return [stepify(a_value,0.01),stepify(b_value,0.01),main_axis_index] # 2 for finger 2 as longer axis

	else: 
		return [stepify(dist1,0.01), stepify(dist1,0.01), 3]   # 3 for a circle

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


# calculate a,b,theta from Sigma matrix
func calculate_ab_theta_from_sigma(correlation, deviation_x, deviation_z):
	var sigma_xx = deviation_x*deviation_x
	var sigma_zz = deviation_z*deviation_z
	var sigma_xz = correlation*deviation_x*deviation_z
	var lambda_1 = ((sigma_xx+sigma_zz)+sqrt((sigma_xx+sigma_zz)*(sigma_xx+sigma_zz) - 4*(sigma_xx*sigma_zz - sigma_xz*sigma_xz)))/2
	var lambda_2 = ((sigma_xx+sigma_zz)-sqrt((sigma_xx+sigma_zz)*(sigma_xx+sigma_zz) - 4*(sigma_xx*sigma_zz - sigma_xz*sigma_xz)))/2
	var eigen_vec1 = Vector2(sigma_xz, lambda_1 - sigma_xx).normalized()
	#var eigen_vec2 = Vector2(sigma_xz, lambda_2 - sigma_xx).normalized()   # these two vectors are orthogonal

	var theta_counterclockwise = atan2(eigen_vec1.x, eigen_vec1.y)
	return [stepify(sqrt(lambda_1),0.01), stepify(sqrt(lambda_2),0.01), stepify(theta_counterclockwise,0.01)]   # return a, b, theta
		
##################################################

func initialize_drawing_param(input_mode):
	# draw the contour by two finger-inputs
	if drawing_type_flag == "two-finger-input":
		# position_3d_1 and 2 are finger positions in the world
		finger_vector1 = Vector2(position_3d_1.x, position_3d_1.z) - calculate_2d_origin 
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z) - calculate_2d_origin
		list_parameters = calculate_ab_of_ellipse(finger_vector1, finger_vector2)
		a = list_parameters[0]
		b = list_parameters[1]
		draw_circle(camera.unproject_position(position_3d_1), 5.0, ColorN("Yellow"))
		draw_circle(camera.unproject_position(position_3d_2), 5.0, ColorN("Yellow"))
		
	# draw the contour by the mean value and std deviations
	elif drawing_type_flag == "mean_change":
		# position_3d_1 and 2 are calculatd from a,b,theta, from (0,0,0)
		finger_vector1 = Vector2(position_3d_1.x,position_3d_1.z)
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z)
		list_parameters[0] = a
		list_parameters[1] = b
		# set the main axis
		if list_parameters[0] > list_parameters[1]:
			list_parameters[2] = 1
		elif list_parameters[0] < list_parameters[1]:
			list_parameters[2] = 2
			var temp = list_parameters[0]
			list_parameters[0] = list_parameters[1]
			list_parameters[1] = temp
		else:
			list_parameters[2] = 3
			
		a = list_parameters[0]
		b = list_parameters[1]
		
	elif drawing_type_flag == "slider_change_ab_theta":
		# new a,b
		# two-finger param is out of range, will not have a strong pull
		if a > 2 and get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().x < 0 :
			a += get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().x * 0.1
		elif a < 1 and 	get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().x > 0 :
			a += get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().x * 0.1						
		# two-finger param in in range
		elif a <= 2 and a >= 1:
			if (a+get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().x * 0.1 < 2 and \
				a+get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().x * 0.1 > 1):
				a += get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().x * 0.1
		# the same for b
		if b > 2 and get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().y > 0 :
			b -= get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().y * 0.1
		elif b < 1 and 	get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().y < 0 :
			b -= get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().y * 0.1						
		# two-finger param in in range
		elif b <= 2 and b >= 1:
			if (b-get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().y * 0.1 < 2 and \
				b-get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().y * 0.1 > 1):
				b -= get_tree().get_root().find_node("TouchScreenButton_ab",true,false).get_value().y * 0.1

		# position_3d_1 and 2 are calculatd from a,b,theta, from(0,0,0)
		finger_vector1 = Vector2(position_3d_1.x, position_3d_1.z)
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z)
		list_parameters[0] = a
		list_parameters[1] = b
		#contour_theta = get_tree().get_root().find_node("VSlider_theta", true, false).value # counter-clockwise, in rad
		# set the main axis
		if list_parameters[0] > list_parameters[1]:
			list_parameters[2] = 1
		elif list_parameters[0] < list_parameters[1]:
			list_parameters[2] = 2
			var temp = list_parameters[0]
			list_parameters[0] = list_parameters[1]
			list_parameters[1] = temp
		else:
			list_parameters[2] = 3

		a = list_parameters[0]
		b = list_parameters[1]
		
	elif drawing_type_flag ==  "slider_change_rho":
		var left_matrix = calculate_ab_theta_from_sigma(correlation_Gaussian,std_deviation_x, std_deviation_z)
		a = left_matrix[0]
		b = left_matrix[1]
		contour_theta = left_matrix[2]    # theta value from -pi to pi
		list_parameters[0] = a
		list_parameters[1] = b
		list_parameters[2] = 1  # a is always >= b in eigens	

		position_3d_1 = Vector3(a*cos(contour_theta),0,a*sin(contour_theta))  
		position_3d_2 = Vector3(-b*sin(contour_theta),0,b*cos(contour_theta))  # recalculate in this frame from new a,b,theta	
		finger_vector1 = Vector2(position_3d_1.x, position_3d_1.z)
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z)		
		
	elif drawing_type_flag ==  "slider_change_deviations":
		# update deviations 
		# two-finger gesture param is out of range
		if std_deviation_x > 2 and get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().x < 0:
			std_deviation_x += get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().x * 0.3	
		elif std_deviation_x < 0.5 and get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().x > 0:
			std_deviation_x += get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().x * 0.3	
		# two-finger gesture param is not out of range
		elif std_deviation_x <= 2 and std_deviation_x >= 0.5:
			if (std_deviation_x + get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().x * 0.3 < 2 and \
		 		  std_deviation_x + get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().x * 0.3 > 0.5):
				std_deviation_x += get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().x * 0.3
		# the same for z
		if std_deviation_z > 2 and get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().y > 0:
			std_deviation_z -= get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().y * 0.3	
		elif std_deviation_z < 0.5 and get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().y < 0:
			std_deviation_z -= get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().y * 0.3	
		elif std_deviation_z <= 2 and std_deviation_z >= 0.5:		
			if (std_deviation_z - get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().y * 0.3 < 2 and \
			   std_deviation_z - get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().y * 0.3 > 0.5):
				std_deviation_z -= get_tree().get_root().find_node("TouchScreenButton_deviations",true,false).get_value().y * 0.3

		var left_matrix = calculate_ab_theta_from_sigma(correlation_Gaussian,std_deviation_x, std_deviation_z)
		
		a = left_matrix[0]
		b = left_matrix[1]
		contour_theta = left_matrix[2]    # theta value from -pi to pi
		list_parameters[0] = a
		list_parameters[1] = b
		# set the main axis, a >= b in eigens
		list_parameters[2] = 1	

		position_3d_1 = Vector3(a*cos(contour_theta),0,a*sin(contour_theta))  
		position_3d_2 = Vector3(-b*sin(contour_theta),0,b*cos(contour_theta))  # recalculate in this frame from new a,b,theta	
		finger_vector1 = Vector2(position_3d_1.x, position_3d_1.z)
		finger_vector2 = Vector2(position_3d_2.x, position_3d_2.z)	

###############
func calculate_covariance_matrix(cosine):
	var sin_rotation = sqrt(1-cosine*cosine)
	var rotation_mtx = Transform2D()
	rotation_mtx.x.x = cosine
	rotation_mtx.x.y = -sin_rotation
	rotation_mtx.y.x = sin_rotation
	rotation_mtx.y.y = cosine
		
	# calculate the transpose = inverse of rotation matrix
	var rotation_matrix_inverse = rotation_mtx
	rotation_matrix_inverse.x.y = rotation_mtx.y.x
	rotation_matrix_inverse.y.x = rotation_mtx.x.y		
	# calculate covariance matrix
	var covariance_mtx = rotation_mtx * middle_matrix * \
		rotation_matrix_inverse	
	
	return [covariance_mtx,rotation_mtx]


# find points behind Gaussian
func find_points_behind_Gaussian(start,delta, mode):
	var canvas_contour_bottom = PoolVector2Array()
#	if mode == "non_circular":
#		var ellipse_x_pre = start.x
#		var ellipse_z1_pre = start.y
#		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z1_pre)))
#		for n in range(1, ellipse_drawing_step+correction_point):
#			var ellipse_x_next = -list_parameters[0] + delta*n
#			var ellipse_z1_next = sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
#			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z1_next)
#			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
#			ellipse_x_pre = rotated_points.x
#			ellipse_z1_pre = rotated_points.y
#
#		ellipse_x_pre = start.x
#		var ellipse_z2_pre = start.y
#		canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(ellipse_x_pre, 0, ellipse_z2_pre)))
#
#		for n in range(1, ellipse_drawing_step+correction_point):
#			var ellipse_x_next = -list_parameters[0] + delta*n
#			var ellipse_z2_next = -sqrt((1 - ellipse_x_next*ellipse_x_next / pow(list_parameters[0],2))*pow(list_parameters[1],2))
#			var rotated_points = rotation_matrix * Vector2(ellipse_x_next,ellipse_z2_next)
#			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(rotated_points.x, 0, rotated_points.y)))
#			ellipse_x_pre = rotated_points.x
#			ellipse_z2_pre = rotated_points.y

	if mode == "circular":
		canvas_contour_bottom.append(camera.unproject_position(origin + start))
				
		for n in range(1, ellipse_drawing_step+correction_point):
			var theta = 0 + n*delta
			canvas_contour_bottom.append(camera.unproject_position(origin + Vector3(list_parameters[0] * cos(theta), 0, list_parameters[0] * sin(theta))))


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
