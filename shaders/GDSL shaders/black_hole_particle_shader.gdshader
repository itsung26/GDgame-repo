// Minimal GPUParticles process shader template (Godot 4.x).
// Entry points: start() = spawn / reset, process() = each simulation step.

shader_type particles;

// Optional: disable built-in velocity integration if you move TRANSFORM yourself only.
// render_mode disable_velocity;

// uniform float example_strength : hint_range(0.0, 10.0) = 1.0;

// Matches Godot's Basis.get_euler(EulerOrder.YXZ): radians in X, Y, Z application order for that convention.
// Requires uniform scaling on each axis (columns share one scale factor); otherwise normalization is wrong.
const float EULER_EPS = 0.00000025;
const float HALF_PI = 1.57079632679;

uniform vec3 rotation;
uniform vec3 look_at_point;


vec3 getEulerRot(mat4 transform) {
	// Two-argument atan(y, x) is quadrant-correct (C's atan2); Godot shaders do not define atan2.
	// Upper 3x3: basis with optional uniform scale. Normalize columns to get a pure rotation matrix.
	// Pass TRANSFORM from start()/process() — built-ins are not visible inside user functions.
	vec3 c0 = normalize(transform[0].xyz);
	vec3 c1 = normalize(transform[1].xyz);
	vec3 c2 = normalize(transform[2].xyz);
	// Columns of R are local X, Y, Z axes in the parent/emission space of this matrix.
	mat3 R = mat3(c0, c1, c2);
	// Godot Basis row i col j equals R[j][i] when R is built from column vectors (transpose indexing).
	float m12 = R[2][1];
	vec3 euler;

	if (m12 < (1.0 - EULER_EPS)) {
		if (m12 > -(1.0 - EULER_EPS)) {
			// Gimbal-adjacent: pure rotation about local X (editor-friendly special case in Godot).
			bool pure_x = (
					abs(R[0][1]) < EULER_EPS &&
					abs(R[1][0]) < EULER_EPS &&
					abs(R[2][0]) < EULER_EPS &&
					abs(R[0][2]) < EULER_EPS &&
					abs(R[0][0] - 1.0) < EULER_EPS);
			if (pure_x) {
				euler.x = atan(-m12, R[1][1]);
				euler.y = 0.0;
				euler.z = 0.0;
			} else {
				euler.x = asin(clamp(-m12, -1.0, 1.0));
				euler.y = atan(R[2][0], R[2][2]);
				euler.z = atan(R[0][1], R[1][1]);
			}
		} else {
			// m12 == -1: pitch locked at +90°.
			euler.x = HALF_PI;
			euler.y = atan(R[1][0], R[0][0]);
			euler.z = 0.0;
		}
	} else {
		// m12 == 1: pitch locked at -90°.
		euler.x = -HALF_PI;
		euler.y = -atan(R[1][0], R[0][0]);
		euler.z = 0.0;
	}
	return euler;
}


// Inverse of getEulerRot: applies Basis.set_euler(YXZ) — same as ymat * xmat * zmat in Godot's basis.cpp.
// Preserves per-axis column lengths (scale). Translation (transform[3].xyz) is unchanged.
// Pass TRANSFORM from start()/process() — built-ins are not visible inside user functions.
void setEulerRot(inout mat4 transform, vec3 euler_yxz) {
	float sx = length(transform[0].xyz);
	float sy = length(transform[1].xyz);
	float sz = length(transform[2].xyz);
	sx = max(sx, 1e-6);
	sy = max(sy, 1e-6);
	sz = max(sz, 1e-6);

	float cx = cos(euler_yxz.x);
	float s_x = sin(euler_yxz.x);
	mat3 xmat = mat3(
			vec3(1.0, 0.0, 0.0),
			vec3(0.0, cx, s_x),
			vec3(0.0, -s_x, cx));

	float cy = cos(euler_yxz.y);
	float s_y = sin(euler_yxz.y);
	mat3 ymat = mat3(
			vec3(cy, 0.0, -s_y),
			vec3(0.0, 1.0, 0.0),
			vec3(s_y, 0.0, cy));

	float cz = cos(euler_yxz.z);
	float s_z = sin(euler_yxz.z);
	mat3 zmat = mat3(
			vec3(cz, s_z, 0.0),
			vec3(-s_z, cz, 0.0),
			vec3(0.0, 0.0, 1.0));

	mat3 R = ymat * xmat * zmat;
	transform[0].xyz = R[0] * sx;
	transform[1].xyz = R[1] * sy;
	transform[2].xyz = R[2] * sz;
}


// Orients the basis so local -Z faces the target (same as Node3D: forward is -basis.z).
// `where` and `transform[3]` must be in the same space (e.g. both world if position is world).
// `up_vector` is a hint for the local +Y axis (usually vec3(0,1,0) in world space).
// Pass TRANSFORM from start()/process() — built-ins are not visible inside user functions.
void lookAt(inout mat4 transform, vec3 up_vector, vec3 where) {
	vec3 pos = transform[3].xyz;
	vec3 to_target = where - pos;
	float dist = length(to_target);
	if (dist > 1e-6) {
		vec3 fwd = to_target / dist;
		vec3 z_axis = -fwd;
		vec3 x_axis = cross(up_vector, z_axis);
		float lx = length(x_axis);
		if (lx < 1e-6) {
			x_axis = cross(vec3(0.0, 0.0, 1.0), z_axis);
			lx = length(x_axis);
		}
		if (lx < 1e-6) {
			x_axis = cross(vec3(1.0, 0.0, 0.0), z_axis);
			lx = length(x_axis);
		}
		x_axis = x_axis / max(lx, 1e-6);
		vec3 y_axis = cross(z_axis, x_axis);
		y_axis = normalize(y_axis);

		float sx = max(length(transform[0].xyz), 1e-6);
		float sy = max(length(transform[1].xyz), 1e-6);
		float sz = max(length(transform[2].xyz), 1e-6);

		transform[0].xyz = x_axis * sx;
		transform[1].xyz = y_axis * sy;
		transform[2].xyz = z_axis * sz;
	}
}


void start() {
	// Only the matching RESTART_* blocks run for this emission event.
	if (RESTART_CUSTOM) {
		CUSTOM = vec4(0.0);
		// Pack your own per-particle state in CUSTOM (vec4). Example: age in .x
	}
	if (RESTART_COLOR) {
		COLOR = vec4(1.0, 1.0, 1.0, 1.0);
	}
	if (RESTART_ROT_SCALE) {
		TRANSFORM[0].xyz = vec3(1.0, 0.0, 0.0);
		TRANSFORM[1].xyz = vec3(0.0, 1.0, 0.0);
		TRANSFORM[2].xyz = vec3(0.0, 0.0, 1.0);
	}
	if (RESTART_POSITION) {
		TRANSFORM[3].xyz = vec3(0.0);
		TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	}
	if (RESTART_VELOCITY) {
		VELOCITY = vec3(0.0, 0.0, 0.0);
	}
}


void process() {
	// Normalized age over particle lifetime (0 -> 1). Adjust or replace with your own logic.
	float age = CUSTOM.x + DELTA / LIFETIME;
	CUSTOM.x = age;
	if (age > 1.0) {
		ACTIVE = false;
	} else {
		TRANSFORM[3].xyz += VELOCITY * DELTA;
		lookAt(TRANSFORM, vec3(0.0, 1.0, 0.0), look_at_point);
	}
}
