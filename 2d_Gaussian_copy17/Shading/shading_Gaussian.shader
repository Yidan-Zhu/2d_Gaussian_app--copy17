shader_type spatial;

uniform float variance_x=1.0;
uniform float variance_z=1.0;
uniform float mean_x=0.5;
uniform float mean_z=0.5;
uniform float correlation=0.0;
uniform float Gaussian_scale_up = 20.0;

//uniform sampler2D texturemap : hint_albedo;
//uniform vec2 texture_scale = vec2(8.0,4.0);

//void fragment(){
//	ALBEDO = texture(texturemap, UV*texture_scale).rgb;
//}

float y_value(float x,float z){
	float coefficient = 1.0/(2.0*3.1416*variance_x*variance_z*sqrt(1.0-correlation*correlation));
	float power_index_coefficient = -1.0/(2.0*(1.0-correlation*correlation));
	float power_index_main = pow(x-mean_x,2.0)/pow(variance_x,2.0) - 
						   2.0*correlation*(x-mean_x)*(z-mean_z)/(variance_x*variance_z) + 
						   pow(z-mean_z,2.0)/pow(variance_z,2.0);
   	float probability_density = coefficient*exp(power_index_coefficient*power_index_main);
	return probability_density; 
}

void vertex(){
	VERTEX.y = Gaussian_scale_up*y_value(VERTEX.x, VERTEX.z);
	TANGENT = normalize(vec3(0.0, y_value(VERTEX.x, VERTEX.z + 0.2) - y_value(VERTEX.x, VERTEX.z - 0.2), 0.4));
	BINORMAL = normalize(vec3(0.4, y_value(VERTEX.x+0.2,VERTEX.z)-y_value(VERTEX.x-0.2,VERTEX.z),0.0));
	NORMAL = cross(TANGENT,BINORMAL);
}
