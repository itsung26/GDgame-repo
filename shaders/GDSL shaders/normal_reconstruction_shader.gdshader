shader_type spatial;

uniform sampler2D noise_tex:hint_normal;
uniform float normal_intensity = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 normal_map = texture(noise_tex, UV).xyz;
	vec3 normal_map_scaled = vec3(normal_map.xy * normal_intensity, normal_map.z);

	ALBEDO = vec3(1.0);
	EMISSION = vec3(0.0);
	NORMAL_MAP = vec3(normal_map_scaled);
}