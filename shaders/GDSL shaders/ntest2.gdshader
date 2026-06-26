shader_type spatial;

uniform float uv_scale = 1.0;
uniform float normal_strength = 1.0;
const float EPSILON = 0.0001;
uniform sampler2D falloff_texture;

float sample_falloff_texture(float fac) {
	return texture(falloff_texture, vec2(fac, 0.5)).r;
}

float sample_shape_function(vec2 uv) {
	float distance_to_center = distance(uv, vec2(0.5));
	return sample_falloff_texture(distance_to_center);
}

vec3 construct_tangent_normal(vec2 uv) {
	float center = sample_shape_function(uv);
	float up = sample_shape_function(uv + vec2(0.0, EPSILON));
	float down = sample_shape_function(uv - vec2(0.0, EPSILON));
	float right = sample_shape_function(uv + vec2(EPSILON, 0.0));
	float left = sample_shape_function(uv - vec2(EPSILON, 0.0));
	
	float deriv_x = ((right - left) / (2.0 * EPSILON)) * normal_strength;
	float deriv_y = ((up - down) / (2.0 * EPSILON)) * normal_strength;
	
	vec3 tangent_normal = normalize(vec3(-deriv_x, -deriv_y, 1.0));
	return tangent_normal;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv_transformed = UV * uv_scale;
	
	//ALBEDO = vec3(sample_shape_function(uv_transformed));
	//ALBEDO = vec3(construct_tangent_normal(uv_transformed));
	ALBEDO = vec3(1.0);
	EMISSION = vec3(0.0);
	NORMAL_MAP = construct_tangent_normal(uv_transformed);
}
