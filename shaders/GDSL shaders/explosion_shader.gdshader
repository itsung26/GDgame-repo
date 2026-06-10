shader_type spatial;

uniform vec3 color:source_color;
uniform float intensity = 1.0;
uniform float alpha = 1.0;

varying vec3 vertex_view_space;

void vertex() {
	vertex_view_space = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 derivative_x = dFdx(vertex_view_space);
	vec3 derivative_y = dFdy(vertex_view_space);
	
	vec3 reconstructed_flat_normal = normalize(cross(derivative_y, derivative_x));
	
	NORMAL = reconstructed_flat_normal;
	ALBEDO = vec3(0.0);
	EMISSION = color * intensity;
	ALPHA = alpha;
}
