shader_type canvas_item;
render_mode blend_add;
// Солнечные блики на морском дне: сетка светлых прожилок, медленно плывёт. Пиксели 2x2.

uniform float strength = 0.22;

varying vec2 wp;

void vertex() {
	wp = VERTEX;
}

vec2 h2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// расстояние до границы ячеек Вороного — светлые нити там, где ячейки сходятся
float vor(vec2 p, float t) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = h2(i + g);
			o = 0.5 + 0.45 * sin(t * 0.6 + 6.2831 * o);
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return d2 - d1;
}

void fragment() {
	vec2 p = floor(wp / 2.0) * 2.0;
	float v = vor(p / 46.0, TIME) ;
	float v2 = vor(p / 31.0 + 3.7, TIME * 1.3);
	float l = smoothstep(0.12, 0.0, v) * 0.7 + smoothstep(0.1, 0.0, v2) * 0.5;
	l = floor(l * 3.0) / 3.0;
	COLOR = vec4(vec3(0.55, 0.85, 0.95) * l * strength, 1.0);
}
