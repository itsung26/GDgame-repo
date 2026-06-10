shader_type spatial;

uniform float fresnel_power = 1.0;
uniform bool fresnel_invert = false;
uniform float fresnel_brightness = 1.0;
uniform sampler2D cell_noise_texture;
uniform sampler2D color_ramp:filter_nearest;

vec3 spherical_coordinates(vec3 position) {
	vec3 spherical_position = vec3(length(position.xz), atan(position.z, position.x), position.y);
	return spherical_position;
}

float fresnel(vec3 normal, vec3 viewDir, float power, bool invert) {
    // Fresnel term: F = (1 - dot(n, v))^power
    float f = pow(1.0 - abs(dot(normalize(normal), normalize(viewDir))), power);
    if (invert) {
        f = 1.0 - f;
    }
    return f;
}

// takes a direction in world space and returns a color based on cubic color coordinates
// converted to spherical coordinates.
vec3 direction_to_color(vec3 direction) {
	vec3 normalized_direction = normalize(direction);
	vec3 color = normalized_direction * 0.5 + 0.5;
	return clamp(color, vec3(0.0), vec3(1.0));
}

vec3 viewPosToWorld(vec3 view_position, mat4 inverse_view_matrix) {
	return (inverse_view_matrix * vec4(view_position, 1.0)).xyz;
}

vec3 viewDirToWorld(vec3 view_direction, mat4 inverse_view_matrix) {
	return normalize((inverse_view_matrix * vec4(view_direction, 0.0)).xyz);
}

float sample_color_ramp(float value) {
	return texture(color_ramp, vec2(value, 0.5)).r;
}

vec2 rect_to_polar(vec2 rect) {
	float
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 frag_world_coord = viewPosToWorld(VERTEX, INV_VIEW_MATRIX);
	vec3 frag_world_normal = viewDirToWorld(NORMAL, INV_VIEW_MATRIX);

	float fresnel_value = fresnel(NORMAL, VIEW, fresnel_power, fresnel_invert);
	fresnel_value *= fresnel_brightness;
	
	float cell_noise_value = clamp(texture(cell_noise_texture, UV).x, 0.0, 1.0);
	float cell_noise_value_ramped = sample_color_ramp(cell_noise_value);
	
	vec2 SC
	
	// ALPHA = fresnel_value;
	ALBEDO = vec3(0.0);
	EMISSION = vec3(1.0);
	ALPHA = (1.0);
}
