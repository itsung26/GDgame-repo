shader_type spatial;

uniform vec2 points[2];

vec3 view_to_world(vec3 vector, bool is_direction, mat4 inv_view_matrix) {
	float w = is_direction ? 0.0 : 1.0;
	vec3 world = (inv_view_matrix * vec4(vector, w)).xyz;
	if (is_direction) {
		return normalize(world);
	}
	return world;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 vertex_world = view_to_world(VERTEX, false, INV_VIEW_MATRIX);
	
	float col = distance(vertex_world.xz, points[1]);
	
	ALBEDO = vec3(col);
}
