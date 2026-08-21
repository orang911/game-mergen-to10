shader_type canvas_item;

uniform float saturation : hint_range(0.0, 1.0) = 0.08;
uniform float brightness : hint_range(0.0, 1.0) = 0.58;

void fragment() {
	vec4 tint = COLOR;
	vec4 tex = texture(TEXTURE, UV);
	float luminance = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 muted = mix(vec3(luminance), tex.rgb, saturation) * brightness;
	COLOR = vec4(muted, tex.a) * tint;
}
