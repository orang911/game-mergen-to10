shader_type canvas_item;
render_mode unshaded;

const int MAX_BLOCKS = 25;

uniform int block_count = 0;
uniform vec2 block_centers[MAX_BLOCKS];
uniform vec2 block_half_sizes[MAX_BLOCKS];
uniform float block_opacities[MAX_BLOCKS];

uniform vec2 canvas_size = vec2(600.0, 600.0);
uniform vec2 shadow_offset = vec2(3.0, 6.0);
uniform float corner_radius = 18.0;
uniform float softness = 3.5;
uniform vec4 shadow_color : source_color = vec4(0.025, 0.045, 0.09, 0.28);


float rounded_box_sdf(vec2 point, vec2 half_size, float radius) {
	vec2 q = abs(point) - half_size + vec2(radius);
	return min(max(q.x, q.y), 0.0) + length(max(q, vec2(0.0))) - radius;
}


void fragment() {
	vec2 pixel_position = UV * canvas_size;
	float union_coverage = 0.0;

	for (int index = 0; index < MAX_BLOCKS; index++) {
		if (index >= block_count) {
			break;
		}
		vec2 half_size = block_half_sizes[index];
		float radius = min(corner_radius, min(half_size.x, half_size.y) - 0.5);
		float distance_to_shadow = rounded_box_sdf(
			pixel_position - block_centers[index] - shadow_offset,
			half_size,
			radius
		);
		float coverage = 1.0 - smoothstep(-softness, softness, distance_to_shadow);
		union_coverage = max(union_coverage, coverage * block_opacities[index]);
	}

	COLOR = vec4(shadow_color.rgb, shadow_color.a * union_coverage);
}
