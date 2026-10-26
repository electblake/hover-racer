shader_type spatial;
render_mode world_vertex_coords;

uniform float elapsed = 0.0;
uniform vec4 wakes[16]; // world x/z, birth time, strength
varying vec3 world_position;

void vertex() {
	world_position = VERTEX;
	// Flat physical surface; ripples perturb shading, not displacement.
}

void fragment() {
	vec2 p = world_position.xz;
	float flow = sin(p.x * 0.68 + p.y * 0.22 + elapsed * 1.4);
	float crossflow = cos(p.y * 1.1 - p.x * 0.3 - elapsed * 1.8);
	float wake = 0.0;
	for (int i = 0; i < 16; i++) {
		float age = max(elapsed - wakes[i].z, 0.0);
		float distance_from_wake = length(p - wakes[i].xy);
		float ring = exp(-pow((distance_from_wake - age * 5.0) * 0.65, 2.0));
		wake += ring * exp(-age * 1.6) * wakes[i].w;
	}
	// Repeating raindrop impacts, staggered independently in each world-space cell.
	vec2 cell = floor(p / 3.0);
	float seed = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	float rain_age = fract(elapsed * 1.2 + seed);
	vec2 center = (cell + vec2(0.25 + seed * 0.5, 0.75 - seed * 0.5)) * 3.0;
	float rain_ring = exp(-pow((length(p - center) - rain_age * 1.6) * 13.0, 2.0)) * (1.0 - rain_age);
	float ripple = flow * 0.55 + crossflow * 0.3 + wake * 1.7 + rain_ring * 0.6;
	ALBEDO = mix(vec3(0.48, 0.21, 0.008), vec3(1.0, 0.77, 0.06), clamp(0.55 + ripple * 0.22, 0.0, 1.0));
	METALLIC = 0.68;
	ROUGHNESS = 0.2;
	EMISSION = vec3(1.0, 0.58, 0.01) * (0.12 + wake * 0.5 + rain_ring * 0.15);
	vec3 tangent = normalize((VIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
	vec3 bitangent = normalize((VIEW_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz);
	NORMAL = normalize(NORMAL + tangent * (flow * 0.13 + wake * 0.2) + bitangent * (crossflow * 0.12 + rain_ring * 0.16));
}
