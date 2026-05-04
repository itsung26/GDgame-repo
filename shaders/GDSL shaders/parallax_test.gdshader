shader_type spatial; render_mode unshaded;

uniform sampler2D noise_tex;
uniform float uv_scale = 1.0;
uniform vec2 uv_offset;

vec3 viewDirToWorld(mat4 inv_view_matrix, vec3 dir) {
	return normalize(mat3(inv_view_matrix) * dir);
}


vec3 viewPosToWorld(mat4 inv_view_matrix, vec3 pos) {
	return (inv_view_matrix * vec4(pos, 1.0)).xyz;
}


void vertex() {
	// Called for every vertex the material is visible on.
}


void fragment() {
	vec3 world_normal = viewDirToWorld(INV_VIEW_MATRIX, NORMAL);
	vec3 world_pos = viewPosToWorld(INV_VIEW_MATRIX, VERTEX);
	vec3 view_world = viewDirToWorld(INV_VIEW_MATRIX, VIEW);
	vec2 uv_world = (world_pos.xz * uv_scale) + uv_offset;
	float dotprod = dot(world_normal, view_world);
	dotprod = clamp(dotprod, -1.0, 1.0);
	float angle_between = acos(dotprod);
	
	
	ALBEDO = texture(noise_tex, uv_world).xyz;
	//ALBEDO = vec3(angle_between);
}