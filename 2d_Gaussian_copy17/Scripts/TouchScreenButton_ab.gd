extends TouchScreenButton


var radius = Vector2(64,64)
var boundary = 90
var ongoing_drag = -1
var return_accel = 8
var threshold = 10


func _ready():
	var node_background = get_parent()
	node_background.set_global_position(Vector2(135,156))
	VisualServer.texture_set_shrink_all_x2_on_set_data(true)


func _process(delta):
# return the handler to the center
	if ongoing_drag == -1:
		var pos_difference = (Vector2(0,0) - radius) - position
		position += pos_difference * return_accel * delta


func get_button_pos():
	return position + radius

func _input(event):	
	if event is InputEventScreenDrag or (event is InputEventScreenTouch \
		and event.is_pressed()):
			
		# keep tracking the button when finger is on
		var event_dist_from_centre = (event.position - get_parent().global_position).length()
		if event_dist_from_centre <= boundary * global_scale.x or event.get_index() == ongoing_drag:
			ongoing_drag = event.get_index()

		# fix the handler inside the circle
			set_global_position(event.position-radius*global_scale)	

			if get_button_pos().length() > boundary:
				set_position(get_button_pos().normalized()*boundary - radius)
		
			ongoing_drag = event.get_index()	
			
	if event is InputEventScreenTouch and !event.is_pressed() and event.get_index()==ongoing_drag:
		ongoing_drag = -1

func get_value():
	if get_button_pos().length() > threshold:
		return get_button_pos().normalized()
	return Vector2(0,0)


