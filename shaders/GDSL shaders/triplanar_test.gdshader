shader_type spatial; render_mode specular_disabled;

uniform sampler2D tex:filter_nearest;
uniform sampler2D tex_2:filter_nearest;
uniform float mapping_scale = 1.0;
uniform float y_normal_bias = 1.0;
uniform float xz_normal_bias = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 WORLD_NORMAL = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// z axis normal
	vec3 xy_projection = texture(tex, vec2(world_pos.xy * mapping_scale)).xyz;
	// y axis normal up
	vec3 xz_projection_up = texture(tex_2, vec2(world_pos.xz * mapping_scale)).xyz;
	// y axis normal down
	vec3 xz_projection_down = texture(tex, vec2(world_pos.xz * mapping_scale)).xyz;
	// x axis normal
	vec3 yz_projection = texture(tex, vec2(world_pos.yz * mapping_scale)).xyz;
	
	// scale by bias and re normalize
	WORLD_NORMAL.y = WORLD_NORMAL.y * y_normal_bias;
	WORLD_NORMAL = normalize(WORLD_NORMAL);
	
	vec3 result_col = 
	(clamp(WORLD_NORMAL.y, 0.0, 1.0) * xz_projection_up) + 
	(clamp(-WORLD_NORMAL.y, 0.0, 1.0) * xz_projection_down) + 
	(abs(WORLD_NORMAL.x) * yz_projection) + 
	(abs(WORLD_NORMAL.z) * xy_projection);
		
	EMISSION = vec3(result_col);
	ALBEDO = vec3(0.0);
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}
