shader_type spatial;

uniform float fresnel_power = 1.0;
uniform bool fresnel_invert = false;
uniform vec3 fresnel_color:source_color;
uniform float fresnel_brightness = 1.0;

// shader style fresnel operation
float fresnel(vec3 normal, vec3 viewDir, float power, bool invert) {
    // Fresnel term: F = (1 - dot(n, v))^power
    float f = pow(1.0 - abs(dot(normalize(normal), normalize(viewDir))), power);
    if (invert) {
        f = 1.0 - f;
    }
    return f;
}

vec3 viewPosToWorld(vec3 xyz, mat4 inv_view_matrix) {
	return (inv_view_matrix * vec4(xyz, 1.0)).xyz;
}

// takes a direction in view space and returns it in world space, normalized
vec3 viewDirToWorld(vec3 xyz, mat4 inv_view_matrix) {
	// Transform the direction with the inverse view matrix (ignore translation)
	vec3 world_dir = mat3(inv_view_matrix) * xyz;
	return normalize(world_dir);
}

void fragment() {
	vec3 normal_world = viewDirToWorld(NORMAL, INV_VIEW_MATRIX);
	vec3 frag_to_camera_dir = (normalize(viewDirToWorld(normalize(-VERTEX), INV_VIEW_MATRIX)));
	
	ALBEDO = vec3(0.0);
	ALPHA = clamp(float(fresnel(normal_world, frag_to_camera_dir, fresnel_power, fresnel_invert)), 0.0, 1.0);
	EMISSION = vec3(fresnel_color * fresnel_brightness);
}
