shader_type spatial;

uniform float fresnel_power: hint_range(0.0, 16.0, 0.1) = 1.0;
uniform bool fresnel_invert = false;
uniform float frequency = 1.0;
uniform float amplitude = 1.0;
uniform float offset = 0.0;

uniform float emission_multiplier = 1.0;
uniform vec3 inner_color: source_color = vec3(0.0);
uniform vec3 outer_color: source_color = vec3(1.0);

void vertex() {
	// Called for every vertex the material is visible on.
}


void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 emission = vec3(0.0);
	
	vec3 frag_normal = normalize(NORMAL);
	vec3 view_normal = VIEW;

	float angle_difference = dot(frag_normal, normalize(view_normal));
	angle_difference = clamp(angle_difference, -1.0, 1.0);
	emission = vec3(pow(angle_difference, fresnel_power));
	
	if (fresnel_invert == true) {
		emission = 1.0 - emission;
	}
	
	// oscillate the emission_multiplier for a growing/shrinking effect
	emission = emission * (emission_multiplier * ((amplitude * sin(TIME * frequency)) + offset));
	
	// the fresnel texture stored in emission will serve as a mask for mixing the two colors
	emission = mix(outer_color, inner_color, emission);
	
	emission = clamp(emission, 0.0, 1.0);
	
	EMISSION = emission;
	ALBEDO = vec3(0.0);
}