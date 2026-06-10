shader_type canvas_item;

uniform sampler2D screen_texture:hint_screen_texture;

// returns a point interpolated towards target by fac
vec2 moved_towards(vec2 uv, vec2 target, float fac) {
	return mix(uv, target, fac);
}

void fragment() {
	vec2 vector_to_center = vec2(0.5, 0.5) - SCREEN_UV;
	float distance_to_center = length(vector_to_center);
	float inverse_distance_to_center = 1.0 - distance_to_center;
	
	vec3 screen_tex_col = texture(screen_texture, moved_towards(SCREEN_UV, vec2(0.5, 0.5), distance_to_center)).xyz;
	
	vec3 color = vec3(screen_tex_col);
	COLOR = vec4(color, 1.0);
}