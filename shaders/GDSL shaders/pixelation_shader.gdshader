shader_type canvas_item;
render_mode blend_mix;

// Godot 4: declare screen texture explicitly
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float pixel_resolution : hint_range(16.0, 720.0, 1.0) = 180.0;
uniform float dither_strength  : hint_range(0.0, 1.0, 0.01) = 0.5;

// 2x2 Bayer-style dither pattern based on screen-space pixel coords
float dither_threshold(vec2 frag_pos) {
    vec2 p = floor(frag_pos);      // integer pixel coords
    vec2 r = mod(p, 2.0);          // 0..1 in each axis
    float v = r.x + r.y * 2.0;     // 0,1,2,3
    return v / 4.0;                // 0.0, 0.25, 0.5, 0.75
}

void fragment() {
    // Use screen UVs so this works as a fullscreen post-process
    vec2 uv = SCREEN_UV;

    // Quantize UVs based on desired pixel resolution (higher = finer pixels)
    vec2 pixelated_uv = floor(uv * pixel_resolution) / pixel_resolution;

    vec4 col = texture(screen_texture, pixelated_uv);

    // Screen-space dithering on brightness
    float lum = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));
    float threshold = dither_threshold(FRAGCOORD.xy);

    // Quantize brightness with a bit of dither-driven offset
    float levels = 4.0; // number of brightness steps
    float q = floor(lum * levels + threshold * dither_strength) / levels;

    // Apply quantized brightness back to color while preserving hue roughly
    float factor = lum > 0.0 ? (q / max(lum, 1e-4)) : 0.0;
    col.rgb *= factor;

    COLOR = col;
}