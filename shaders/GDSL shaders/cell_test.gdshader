shader_type spatial; render_mode specular_disabled;

uniform vec2 uv_stretch = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform vec2 uv_cell_stretch = vec2(1.0);
uniform vec2 uv_cell_offset = vec2(0.0);
uniform float float_param = 1.0;
uniform float float_param_2 = 1.0;
uniform vec2 test_point;

// Returns xyz in cube hex coordinates, from rectangular.
vec3 toHexCube(vec2 xy) {
	// Pointy-top conversion from Cartesian/pixel space to cube coords.
	float sqrt_3 = sqrt(3.0);
	float x = ((sqrt_3 / 3.0) * xy.x) - ((1.0 / 3.0) * xy.y);
	float z = (2.0 / 3.0) * xy.y;
	float y = -x - z;
	return vec3(x, y, z);
}

// returns distance to nearest multiple of val
float distInterval(float x, float val) {
	float step_val = max(abs(val), 0.00001);
	float nearest = round(x / step_val) * step_val;
	return abs(x - nearest);
}


// returns 1.0 if x is in range range of y
float isInThreshold(float x, float y, float range) {
	float threshold = max(range, 0.0);
	return step(abs(x - y), threshold);
}


// returns 0.0 if x is below threshold
float blackout(float x, float threshold) {
	return step(threshold, x);
}


void fragment() {
	vec2 uv = UV - vec2(0.5, 0.5);
	vec3 uv_hex = toHexCube(uv);
	
	float x = distInterval(uv_hex.x, float_param);
	float y = distInterval(uv_hex.y, float_param);
	float z = distInterval(uv_hex.z, float_param);
	//x = isInThreshold(x, 0.0, float_param_2);
	//y = isInThreshold(y, 0.0, float_param_2);
	//z = isInThreshold(z, 0.0, float_param_2);
	x = blackout(x, float_param_2);
	y = blackout(y, float_param_2);
	z = blackout(z, float_param_2);
	
	ALBEDO = vec3(0.0);
	EMISSION = vec3(x + y + z);
}

