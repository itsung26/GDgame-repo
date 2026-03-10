shader_type spatial;

// Controls how large each hexagon is in UV space.
// Larger values = larger hexes.
uniform float hex_scale = 2.0;

// Thickness of the black border between hexes.
uniform float border_thickness = 0.08;

// Base colors
uniform vec3 hex_color : source_color = vec3(1.0);
uniform vec3 border_color : source_color = vec3(0.0);

// Controls where the interior turns fully "on" (0..1 mask threshold)
uniform float hex_fill_threshold = 0.5;

// Signed distance to a regular hex centered at the origin, radius r.
// Negative inside, 0 at border, positive outside.
float sd_hex(vec2 p, float r) {
	p = abs(p);
	return max(p.x * 0.8660254 + p.y * 0.5, p.y) - r;
}

// Helper: round cube coordinates to nearest hex grid cell
vec3 cube_round(vec3 h) {
	vec3 r = floor(h + 0.5);
	vec3 diff = abs(r - h);

	if (diff.x > diff.y && diff.x > diff.z) {
		r.x = -r.y - r.z;
	} else if (diff.y > diff.z) {
		r.y = -r.x - r.z;
	} else {
		r.z = -r.x - r.y;
	}
	return r;
}

// Return distance to nearest hex border using a regular hex tiling
float hex_border_distance(vec2 uv) {
	// Scale UVs to control overall hex size
	vec2 p = uv * hex_scale;

	// Convert from Cartesian to axial hex coordinates (pointy-top layout)
	float q = (0.5773503 * p.x - 0.3333333 * p.y); // sqrt(3)/3, 1/3
	float r = (0.6666667 * p.y);                   // 2/3

	// Axial (q,r) to cube (x,y,z) with x + y + z = 0
	vec3 cube = vec3(q, -q - r, r);

	// Round to nearest hex cell
	vec3 cube_rounded = cube_round(cube);
	q = cube_rounded.x;
	r = cube_rounded.z;

	// Back to Cartesian: center position of this hex cell
	vec2 center = vec2(
		1.7320508 * (q + r * 0.5), // sqrt(3)
		1.5 * r
	);

	// Local position relative to hex center
	vec2 local = p - center;

	// Signed distance to a unit-radius hex
	float d = sd_hex(local, 1.0);

	// We want positive inside, ~0 at border
	return -d;
}

void fragment() {
	// Use mesh UVs; if your mesh has different UV layout you can adjust here.
	vec2 uv = UV;

	// Distance > 0 => inside hex, near 0 => at border, < 0 => outside (in next hex)
	float dist_to_border = hex_border_distance(uv);

	// Use smoothstep so borders remain visible even for small thickness values
	float inside = smoothstep(0.0, border_thickness, dist_to_border);

	// Shape the interior using a simple greater-than comparison
	inside = inside > hex_fill_threshold ? 1.0 : 0.0;

	vec3 color = mix(border_color, hex_color, inside);

	ALBEDO = color;
	ALPHA = 1.0;
}

