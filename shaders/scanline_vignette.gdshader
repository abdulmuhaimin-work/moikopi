shader_type canvas_item;

// Multiply blend: we output (1,1,1) = no change, (0,0,0) = full dark.
render_mode blend_mul, unshaded;

// 0 = no effect, 1 = full vignette/scanlines
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.12;
uniform float scanline_freq : hint_range(50.0, 400.0) = 180.0;

void fragment() {
	vec2 uv = UV;
	vec2 c = uv - 0.5;
	float d = length(c) * 2.0;
	// Vignette: darken toward edges
	float vignette = 1.0 - vignette_strength * smoothstep(0.4, 1.4, d);

	// Scanlines: thin horizontal dark lines (CRT / synthwave)
	float scan = sin(uv.y * scanline_freq) * 0.5 + 0.5;
	float scanline = 1.0 - scanline_strength * (1.0 - scan);

	float m = vignette * scanline;
	COLOR = vec4(m, m, m, 1.0);
}
