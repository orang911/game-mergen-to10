shader_type canvas_item;

// A soft after-image for blocks that are pulled into the clicked block.
// The source texture remains recognizable while the edge/radial falloff
// keeps the effect light enough for a busy board.
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.82, 0.92, 1.0, 1.0);
uniform vec4 source_modulate : source_color = vec4(1.0);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float edge_alpha = smoothstep(0.0, 0.12, edge_distance);
	float radial_alpha = 1.0 - smoothstep(0.35, 0.78, distance(UV, vec2(0.5)));
	float alpha = source.a * source_modulate.a * fade * edge_alpha * (0.72 + radial_alpha * 0.28);
	vec3 color = mix(source.rgb * source_modulate.rgb, tint.rgb, 0.18);
	COLOR = vec4(color, alpha);
}
