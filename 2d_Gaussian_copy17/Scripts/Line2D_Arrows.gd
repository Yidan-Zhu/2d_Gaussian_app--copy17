extends Line2D

#####################
#     PARAMS
#####################
# arrows
onready var script_parameter = get_node("../..")
var origin_projection


func _ready():
	origin_projection = script_parameter.origin_projection
	
func _process(_delta):
	origin_projection = script_parameter.origin_projection
	update()

func _draw():
	draw_triangle(script_parameter.x_end_projection_pos, script_parameter.x_end_projection_pos - origin_projection, 7, Color(0.75,0.75,0.75,1))
	draw_triangle(script_parameter.x_end_projection_neg, script_parameter.x_end_projection_neg - origin_projection, 7, Color(0.75,0.75,0.75,1))
	draw_triangle(script_parameter.z_end_projection_pos, script_parameter.z_end_projection_pos - origin_projection, 7, Color(0.75,0.75,0.75,1))
	draw_triangle(script_parameter.z_end_projection_neg, script_parameter.z_end_projection_neg - origin_projection, 7, Color(0.75,0.75,0.75,1))
	draw_triangle(script_parameter.y_end_projection, script_parameter.y_end_projection - origin_projection, 7, Color(0.75,0.75,0.75,1))

# draw a triangle on the 2d canvas
func draw_triangle(pos:Vector2, dir:Vector2, size, color):
	dir = dir.normalized()
	var a = pos + dir*size
	var b = pos + dir.rotated(2*PI/3)*size
	var c = pos + dir.rotated(4*PI/3)*size
	var points = PoolVector2Array([a,b,c])
	draw_polygon(points, PoolColorArray([color]))
