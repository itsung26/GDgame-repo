// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Local axis to keep fixed when billboarding (in mesh local space).
// For trails, usually (1, 0, 0) to keep the length axis fixed.
uniform vec3 billboard_axis = vec3(1.0, 0.0, 0.0);

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_nearest, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_emission : source_color, hint_default_black, filter_nearest, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Billboard the quad around a customizable local axis so that the quad's
	// normal faces the camera as much as possible while preserving that axis.
	// We work in local space and only rotate the vertex position; the engine
	// will still apply MODEL/VIEW/PROJECTION afterwards.

	// Direction from object origin to camera in world space.
	// Godot 4 does not expose CAMERA_POSITION directly, so we derive it:
	vec3 cam_world = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 obj_world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 to_cam_world = normalize(cam_world - obj_world);

	// Bring that direction into local space.
	mat3 model3 = mat3(MODEL_MATRIX);
	mat3 inv_model3 = inverse(model3);
	vec3 to_cam_local = normalize(inv_model3 * to_cam_world);

	// Local axis we want to keep fixed (e.g. trail length direction).
	vec3 x_dir = normalize(billboard_axis);

	// Project camera direction onto plane perpendicular to x_dir.
	vec3 v = to_cam_local - x_dir * dot(to_cam_local, x_dir);
	if (dot(v, v) > 1e-6) {
		vec3 z_dir = normalize(v);                 // desired quad normal
		vec3 y_dir = normalize(cross(z_dir, x_dir));

		// Build a local rotation basis with x_dir fixed.
		mat3 R = mat3(x_dir, y_dir, z_dir);       // columns: X, Y, Z

		vec3 local_pos = VERTEX;
		local_pos = R * local_pos;
		VERTEX = local_pos;
	}
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Emission: Enabled
	vec3 emission_tex = texture(texture_emission, base_uv).rgb;
	// Emission Operator: Multiply
	EMISSION = (emission.rgb * emission_tex) * emission_energy;
	ALPHA *= albedo.a * albedo_tex.a;
}
