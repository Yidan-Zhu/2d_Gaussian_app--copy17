extends Line2D

####################
#      PARAMS
####################

export var animation_finish = false

# projection
onready var script_parameter_axes = get_node("../..")
onready var camera = get_node("/root/Spatial_SplitScreen/HBoxContainer/ViewportContainer_camera/Viewport_camera/Camera")
var animation_count = 0

# instruction parameters
var x_limit
var z_limit
var illustration_region_color = Color(0.169,0.91,0.38,0.25)

###########################################

func _ready():
	x_limit = script_parameter_axes.x_end # a 3d value
	z_limit = script_parameter_axes.z_end

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			animation_count += 1
			update()

func _draw():
	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://Fonts/BebasNeue_Bold.ttf")
	dynamic_font.size = 18

	if animation_count < 6:
		# add a button to skip animation
		if !get_node_or_null("button"):
			var node_button = Button.new()
			node_button.name = "button"
			add_child(node_button)		
		get_node("button").set_global_position(Vector2(100,50))
		get_node("button").text = "Skip Instruction"
		if (get_node("button").is_pressed()):
			animation_count = 6
			get_node("button").queue_free()
			# delete
			if get_node_or_null("Instruction_one"):
				get_node("Instruction_one").queue_free()
				get_node("example_sprite1").queue_free()	
			if get_node_or_null("Instruction_two"):
				get_node("Instruction_two").queue_free()
				get_node("example_sprite2").queue_free()
			if get_node_or_null("Instruction_three"):
				get_node("Instruction_three").queue_free()
				get_node("example_sprite3").queue_free()
			if get_node_or_null("Instruction_four"):
				get_node("Instruction_four").queue_free()
				get_node("example_sprite4").queue_free()	
			if get_node_or_null("Instruction_five"):
				get_node("Instruction_five").queue_free()
				get_node("example_sprite5").queue_free()
															
		# animation part
		if animation_count == 0:
		# instruction one - one-finger mean gesture
		# the function region
			var pointxz_rec = camera.unproject_position(x_limit+z_limit)	
			var pointx_negz_rec = camera.unproject_position(x_limit-z_limit)	
			var pointnegx_z_rec = camera.unproject_position(-x_limit+z_limit)	
			var pointnegx_negz_rec = camera.unproject_position(-x_limit-z_limit)	

			draw_polygon(PoolVector2Array([pointxz_rec, pointx_negz_rec, \
				pointnegx_negz_rec, pointnegx_z_rec]), \
				PoolColorArray([illustration_region_color]))

		# an example trace
			var start_drag = camera.unproject_position(Vector3(0,0,1))
			var end_drag = camera.unproject_position(Vector3(-3.5,0,-2))
			draw_line(start_drag, end_drag, Color(0.937,0.149,0.945,1.0),2.0,true)
			draw_triangle(end_drag,end_drag-start_drag,7,Color(0.937,0.149,0.945,1.0))
	
			var num_example = 5
			for n in range(num_example):
				draw_circle(start_drag+(end_drag-start_drag)*n/num_example,3.0,ColorN("Yellow"))
	
		# add instruction text and picture
			if !get_node_or_null("Instruction_one"):
				var node = Label.new()
				node.name = "Instruction_one"
				add_child(node)	
			get_node("Instruction_one").set_global_position(camera.unproject_position(Vector3(1,0,-2.7))+\
				Vector2(30,110))
			get_node("Instruction_one").text = "Drag in the region to change \nthe center of Gaussian"
			get_node("Instruction_one").add_color_override("font_color", Color(0,0,0,1))	
			get_node("Instruction_one").add_font_override("font",dynamic_font)
		
			if !get_node_or_null("example_sprite1"):
				var node2 = Sprite.new()
				node2.name = "example_sprite1"
				add_child(node2)
			get_node("example_sprite1").set_global_position(camera.unproject_position(Vector3(-2.1,0,-2.1)))
			get_node("example_sprite1").texture = load("res://Sprites/finger_swipe_1.png")
			get_node("example_sprite1").rotation_degrees = 70
			get_node("example_sprite1").set_scale(Vector2(0.5,0.5))
		
		elif animation_count == 1 or animation_count == 2 or \
			animation_count == 3 or animation_count == 4:
			draw_rect(Rect2(0, 50, 766, 150),illustration_region_color,true)		

			if animation_count == 1:
			# delete the pre instruction nodes
				if get_node_or_null("Instruction_one"):
					get_node("Instruction_one").queue_free()
					get_node("example_sprite1").queue_free()
			# instruction two.1 - one-finger camera left gesture
				var start_drag_2 = Vector2(550,150)
				var end_drag_2_left = Vector2(650,150)
				draw_line(start_drag_2, end_drag_2_left,Color(0.937,0.149,0.945,1.0),2.0,true)
				draw_triangle(end_drag_2_left,end_drag_2_left-start_drag_2,7,Color(0.937,0.149,0.945,1.0))

				if !get_node_or_null("example_sprite2"):
					var node3 = Sprite.new()
					node3.name = "example_sprite2"
					add_child(node3)
				get_node("example_sprite2").set_global_position(Vector2(600,210))
				get_node("example_sprite2").texture = load("res://Sprites/finger_swipe_1.png")
				get_node("example_sprite2").rotation_degrees = 0
				get_node("example_sprite2").set_scale(Vector2(0.5,0.5))	
			
				if !get_node_or_null("Instruction_two"):
					var node4 = Label.new()
					node4.name = "Instruction_two"
					add_child(node4)	
				get_node("Instruction_two").set_global_position(Vector2(490,105))
				get_node("Instruction_two").text = "Swipe to left, to rotate \nthe camera counterclockwisely"
				get_node("Instruction_two").add_color_override("font_color", Color(0,0,0,1))					
				get_node("Instruction_two").add_font_override("font",dynamic_font)	
	
			elif animation_count == 2:
			# delete the pre instruction nodes
				if get_node_or_null("Instruction_two"):
					get_node("Instruction_two").queue_free()
					get_node("example_sprite2").queue_free()		
			# instruction two.2 - one-finger camera right gesture			
				var start_drag_3 = Vector2(650,150)
				var end_drag_3_right = Vector2(550,150)
				draw_line(start_drag_3, end_drag_3_right,Color(0.937,0.149,0.945,1.0),2.0,true)
				draw_triangle(end_drag_3_right,end_drag_3_right-start_drag_3,7,Color(0.937,0.149,0.945,1.0))				
	
				if !get_node_or_null("example_sprite3"):
					var node4 = Sprite.new()
					node4.name = "example_sprite3"
					add_child(node4)
				get_node("example_sprite3").set_global_position(Vector2(600,210))
				get_node("example_sprite3").texture = load("res://Sprites/finger_swipe_2.png")
				get_node("example_sprite3").rotation_degrees = 0
				get_node("example_sprite3").set_scale(Vector2(0.5,0.5))	
		
				if !get_node_or_null("Instruction_three"):
					var node5 = Label.new()
					node5.name = "Instruction_three"
					add_child(node5)	
				get_node("Instruction_three").set_global_position(Vector2(560,105))
				get_node("Instruction_three").text = "Swipe to right, to rotate \nthe camera clockwisely"
				get_node("Instruction_three").add_color_override("font_color", Color(0,0,0,1))					
				get_node("Instruction_three").add_font_override("font",dynamic_font)		
		
			elif animation_count == 3:
			# delete the pre instruction nodes
				if get_node_or_null("Instruction_three"):
					get_node("Instruction_three").queue_free()
					get_node("example_sprite3").queue_free()
			# instruction two.3 - one-finger camera up gesture	
				var start_drag_4 = Vector2(600,150)
				var end_drag_4_up = Vector2(600,70)
				draw_line(start_drag_4, end_drag_4_up,Color(0.937,0.149,0.945,1.0),2.0,true)
				draw_triangle(end_drag_4_up,end_drag_4_up-start_drag_4,7,Color(0.937,0.149,0.945,1.0))				
				
				if !get_node_or_null("example_sprite4"):
					var node5 = Sprite.new()
					node5.name = "example_sprite4"
					add_child(node5)
				get_node("example_sprite4").set_global_position(Vector2(670,110))
				get_node("example_sprite4").texture = load("res://Sprites/finger_swipe_1.png")
				get_node("example_sprite4").rotation_degrees = -90
				get_node("example_sprite4").set_scale(Vector2(0.5,0.5))		
	
				if !get_node_or_null("Instruction_four"):
					var node6 = Label.new()
					node6.name = "Instruction_four"
					add_child(node6)	
				get_node("Instruction_four").set_global_position(Vector2(505,160))
				get_node("Instruction_four").text = "Swipe up, to raise the camera"
				get_node("Instruction_four").add_color_override("font_color", Color(0,0,0,1))					
				get_node("Instruction_four").add_font_override("font",dynamic_font)
	
			elif animation_count == 4:
			# delete the pre instruction nodes	
				if get_node_or_null("Instruction_four"):
					get_node("Instruction_four").queue_free()
					get_node("example_sprite4").queue_free()	
			# instruction two.4 - one-finger camera down gesture	
				var start_drag_5 = Vector2(600,100)
				var end_drag_5_up = Vector2(600,180)
				draw_line(start_drag_5, end_drag_5_up,Color(0.937,0.149,0.945,1.0),2.0,true)
				draw_triangle(end_drag_5_up,end_drag_5_up-start_drag_5,7,Color(0.937,0.149,0.945,1.0))				
	
				if !get_node_or_null("example_sprite5"):
					var node7 = Sprite.new()
					node7.name = "example_sprite5"
					add_child(node7)
				get_node("example_sprite5").set_global_position(Vector2(530,140))
				get_node("example_sprite5").texture = load("res://Sprites/finger_swipe_1.png")
				get_node("example_sprite5").rotation_degrees = 90
				get_node("example_sprite5").set_scale(Vector2(0.5,0.5))	
				
				if !get_node_or_null("Instruction_five"):
					var node8 = Label.new()
					node8.name = "Instruction_five"
					add_child(node8)	
				get_node("Instruction_five").set_global_position(Vector2(485,75))
				get_node("Instruction_five").text = "Swipe down, to lower the camera"
				get_node("Instruction_five").add_color_override("font_color", Color(0,0,0,1))											
				get_node("Instruction_five").add_font_override("font",dynamic_font)
		
		elif animation_count == 5:
			# delete the pre instruction nodes
			if get_node_or_null("Instruction_five"):
				get_node("Instruction_five").queue_free()
				get_node("example_sprite5").queue_free()
			# instruction three - two-finger contour control
			var pointxz_rec = camera.unproject_position(x_limit+z_limit)	
			var pointx_negz_rec = camera.unproject_position(x_limit-z_limit)	
			var pointnegx_z_rec = camera.unproject_position(-x_limit+z_limit)	
			var pointnegx_negz_rec = camera.unproject_position(-x_limit-z_limit)
			
			draw_polygon(PoolVector2Array([pointxz_rec, pointx_negz_rec, \
				pointnegx_negz_rec, pointnegx_z_rec]), \
				PoolColorArray([illustration_region_color]))		
	
			# draw an example contour
			var radius = 0.8
			var pre_vector = Vector3(radius,0,0)
			var ellipse_drawing_step = 500
			var correction_point = 20
			var anti_aliasing_transparent = 0.2
			var anti_aliasing_linewidth = 1.2
			var delta = 2*PI/(ellipse_drawing_step - 1)
			var origin = Vector3(-2,0,-2)
	
			for n in range(0, ellipse_drawing_step+correction_point):
				var theta = 0 + n*delta
				var draw1 = camera.unproject_position(origin + Vector3(radius * cos(theta), 0, radius * sin(theta)))
				var draw2 = camera.unproject_position(origin + pre_vector)
				if !is_nan(draw1.x) && !is_nan(draw2.x):
					draw_line(camera.unproject_position(origin + Vector3(radius * cos(theta), 0, radius * sin(theta))), \
						camera.unproject_position(origin + pre_vector), Color(0,0,0,1), 1.0, true)
					draw_line(camera.unproject_position(origin+Vector3(radius * cos(theta), 0, radius * sin(theta))), \
						camera.unproject_position(origin + pre_vector), Color(0,0,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
	
				pre_vector = Vector3(radius * cos(theta),0, radius*sin(theta))
	
			var point_finger1_inside = camera.unproject_position(origin + Vector3(radius*cos(PI),0,radius*sin(PI)))
			var point_finger2_inside = camera.unproject_position(origin + Vector3(radius*cos(PI/5),0,radius*sin(PI/5)))
			draw_circle(point_finger1_inside,5,ColorN("Black"))
			draw_circle(point_finger2_inside,5,ColorN("Black"))		
	
			radius = 2*radius
			pre_vector = Vector3(radius,0,0)
			for n in range(0, ellipse_drawing_step+correction_point):
				var theta = 0 + n*delta
				var draw1 = camera.unproject_position(origin + Vector3(radius * cos(theta), 0, radius * sin(theta)))
				var draw2 = camera.unproject_position(origin + pre_vector)
				if !is_nan(draw1.x) && !is_nan(draw2.x):
					draw_line(camera.unproject_position(origin + Vector3(radius * cos(theta), 0, radius * sin(theta))), \
						camera.unproject_position(origin + pre_vector), Color(0,0,0,1), 1.0, true)
					draw_line(camera.unproject_position(origin+Vector3(radius * cos(theta), 0, radius * sin(theta))), \
						camera.unproject_position(origin + pre_vector), Color(0,0,0,anti_aliasing_transparent), anti_aliasing_linewidth, true)		
	
				pre_vector = Vector3(radius * cos(theta),0, radius*sin(theta))		
	
			var point_finger1_outside = camera.unproject_position(origin + Vector3(radius*cos(PI),0,radius*sin(PI)))
			var point_finger2_outside = camera.unproject_position(origin + Vector3(radius*cos(PI/5),0,radius*sin(PI/5)))
			draw_circle(point_finger1_outside,5,ColorN("Black"))
			draw_circle(point_finger2_outside,5,ColorN("Black"))			
		
			var shrink_vec1 = (point_finger1_outside-point_finger1_inside)*0.15
			var shrink_vec2 = (point_finger2_outside-point_finger2_inside)*0.3
			draw_line(point_finger1_inside+0.5*shrink_vec1, point_finger1_outside-shrink_vec1,Color(0.937,0.149,0.945,1.0),2.0,true)
			draw_line(point_finger2_inside+0.5*shrink_vec2, point_finger2_outside-shrink_vec2,Color(0.937,0.149,0.945,1.0),2.0,true)
			draw_triangle(point_finger1_outside-shrink_vec1, point_finger1_outside-point_finger1_inside,5,Color(0.937,0.149,0.945,1.0))
			draw_triangle(point_finger2_outside-shrink_vec2, point_finger2_outside-point_finger2_inside,5,Color(0.937,0.149,0.945,1.0))
			
			# add instruction text and picture
			if !get_node_or_null("example_sprite6"):
				var node8 = Sprite.new()
				node8.name = "example_sprite6"	
				add_child(node8)
			get_node("example_sprite6").set_global_position(Vector2(525,325))
			get_node("example_sprite6").texture = load("res://Sprites/finger_pinch.png")
			get_node("example_sprite6").rotation_degrees = -94
			get_node("example_sprite6").set_scale(Vector2(0.17,0.17))	
	
			if !get_node_or_null("Instruction_six"):
				var node9 = Label.new()
				node9.name = "Instruction_six"
				add_child(node9)	
			get_node("Instruction_six").set_global_position(Vector2(200,520))
			get_node("Instruction_six").text = "Two-finger pinch to change \nthe 1st-deviation-contour of Gaussian"
			get_node("Instruction_six").add_color_override("font_color", Color(0,0,0,1))		
			get_node("Instruction_six").add_font_override("font",dynamic_font)
		
	elif animation_count >= 6:	
		if get_node_or_null("Instruction_six"):
			get_node("Instruction_six").queue_free()
			get_node("example_sprite6").queue_free()
		if get_node_or_null("button"):
			get_node("button").queue_free()
		animation_finish = true

		
##############################################################	
# draw a triangle on the 2d canvas
func draw_triangle(pos:Vector2, dir:Vector2, size, color):
	dir = dir.normalized()
	var a = pos + dir*size
	var b = pos + dir.rotated(2*PI/3)*size
	var c = pos + dir.rotated(4*PI/3)*size
	var points = PoolVector2Array([a,b,c])
	draw_polygon(points, PoolColorArray([color]))	
	
