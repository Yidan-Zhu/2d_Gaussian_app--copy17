extends Node2D

#######################
#      PARAMS
#######################

# UIs
onready var slider_theta = $VSlider_theta
onready var slider_rho = $VSlider_rho

onready var minus_pi_text = $VSlider_theta/Label_minusPi
onready var plus_pi_text = $VSlider_theta/Label_plusPi
onready var minus_one_text = $VSlider_rho/Label_minusOne
onready var plus_one_text = $VSlider_rho/Label_plusOne
onready var theta_label = $VSlider_theta/Label_theta
onready var rho_label = $VSlider_rho/Label_rho

onready var joystick_ab = $joystick_ab/joystick_background/TouchScreenButton_ab
onready var joystick_dev = $joystick_deviations/joystick_background2/TouchScreenButton_deviations

onready var joystick_a_text = $joystick_ab/joystick_background/Label_a
onready var joystick_b_text = $joystick_ab/joystick_background/Label_b
onready var joystick_devx_text = $joystick_deviations/joystick_background2/Label_dev_x
onready var joystick_devy_text = $joystick_deviations/joystick_background2/Label_dev_z

# signal out
onready var gesture_para = get_tree().get_root().find_node(\
	"Line2D_Gaussian_Contour",true,false)
var old_slider_theta_value
var new_slider_theta_value
var param_theta_from_another_script
var old_slider_rho_value
var new_slider_rho_value
var param_rho_from_another_script

# animation
onready var animation_node = get_tree().get_root().find_node(\
	"Line2D_drawAnimation",true,false)
var animation_finish = false

################################

func _ready():
	# set the location of sliders
	slider_theta.set_global_position(Vector2(45,105))
	slider_rho.set_global_position(Vector2(45,275))

	slider_theta.step = 0.01
	slider_theta.min_value = -PI
	slider_theta.max_value = PI
	slider_theta.value = 0
	slider_theta.rect_size = Vector2(16,100)
	
	slider_rho.step = 0.01
	slider_rho.min_value = -0.5
	slider_rho.max_value = 0.5
	slider_rho.value = 0
	slider_rho.rect_size = Vector2(16,100)

	# set a font
	var dynamic_font = DynamicFont.new()
	dynamic_font.font_data = load("res://Fonts/HussarBd.otf")
	dynamic_font.size = 30
	
	var dynamic_font_small = DynamicFont.new()
	dynamic_font_small.font_data = load("res://Fonts/HussarBd.otf")
	dynamic_font_small.size = 11.8
	
	# set the location of slider labels
	# slider theta	
	minus_pi_text.text = "-Pi"
	minus_pi_text.add_color_override("font_color", ColorN("Black"))
	minus_pi_text.set_global_position(Vector2(28,195))

	plus_pi_text.text = "+Pi"
	plus_pi_text.add_color_override("font_color", ColorN("Black"))
	plus_pi_text.set_global_position(Vector2(26.5,100))
	
	theta_label.text = "Theta"
	theta_label.add_font_override("font",dynamic_font_small)
	theta_label.add_color_override("font_color", ColorN("Black"))
	theta_label.set_global_position(Vector2(26,85))
	
	# slider rho
	minus_one_text.text = "-.5"
	minus_one_text.add_color_override("font_color", ColorN("Black"))
	minus_one_text.set_global_position(Vector2(29,362))	

	plus_one_text.text = "+.5"
	plus_one_text.add_color_override("font_color", ColorN("Black"))
	plus_one_text.set_global_position(Vector2(27.2,274))		

	rho_label.text = "Rho"
	rho_label.add_font_override("font",dynamic_font_small)
	rho_label.add_color_override("font_color", ColorN("Black"))
	rho_label.set_global_position(Vector2(27,259))

	
	# set the location of joystick labels
	joystick_a_text.text = "a"
	joystick_a_text.add_font_override("font",dynamic_font)
	joystick_a_text.add_color_override("font_color", ColorN("Black"))
	joystick_a_text.set_global_position(Vector2(192,151))

	joystick_b_text.text = "b"
	joystick_b_text.add_font_override("font",dynamic_font)
	joystick_b_text.add_color_override("font_color", ColorN("Black"))
	joystick_b_text.set_global_position(Vector2(130,88))

	joystick_devx_text.text = "Sigma x"
	joystick_devx_text.add_font_override("font",dynamic_font)
	joystick_devx_text.add_color_override("font_color", ColorN("Black"))
	joystick_devx_text.set_global_position(Vector2(204,299))	
	joystick_devx_text.rect_rotation = 90

	joystick_devy_text.text = "Sigma z"
	joystick_devy_text.add_font_override("font",dynamic_font)
	joystick_devy_text.add_color_override("font_color", ColorN("Black"))
	joystick_devy_text.set_global_position(Vector2(109,254))

	# signal sent judgment
	old_slider_theta_value = slider_theta.value
	param_theta_from_another_script = gesture_para.contour_theta
	
	old_slider_rho_value = slider_rho.value
	param_rho_from_another_script = gesture_para.correlation_Gaussian

func _process(_delta):
	animation_finish = animation_node.animation_finish
	if animation_finish == false: # disable side panel when instruction is unfinished
		slider_rho.editable = false
		slider_theta.editable = false
	else:
		slider_rho.editable = true
		slider_theta.editable = true
	
		# signal out - drawing type 1
		if joystick_ab.get_value() != Vector2(0,0):
			gesture_para.drawing_type_flag = "slider_change_ab_theta"
	
		new_slider_theta_value = slider_theta.value
		param_theta_from_another_script = gesture_para.contour_theta
		if new_slider_theta_value != old_slider_theta_value:
			gesture_para.drawing_type_flag = "slider_change_ab_theta"
			gesture_para.contour_theta = new_slider_theta_value
			old_slider_theta_value = new_slider_theta_value          # slider changes value
		elif new_slider_theta_value == old_slider_theta_value && \
			param_theta_from_another_script != old_slider_theta_value:
			slider_theta.value = param_theta_from_another_script
			gesture_para.drawing_type_flag = "mean_change"
			old_slider_theta_value = param_theta_from_another_script  # type 2 UI changes theta

		# signal out - drawing type 2
		param_rho_from_another_script = gesture_para.correlation_Gaussian  # check the rho value in script
		new_slider_rho_value = slider_rho.value
		if new_slider_rho_value != old_slider_rho_value:
			gesture_para.drawing_type_flag = "slider_change_rho"
			gesture_para.correlation_Gaussian = new_slider_rho_value
			old_slider_rho_value = new_slider_rho_value   # slider changes value
		elif new_slider_rho_value == old_slider_rho_value && \
			param_rho_from_another_script != old_slider_rho_value:
			slider_rho.value = param_rho_from_another_script
			gesture_para.drawing_type_flag = "mean_change"
			old_slider_rho_value = param_rho_from_another_script # other ways of changing rho in script
		
		# signal out - drawing type 3
		if joystick_dev.get_value() != Vector2(0,0):
			gesture_para.drawing_type_flag = "slider_change_deviations"	
		

