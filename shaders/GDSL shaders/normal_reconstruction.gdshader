shader_type spatial; render_mode cull_disabled;

uniform vec3 base_color:source_color;
uniform float normal_strength = 1.0;
uniform float cells_amt = 1.0;
uniform float circle_radius = 0.25;
uniform float circle_falloff = 0.2;
const float NORMAL_EPSILON = 0.001;

float sampleHeightFunction(vec2 uv) {
	vec2 uv_center = vec2(0.5, 0.5);
	float distance_to_center = distance(uv, uv_center);
	float edge_start = circle_radius;
	float edge_end = circle_radius + circle_falloff;
	float falloff = 1.0 - smoothstep(edge_start, edge_end, distance_to_center);
	return clamp(falloff, 0.0, 1.0);
}

vec3 calculateHeightFunctionTangentNormal(vec2 uv) {
	float sampling_distance = max(NORMAL_EPSILON / max(cells_amt, 1.0), 0.00001);
	float sampled_left = sampleHeightFunction(uv - vec2(sampling_distance, 0.0));
	float sampled_right = sampleHeightFunction(uv + vec2(sampling_distance, 0.0));
	float sampled_up = sampleHeightFunction(uv + vec2(0.0, sampling_distance));
	float sampled_down = sampleHeightFunction(uv - vec2(0.0, sampling_distance));
	
	float derivative_x = ((sampled_right - sampled_left) / (2.0 * sampling_distance)) * normal_strength;
	float derivative_y = ((sampled_up - sampled_down) / (2.0 * sampling_distance)) * normal_strength;
	
	vec3 reconstructed_normal = normalize(vec3(-derivative_x, derivative_y, 1.0));
	
	return reconstructed_normal;
}

void vertex() {
	// pass
}

void fragment() {
	vec2 uv_cell = fract(UV * cells_amt);

	ALBEDO = vec3(base_color);
	NORMAL_MAP = vec3(calculateHeightFunctionTangentNormal(uv_cell));
}