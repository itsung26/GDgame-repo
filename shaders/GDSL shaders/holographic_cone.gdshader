shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec3 color:source_color;
uniform sampler2D fade_alpha_curve:filter_nearest;
uniform sampler2D noise_texture:filter_nearest;
uniform vec2 uv_scale = vec2(1.0);


float distanceToTop(vec2 uv) {
	return distance(uv.y, 0.0);
}


float remap(float x, float in_min, float in_max, float out_min, float out_max) {
	return out_min + (x - in_min) * (out_max - out_min) / (in_max - in_min);
}


void fragment() {
	float distance_to_top = distanceToTop(UV);
	
	// sample the curve to determine the fadeout as UV.y approaches 0.0
	float alpha = texture(fade_alpha_curve, vec2(distance_to_top, 0.5)).r;
	
	// multiply the current alpha with a noise texture to add some noise
	// first the uv is scaled
	vec2 screen_uv_transformed = SCREEN_UV * uv_scale;
	// then the multiplication happens
	alpha = alpha * texture(noise_texture, screen_uv_transformed + vec2(TIME, 0.0)).r;
	
	ALPHA = alpha;
	EMISSION = vec3(color);
	ALBEDO = vec3(0.0);
}
