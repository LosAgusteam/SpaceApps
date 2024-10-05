shader_type spatial;
render_mode cull_disabled;

uniform float line_width = 0.0025;
uniform vec3 line_color = vec3( 1.0, 1.0, 1.0 );

float circle(vec2 position, float radius, float feather) {
	return smoothstep(radius, radius + feather, dot(position, position) * 4.0);
}

void fragment() {
	float dist = length(UV - vec2(0.5));
	float radius = 0.5;

	if (dist > radius - line_width && dist < radius) {
		circle(UV, radius, 0.005);
		ALBEDO = line_color * vec3(10);
	} else {
		ALPHA = 0.0;
	}
}