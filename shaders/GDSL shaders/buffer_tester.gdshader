shader_type spatial;

uniform sampler2D normal_texture:hint_normal_roughness_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(normal_texture, SCREEN_UV).xyz;
}