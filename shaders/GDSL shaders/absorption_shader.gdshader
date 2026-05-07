shader_type spatial;

uniform sampler2D depth_texture:hint_depth_texture;
uniform float float_param;


float get_linear_depth(vec2 screen_uv, mat4 inv_projection_matrix) {
	float depth = texture(depth_texture, screen_uv).r;
	vec3 ndc = vec3(screen_uv, depth) * 2.0 - 1.0;
	vec4 view_pos = inv_projection_matrix * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	return -view_pos.z;
}


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float d_raw = texture(depth_texture, SCREEN_UV).r;
	float d_lin = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);

	// Raw depth visualization
	// ALBEDO = vec3(d_raw);

	// Linear depth visualization (scaled into 0..1)
	ALBEDO = vec3(clamp(d_lin / float_param, 0.0, 1.0));
}