shader_type spatial;
render_mode unshaded;

uniform int moon_type = 0;
varying vec3 local_position;

vec3 cell_point(vec3 cell) {
	return fract(sin(vec3(dot(cell, vec3(127.1, 311.7, 74.7)), dot(cell, vec3(269.5, 183.3, 246.1)), dot(cell, vec3(113.5, 271.9, 124.6)))) * 43758.5453);
}

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = normalize(local_position);
	float terrain = sin(p.x * 17.0 + sin(p.z * 13.0) * 2.0) * sin(p.y * 21.0 + p.z * 9.0);
	float detail = sin(p.x * 97.0 + p.y * 83.0) * sin(p.z * 109.0 - p.y * 67.0);
	vec3 sample_position = p * (moon_type == 3 ? 24.0 : 12.0);
	vec3 cell = floor(sample_position);
	float nearest = 10.0;
	float second = 10.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = cell + vec3(float(x), float(y), float(z));
				float distance_to_cell = length(neighbor + cell_point(neighbor) - sample_position);
				second = min(second, max(nearest, distance_to_cell));
				nearest = min(nearest, distance_to_cell);
			}
		}
	}
	float cracks = 1.0 - smoothstep(0.012, 0.045, second - nearest);
	float crater = 1.0 - smoothstep(0.12, 0.25, nearest);
	float rim = smoothstep(0.19, 0.25, nearest) * (1.0 - smoothstep(0.25, 0.31, nearest));
	vec3 surface;
	if (moon_type == 0) {
		surface = mix(vec3(0.65, 0.29, 0.045), vec3(0.96, 0.81, 0.30), terrain * 0.5 + 0.5);
		surface = mix(surface, vec3(0.18, 0.065, 0.025), crater);
		surface += rim * vec3(0.14, 0.035, 0.0);
	} else if (moon_type == 1) {
		surface = mix(vec3(0.67, 0.64, 0.53), vec3(0.95, 0.92, 0.79), terrain * 0.5 + 0.5);
		surface = mix(surface, vec3(0.40, 0.19, 0.10), cracks * 0.85);
	} else if (moon_type == 2) {
		surface = mix(vec3(0.22, 0.19, 0.16), vec3(0.65, 0.60, 0.50), smoothstep(-0.3, 0.4, terrain));
		surface *= 1.0 - cracks * 0.16 - crater * 0.4;
		surface += rim * 0.16;
	} else {
		surface = mix(vec3(0.12, 0.105, 0.09), vec3(0.32, 0.29, 0.25), terrain * 0.5 + 0.5);
		surface *= 1.0 - crater * 0.65;
		surface += rim * 0.46;
	}
	float light = 0.25 + 0.75 * max(dot(p, normalize(vec3(0.7, 0.8, -0.6))), 0.0);
	ALBEDO = (surface + detail * 0.025) * light;
}
