shader_type spatial;

uniform sampler2D depth_texture:hint_depth_texture;
uniform float far_edge = 1.0;
uniform float dropoff = 1.0;
uniform vec3 color:source_color;
uniform float emission_intensity = 1.0;
uniform float nearest_emission_intensity = 0.10;
uniform float opacity = 1.0;


vec3 get_world_position(
	vec2 screen_uv,
	float depth,
	mat4 inv_projection_matrix,
	mat4 inv_view_matrix
) {
	// In Godot 4, sampled depth is already in 0..1 clip-space range.
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	vec4 view_pos = inv_projection_matrix * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	vec4 world_pos = inv_view_matrix * vec4(view_pos.xyz, 1.0);
	return world_pos.xyz;
}

// returns a value between output_min and output_max based on the value between input_min and input_max
float remap(float value, float input_min, float input_max, float output_min, float output_max) {
	return output_min + (value - input_min) * (output_max - output_min) / (input_max - input_min);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float scene_depth_raw = texture(depth_texture, SCREEN_UV).r;
	vec3 scene_world_pos = get_world_position(
		SCREEN_UV,
		scene_depth_raw,
		INV_PROJECTION_MATRIX,
		INV_VIEW_MATRIX
	);
	vec3 current_world_pos = get_world_position(
		SCREEN_UV,
		FRAGCOORD.z,
		INV_PROJECTION_MATRIX,
		INV_VIEW_MATRIX
	);

	// True world-space distance to the first surface behind this fragment.
	float behind_distance_world = max(distance(scene_world_pos, current_world_pos), 0.0);
	float distance_behind_world_remapped = clamp(remap(behind_distance_world, 0.0, far_edge, 0.0, 1.0), 0.0, 1.0);
	float distance_behind_world_dropoff = pow(distance_behind_world_remapped, dropoff);
	float inverse_distance_behind_world_dropoff = 1.0 - distance_behind_world_dropoff;

	float emission_multiplier = inverse_distance_behind_world_dropoff * emission_intensity;
	emission_multiplier = clamp(emission_multiplier, nearest_emission_intensity, 1.0);

	ALBEDO = vec3(0.0);
	EMISSION = vec3(emission_multiplier);
	EMISSION = EMISSION * color * emission_intensity;
	ALPHA = opacity;
}