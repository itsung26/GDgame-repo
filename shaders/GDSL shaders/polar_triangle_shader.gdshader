shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_texture:hint_screen_texture;

uniform vec3 swirl_color:source_color;
uniform float emission_intensity = 1.0;
uniform float swirl_prog = 1.0;
uniform float swirls = 1.0;
uniform float line_thickness:hint_range(0.001, 0.2, 0.001) = 0.02;
uniform float theta_offset = 0.0;
uniform float radius_scale = 1.0;
uniform float radius_offset = 0.0;
uniform float clipping_distance:hint_range(0.0, 0.5, 0.01) = 0.5;


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


// Rounds theta to the nearest multiple of 2 * PI.
float roundToNearestTauPeriod(float theta) {
	float periods_covered = theta / TAU;
	float ret = round(periods_covered) * TAU;
	return ret;
}


float roundToTauOverInteger(float swirls_value) {
	float safe = max(swirls_value, 0.0001);
	// nearest integer factor count
	float n = round(TAU / safe);
	// avoid n = 0
	n = max(n, 1.0);
	return TAU / n;
}


float spiralFunction(float theta) {
	float theta_transformed = theta + theta_offset;
	// the period of the polar triangle function
	float p = roundToTauOverInteger(swirls);
	float base_r = abs((theta_transformed / p) - floor((theta_transformed / p) + swirl_prog));
	float r_curve = (base_r * radius_scale) + radius_offset;
	return r_curve;
}


void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 pixel_pos = UV - center;
	vec2 polar_uv = toPolar(pixel_pos.x, pixel_pos.y);
	float r_pixel = polar_uv.x;
	float theta = polar_uv.y;
	float r_curve = spiralFunction(theta);
	float radial_dist = abs(r_pixel - r_curve);
	float col = 1.0 - smoothstep(0.0, line_thickness, radial_dist);

	// blackout any pixels beyond a specific polar radius
	if (polar_uv.x > clipping_distance) {
		col = 0.0;
	}

	// calculate and apply the color
	vec3 emission_color = swirl_color * emission_intensity;

	EMISSION = emission_color;
	ALBEDO = vec3(0.0);
	ALPHA = col;
}
