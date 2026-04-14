shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color:source_color;
uniform sampler2D screen_texture:hint_screen_texture;
uniform float power = 1.0;
uniform float multiplicant = 1.0;
uniform float displacement = 1.0;
uniform float period_amplitude = 1.0;
uniform float period_oscillate_speed = 1.0;
uniform float petals = 1.0;
uniform float rotate_speed = 0.0;
uniform float line_thickness = 0.05;

void vertex() {
	// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

// returns x and y in terms of r and theta
vec2 toPolar(float x, float y){
	float magnitude = distance(vec2(0.0, 0.0), vec2(x, y));
	float angle = atan(y, x);
	return vec2(magnitude, angle);
}

// Returns r and theta in terms of x and y.
vec2 toRectangular(float _radius, float _theta) {
	float x = _radius * cos(_theta);
	float y = _radius * sin(_theta);
	return vec2(x, y);
}

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 pixel_pos = UV - center;
	vec2 pixel_pos_polar = toPolar(pixel_pos.x, pixel_pos.y);
	float pixel_pos_polar_radius = pixel_pos_polar.x;
	float pixel_pos_polar_angle = pixel_pos_polar.y;
	
	// oscillate the period
	float p = period_amplitude * sin(TIME * period_oscillate_speed);
	
	// signed distance field built by a polar function.
	// The closer to the field sh.
	// r = a + b(sin(petals(theta) + d))
	float r_curve = displacement + (p * sin((pixel_pos_polar_angle * petals) + TIME * rotate_speed));

	// distance of the pixel's radius from the border of the shape
	float pixel_distance_from_curve = distance(pixel_pos_polar_radius, r_curve);
	pixel_distance_from_curve = clamp(pixel_distance_from_curve, 0.0, 1.0);
	
	
	float col = pixel_distance_from_curve;
	if (col < line_thickness) {
		col = 1.0;
	} else {
		col = 0.0;
	}

	
	
	EMISSION = vec3(1.0);
	ALBEDO = base_color;
	ALPHA = col;
}

