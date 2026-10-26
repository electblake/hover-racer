shader_type spatial;
render_mode world_vertex_coords, cull_disabled;

uniform bool racing_surface = false;
varying vec3 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	float radius = length(world_position.xz);
	float grains = sin(radius * 4.8) * sin(radius * 0.63) * 0.15;
	float band = 0.5 + 0.5 * sin(radius * 0.47);
	vec3 color = mix(vec3(0.22, 0.12, 0.15), vec3(0.83, 0.61, 0.39), band);
	ALBEDO = mix(color + grains, vec3(0.48, 0.45, 0.53) + grains * 0.4, float(racing_surface));
	METALLIC = 0.25;
	ROUGHNESS = 0.6;
	EMISSION = ALBEDO * 0.12;
}
