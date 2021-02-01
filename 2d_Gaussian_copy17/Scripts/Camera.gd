extends Camera

##################
#    PARAMS
##################

# target
export var camera_rotation = 45
export var camera_height = 4
var rot_matrix = Transform2D()

func _ready():
	# set the initial location of the camera
	rot_matrix.x.x = cos(deg2rad(camera_rotation))
	rot_matrix.x.y = - sin(deg2rad(camera_rotation))
	rot_matrix.y.x = sin(deg2rad(camera_rotation))
	rot_matrix.y.y = cos(deg2rad(camera_rotation))
	
	rotation_degrees = Vector3(-20, 90, 0)   # camera rotation
	
	var coord_ref = Vector2(0,-7.5)
	var initial_coord = rot_matrix*coord_ref
	translation = Vector3(initial_coord.x, camera_height, initial_coord.y)   # camera position
	
	look_at(Vector3(0,0,0), Vector3(0,1,0))   # camera facing


func _process(_delta):		
	rot_matrix.x.x = cos(deg2rad(camera_rotation))
	rot_matrix.x.y = - sin(deg2rad(camera_rotation))
	rot_matrix.y.x = sin(deg2rad(camera_rotation))
	rot_matrix.y.y = cos(deg2rad(camera_rotation))
	
	rotation_degrees = Vector3(-20, 90, 0)
	
	var coord_ref = Vector2(0,-7.5)
	var initial_coord = rot_matrix*coord_ref
	translation = Vector3(initial_coord.x, camera_height, initial_coord.y)
	
	look_at(Vector3(0,0,0), Vector3(0,1,0))

