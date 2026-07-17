shader_type canvas_item;

uniform float arrival_flash : hint_range(0.0, 1.0) = 0.0;
uniform float full_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float shimmer_offset = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float shimmer = smoothstep(0.0, 0.16, 0.16 - abs(fract(UV.x + shimmer_offset) - 0.5));
	float flash = arrival_flash * smoothstep(0.4, 1.0, UV.x);
	vec3 tint = mix(vec3(0.15, 0.92, 0.90), vec3(0.40, 0.72, 1.0), UV.x);
	vec3 color = tex.rgb * tint + vec3(0.35, 0.78, 1.0) * shimmer * 0.35;
	color += vec3(0.72, 0.92, 1.0) * (flash + full_pulse * 0.35);
	COLOR = vec4(color, tex.a);
}
