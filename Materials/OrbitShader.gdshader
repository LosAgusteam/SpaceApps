shader_type spatial;

float circle(vec2 position, float radius, float feather) {
	return smoothstep(radius, radius + feather, dot(position, position) * 4.0);
}

void fragment() {
	float dist = length(UV - vec2(0.5));
	float radius = 0.5;
	float line_width = 0.01;
	vec3 line_color = vec3( 1.0, 1.0, 0.0 );

	if (dist > radius - line_width && dist < radius) {
		circle(UV, radius, 0.005);
		ALBEDO = line_color;
	} else {
		ALPHA = 0.0;
	}
}