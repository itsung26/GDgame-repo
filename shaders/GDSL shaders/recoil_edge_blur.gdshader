shader_type canvas_item;

// Screen buffer to sample for the blur; bound automatically when used in a full-screen pass (Godot 4).
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Elliptical radius (aspect-corrected) where blur begins; inside this radius the image stays sharp.
uniform float blur_inner_radius = 0.6;

// Elliptical radius where blur reaches full strength; should be >= blur_inner_radius (clamped in shader).
uniform float blur_outer_radius = 0.95;

// How much to mix in the blurred color in the edge band (0 = no blur, 1 = full blur).
uniform float blur_strength = 0.9;

// Blur kernel size in texels; higher values give a smoother, heavier blur at higher cost.
uniform float blur_sample_radius = 2.0;

void fragment() {
	// Base UV in [0,1].
	vec2 uv = UV;

	vec2 screen_pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	// Compute aspect ratio from the texture to make the blur elliptical
	// so it doesn't stretch on non-square viewports.
	float aspect = screen_pixel_size.y / screen_pixel_size.x;

	// Recenter to [-0.5, 0.5], apply aspect, then compute elliptical distance.
	vec2 centered = uv - vec2(0.5);
	centered.y *= aspect;
	float dist = length(centered) * 2.0; // Scale so ~1.0 is near the edge.

	// Clamp radii to keep them sane.
	float inner_r = clamp(blur_inner_radius, 0.0, 2.0);
	float outer_r = clamp(blur_outer_radius, inner_r + 0.0001, 3.0);

	vec4 base_col = texture(screen_texture, uv);

	// Compute a 0..1 factor for how "edge-y" this pixel is.
	float t = smoothstep(inner_r, outer_r, dist);
	// If fully inside the inner region or blur strength is zero, just output the base color.
	if (t <= 0.0 || blur_strength <= 0.0) {
		COLOR = base_col;
	} else {

	// Sample a small blur kernel around the pixel, using texture texel size.
	vec2 texel = screen_pixel_size * blur_sample_radius;

		vec4 col = vec4(0.0);
		col += texture(screen_texture, uv + vec2(-texel.x, -texel.y));
		col += texture(screen_texture, uv + vec2( 0.0,      -texel.y));
		col += texture(screen_texture, uv + vec2( texel.x, -texel.y));
		col += texture(screen_texture, uv + vec2(-texel.x,  0.0));
		col += texture(screen_texture, uv);
		col += texture(screen_texture, uv + vec2( texel.x,  0.0));
		col += texture(screen_texture, uv + vec2(-texel.x,  texel.y));
		col += texture(screen_texture, uv + vec2( 0.0,       texel.y));
		col += texture(screen_texture, uv + vec2( texel.x,  texel.y));
		col /= 9.0;

		// Mix between original and blurred based on edge factor and strength.
		float mix_factor = t * blur_strength;
		COLOR = mix(base_col, col, mix_factor);
	}
}

