shader_type spatial; render_mode specular_disabled;

uniform vec2 uv_stretch = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform vec2 uv_cell_stretch = vec2(1.0);
uniform vec2 uv_cell_offset = vec2(0.0);
uniform float cells_amt = 1.0;
uniform vec2 test_point;


vec2 toHex(vec2 xy) {
	float q = ((sqrt(3.0) / 3.0) * xy.x) - ((1.0 / 3.0) * xy.y);
	float r = (2.0 / 3.0) * xy.y;
	return vec2(q, r);
}


float sdHexagon(vec2 p) {
	// reflect to first quadrant
	p = abs(p);

	// project onto hex axes
	return max(p.x * 0.8660254 + p.y * 0.5, p.y) - 1.0;
}


void fragment() {
	vec2 uv_transformed = (UV  * uv_stretch) + uv_offset;
	vec2 grid = uv_transformed * cells_amt;
	vec2 uv_cell_id = floor(grid);   // which cell
	vec2 uv_cell = fract(grid);   // local coords (0–1)
	// now the transformations are applied to the cells
	uv_cell = (uv_cell * uv_cell_stretch) + -(uv_cell_stretch / 2.0);
	vec2 uv_hex = toHex(uv_transformed);
	float distance_to_center = distance(uv_hex, test_point);

	
	ALBEDO = vec3(0.0);
	EMISSION = vec3(sdHexagon(uv_cell));
}

