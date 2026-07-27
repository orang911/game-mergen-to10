shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 tail_color : source_color = vec4(0.05, 0.22, 0.88, 1.0);
uniform vec4 middle_color : source_color = vec4(0.05, 0.78, 1.0, 1.0);
uniform vec4 head_color : source_color = vec4(0.82, 0.97, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.5) = 0.92;
uniform float flow_speed : hint_range(0.0, 8.0) = 2.8;
uniform float distortion_strength : hint_range(0.0, 0.15) = 0.038;
uniform float distortion_scale : hint_range(1.0, 20.0) = 7.0;
uniform bool use_texture_alpha = false;
uniform float black_cutoff : hint_range(0.0, 0.3) = 0.025;
uniform float tail_softness : hint_range(0.01, 0.5) = 0.16;
uniform float head_softness : hint_range(0.01, 0.3) = 0.10;
uniform float body_thickness : hint_range(0.0, 0.05) = 0.014;


float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}


void fragment() {
	vec2 uv = UV;
	float time = TIME * flow_speed;
	float tail_weight = mix(1.0, 0.30, UV.x);
	float noise_a = value_noise(vec2(UV.x * distortion_scale - time, UV.y * 3.5 + time * 0.35));
	float noise_b = value_noise(vec2(UV.x * distortion_scale * 1.8 + time * 0.7, UV.y * 6.0 - time * 0.22));
	float wave = sin(UV.x * 15.0 - time * 2.2 + noise_b * 4.0);
	uv.y += ((noise_a - 0.5) * 1.35 + wave * 0.24) * distortion_strength * tail_weight;
	uv.x += (noise_b - 0.5) * distortion_strength * 0.24;
	uv = clamp(uv, vec2(0.001), vec2(0.999));

	vec4 source = texture(TEXTURE, uv);
	vec3 source_rgb = source.rgb;
	float luminance = dot(source_rgb, vec3(0.299, 0.587, 0.114));
	// Two nearby samples gently dilate the ribbon after it is scaled down. Ice
	// uses luminance keying, while RGBA-authored trails such as poison use alpha.
	vec4 upper_source = texture(TEXTURE, uv + vec2(0.0, body_thickness));
	vec4 lower_source = texture(TEXTURE, uv - vec2(0.0, body_thickness));
	float upper_luminance = dot(upper_source.rgb, vec3(0.299, 0.587, 0.114));
	float lower_luminance = dot(lower_source.rgb, vec3(0.299, 0.587, 0.114));
	luminance = max(luminance, max(upper_luminance, lower_luminance) * 0.72);
	float keyed_alpha = smoothstep(black_cutoff, 0.68, luminance);
	if (use_texture_alpha) {
		float source_alpha = max(source.a, max(upper_source.a, lower_source.a) * 0.72);
		keyed_alpha = smoothstep(0.02, 0.85, source_alpha);
	}
	float tail_fade = smoothstep(0.0, tail_softness, UV.x);
	// Fade the head-side edge from fully visible to transparent before it reaches
	// the texture boundary. This removes the vertical cut that can flash beside
	// the orb while the distance-based trail is changing length.
	float head_fade = 1.0 - smoothstep(1.0 - head_softness, 1.0, UV.x);
	float vertical_fade = smoothstep(0.0, 0.10, UV.y) * (1.0 - smoothstep(0.90, 1.0, UV.y));

	vec3 gradient = mix(tail_color.rgb, middle_color.rgb, smoothstep(0.02, 0.58, UV.x));
	gradient = mix(gradient, head_color.rgb, smoothstep(0.58, 1.0, UV.x));
	float brightness = mix(0.52, 1.22, smoothstep(0.02, 0.92, luminance));
	float alpha = keyed_alpha * tail_fade * head_fade * vertical_fade * opacity * COLOR.a;
	COLOR = vec4(gradient * brightness, alpha);
}
