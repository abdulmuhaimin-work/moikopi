shader_type canvas_item;

// Soft neon glow: brightens and softens edges. Use on power bar, buttons, or labels.
uniform float glow_power : hint_range(0.0, 2.0) = 1.2;
uniform vec4 glow_color : source_color = vec4(0.0, 0.9, 1.0, 0.6);

void fragment() {
	// Use node color (e.g. ColorRect). For textured nodes, base comes from texture.
	vec4 base = COLOR;
	float a = base.a;
	vec3 blended = mix(base.rgb, glow_color.rgb, glow_color.a * 0.5);
	blended *= glow_power;
	COLOR = vec4(blended, a);
}
