shader_type spatial;

uniform float color;
uniform float multiplier;
uniform float power;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(color);
	vec3 frag_normal = normalize(NORMAL);
	vec3 view_normal = VIEW;

	float angle_difference = dot(frag_normal, normalize(view_normal));
	angle_difference = clamp(angle_difference, -1.0, 1.0);
	EMISSION = pow(vec3(angle_difference) * multiplier, power);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
