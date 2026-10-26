shader_type spatial;
render_mode unshaded;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec3 p = normalize(local_position);
	float longitude = atan(p.z, p.x);
	float latitude = p.y;
	float turbulence = sin(longitude * 13.0 + latitude * 42.0) * 0.015 + sin(longitude * 29.0 - latitude * 60.0) * 0.008;
	float bands = sin((latitude + turbulence) * 46.0);
	float filaments = sin((latitude + turbulence * 0.5) * 180.0) * 0.06;
	vec3 cloud = mix(vec3(0.38, 0.16, 0.075), vec3(0.94, 0.77, 0.51), smoothstep(-0.65, 0.65, bands) + filaments);
	// One fixed storm longitude, aligned with the course's quarter-lap viewpoint.
	float storm_longitude = atan(sin(longitude + 1.5707963), cos(longitude + 1.5707963));
	vec2 storm = vec2(storm_longitude / 0.30, (latitude - 0.55) / 0.12);
	float radius = length(storm);
	float swirl = sin(radius * 25.0 - atan(storm.y, storm.x) * 3.0);
	vec3 storm_color = mix(vec3(0.22, 0.006, 0.003), vec3(0.7, 0.09, 0.025), 0.55 + swirl * 0.25);
	cloud = mix(cloud, storm_color, 1.0 - smoothstep(0.85, 1.08, radius));
	float light = 0.55 + 0.45 * max(dot(p, normalize(vec3(0.7, 0.8, -0.6))), 0.0);
	ALBEDO = cloud * light;
}
