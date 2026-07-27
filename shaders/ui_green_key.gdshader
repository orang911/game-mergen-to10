shader_type canvas_item;
render_mode unshaded;

uniform float similarity = 0.28;
uniform float smoothness = 0.18;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float green_dominance = source.g - max(source.r, source.b);
	float keyed = smoothstep(similarity - smoothness, similarity + smoothness, green_dominance);
	source.a *= 1.0 - keyed;
	COLOR = source;
}
