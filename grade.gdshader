shader_type canvas_item;
// «Ламповая» цветокоррекция: мягкие пастельные цвета, тёплое свечение со стороны солнца, виньетка.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 sun_color = vec3(1.0, 0.86, 0.62);
uniform vec2 sun_pos = vec2(0.5, -0.3);
uniform float sun_glow = 0.18;
uniform float vignette = 0.32;
uniform float pastel = 0.12;
uniform vec3 lift = vec3(0.10, 0.07, 0.13);

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), pastel * 0.6);
	c = c * (1.0 - pastel) + lift * pastel * 2.2;
	vec2 asp = vec2(1.78, 1.0);
	float d = distance(SCREEN_UV * asp, sun_pos * asp);
	c += sun_color * sun_glow * exp(-d * 1.5);
	float v = smoothstep(1.08, 0.32, length((SCREEN_UV - 0.5) * vec2(1.2, 1.0)));
	c *= mix(1.0, v, vignette);
	COLOR = vec4(c, 1.0);
}
