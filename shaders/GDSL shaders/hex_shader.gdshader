shader_type spatial;

// Controls how large each hexagon is in UV space.
// Larger values = larger hexes.
uniform float hex_scale = 2.0;

// Thickness of the black border between hexes.
uniform float border_thickness = 0.08;

// Controls for hexagon UVs (before hex tiling)
uniform vec2 hex_uv_scale = vec2(1.0, 1.0);
uniform float hex_uv_rotation = 0.0; // radians
uniform vec2 hex_uv_offset = vec2(0.0, 0.0);

// Base colors
uniform vec3 hex_color : source_color = vec3(1.0);
uniform vec3 border_color : source_color = vec3(0.0);

// Controls where the interior turns fully "on" (0..1 mask threshold)
uniform float hex_fill_threshold = 0.5;

// Alpha controls for hex interior and border
uniform float hex_alpha = 1.0;
uniform float border_alpha = 1.0;

// Emission intensity for hex interior and border
uniform float hex_emission = 0.0;
uniform float border_emission = 0.0;

// Texture to draw hexagons on top of (hex alpha is the blend factor)
uniform sampler2D overlay_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

// Controls for overlay texture UVs
uniform vec2 overlay_uv_scale = vec2(1.0, 1.0);
uniform float overlay_uv_rotation = 0.0; // radians
uniform vec2 overlay_uv_offset = vec2(0.0, 0.0);

// Color and alpha controls applied to the overlay texture
uniform vec3 overlay_color : source_color = vec3(1.0);
uniform float overlay_alpha_mul = 1.0;

// Toggles whether overlay blending is active
uniform bool overlay_enabled = true;

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

	// Apply scale, rotation (around 0.5,0.5), and offset to hex UVs
	vec2 hex_uv = uv * hex_uv_scale;
	float hs = sin(hex_uv_rotation);
	float hc = cos(hex_uv_rotation);
	vec2 hex_centered = hex_uv - vec2(0.5);
	hex_uv = vec2(
		hc * hex_centered.x - hs * hex_centered.y,
		hs * hex_centered.x + hc * hex_centered.y
	) + vec2(0.5);
	hex_uv += hex_uv_offset;

	// Distance > 0 => inside hex, near 0 => at border, < 0 => outside (in next hex)
	float dist_to_border = hex_border_distance(hex_uv);

	// Use smoothstep so borders remain visible even for small thickness values
	float inside = smoothstep(0.0, border_thickness, dist_to_border);

	// Shape the interior using a simple greater-than comparison
	inside = inside > hex_fill_threshold ? 1.0 : 0.0;

	// Lerp between border and hex properties using the inside mask
	vec3 hex_layer_color = mix(border_color, hex_color, inside);
	float alpha = mix(border_alpha, hex_alpha, inside);
	float emission_intensity = mix(border_emission, hex_emission, inside);

	// Base outputs from the hex layer (alpha from uniforms controls transparency)
	vec3 final_albedo = hex_layer_color;
	float final_alpha = alpha;
	vec3 final_emission = hex_layer_color * emission_intensity;

	if (overlay_enabled) {
		// Overlay hex layer on top of the texture; alpha is the blend factor
		// Apply scale, rotation (around 0.5,0.5), and offset to overlay UVs
		vec2 overlay_uv = uv * overlay_uv_scale;
		float s = sin(overlay_uv_rotation);
		float c = cos(overlay_uv_rotation);
		vec2 centered = overlay_uv - vec2(0.5);
		overlay_uv = vec2(
			c * centered.x - s * centered.y,
			s * centered.x + c * centered.y
		) + vec2(0.5);
		overlay_uv += overlay_uv_offset;

		vec4 overlay_rgba = texture(overlay_texture, overlay_uv);

		// Apply user color tint and alpha multiplier to the overlay
		vec3 overlay_rgb = overlay_rgba.rgb * overlay_color;
		float overlay_alpha = overlay_rgba.a * overlay_alpha_mul;

		// Mix colors using the hex alpha as blend factor
		final_albedo = mix(overlay_rgb, hex_layer_color, alpha);

		// Combine overlay and hex alpha so transparency depends on both
		// (union over black: a = a_hex + a_overlay - a_hex * a_overlay)
		final_alpha = overlay_alpha + alpha - overlay_alpha * alpha;
	}

	ALBEDO = final_albedo;
	ALPHA = final_alpha;
	EMISSION = final_emission;
}

