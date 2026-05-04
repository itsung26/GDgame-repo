shader_type spatial;

uniform vec3 vec3_parameter;
uniform float float_parameter;
uniform float power = 1.0;

varying vec3 barycentric_coord;

void vertex() {
	int index = VERTEX_ID % 3;
	switch (index) {
		case 0:
			barycentric_coord = vec3(1.0, 0.0, 0.0);
			break;
		case 1:
			barycentric_coord = vec3(0.0, 1.0, 0.0);
			break;
		case 2:
			barycentric_coord = vec3(0.0, 0.0, 1.0);
			break;
	}
}

void fragment() {
	float distance_to_bary_edge = min(barycentric_coord.x, min(barycentric_coord.y, barycentric_coord.z));

	ALBEDO = vec3(0.0);
	if (distance_to_bary_edge < float_parameter) {
		EMISSION = vec3(1.0);
	} else {
		EMISSION = vec3(0.0);
	}
}
