shader_type canvas_item;

// Used by complete claimed sign-in cards. Keep the original alpha and value
// structure while removing hue so the card reads as one disabled state.
uniform float saturation : hint_range(0.0, 1.0) = 0.0;
uniform float brightness : hint_range(0.0, 1.0) = 0.72;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = mix(vec3(luminance), source.rgb, saturation) * brightness;
	COLOR = vec4(grayscale, source.a);
}
