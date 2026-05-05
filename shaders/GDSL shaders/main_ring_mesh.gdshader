shader_type spatial; render_mode specular_disabled;

uniform vec3 primary_color:source_color;
uniform float color_intensity = 1.0;
uniform float alpha:hint_range(0.0, 1.0, 0.001) = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// construct a surface normal vector via computing a vector perpendicular
	// to the surface x and y derivatives (also known as the surface tangents).
	vec3 derivX = dFdx(world_pos);
	vec3 derivY = dFdy(world_pos);
	vec3 true_normal = -normalize(cross(derivX, derivY));
	
	NORMAL = true_normal;
	ALBEDO = vec3(0.0);
	EMISSION = vec3(primary_color * color_intensity);
	ALPHA = alpha;
}
