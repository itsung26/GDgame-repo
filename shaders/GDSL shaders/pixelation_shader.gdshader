shader_type canvas_item;
render_mode blend_mix;

// Godot 4: declare screen texture explicitly
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float pixel_resolution : hint_range(16.0, 720.0, 1.0) = 180.0;

void fragment() {
    // Use screen UVs so this works as a fullscreen post-process
    vec2 uv = SCREEN_UV;

    // Quantize UVs based on desired pixel resolution (higher = finer pixels)
    vec2 pixelated_uv = floor(uv * pixel_resolution) / pixel_resolution;

    COLOR = texture(screen_texture, pixelated_uv);
}