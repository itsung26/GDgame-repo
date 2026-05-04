shader_type spatial; render_mode specular_disabled;

uniform float uv_scale = 1.0;
uniform vec2 uv_offset;
uniform sampler2D noise_texture;
uniform float float_param_g;
uniform float float_param_t;
uniform float dissolve_fac:hint_range(0.0, 1.0, 0.001) = 0.0;
uniform vec3 color:source_color;
uniform float emission_intensity = 1.0;

float periodicStep(float value) {
	if (min(mod(value, float_param_g), float_param_g - mod(value, float_param_g)) <= float_param_t) {
		return 1.0;
	} else {
		return 0.0;
	}
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv_transformed = (UV * uv_scale) + uv_offset;
	vec3 frag_world_coord = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float noise_value = texture(noise_texture, uv_transformed).r;
	float periodic_step_combined = clamp(
		periodicStep(frag_world_coord.x) +
		periodicStep(frag_world_coord.y) +
		periodicStep(frag_world_coord.z),
		0.0,
		1.0
	);
	float blackout = 1.0 - step(dissolve_fac, noise_value);
	
	ALBEDO = vec3(0.0);
	EMISSION = color * emission_intensity;
	ALPHA = (mix(periodic_step_combined, 0.0, blackout));
}
