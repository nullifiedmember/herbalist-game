shader_type canvas_item;
// Море у южного берега: мокрый песок, накатывающая плёнка воды с пеной, полосы волн к берегу,
// цвет от бирюзового на мели до синего на глубине, блики. Всё по пиксельной сетке 2x2.

uniform float shore_y = 7690.0;

varying vec2 wp;

void vertex() {
	wp = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float shore(float x) {
	return shore_y + sin(x * 0.0041) * 38.0 + sin(x * 0.0113 + 1.3) * 16.0 + sin(x * 0.031 + 0.4) * 4.0;
}

void fragment() {
	vec2 p = floor(wp / 2.0) * 2.0;
	float t = TIME;
	float d = p.y - shore(p.x);
	// накат: край воды бегает вперёд-назад
	float surge = (sin(t * 0.55 + p.x * 0.0037) * 0.5 + 0.5) * 26.0 + (vnoise(vec2(p.x * 0.05, t * 0.4)) - 0.5) * 6.0;
	float edge = -surge;
	if (d < edge - 30.0) {
		discard;
	}
	vec4 col;
	if (d < edge) {
		// мокрый песок: темнее и чуть блестит, к суше сходит на нет
		float k = clamp((d - (edge - 30.0)) / 30.0, 0.0, 1.0);
		col = vec4(0.32, 0.26, 0.16, 0.24 * k);
		if (hash(p + floor(t * 2.0)) > 0.995) col = vec4(1.0, 1.0, 0.95, 0.5 * k);
	} else {
		float dd = max(d, 0.0);
		vec3 shallow = vec3(0.42, 0.78, 0.80);
		vec3 mid = vec3(0.20, 0.55, 0.72);
		vec3 deep = vec3(0.10, 0.30, 0.52);
		vec3 c = mix(shallow, mid, smoothstep(0.0, 160.0, dd));
		c = mix(c, deep, smoothstep(140.0, 900.0, dd));
		// пятна глубины и ряби
		float n = vnoise(p / 70.0 + vec2(t * 0.05, 0.0)) * 0.6 + vnoise(p / 23.0 - vec2(0.0, t * 0.08)) * 0.4;
		c *= 0.9 + n * 0.16;
		// гребни волн бегут к берегу
		float wv = sin(dd * 0.055 + t * 1.6 + vnoise(p / 90.0) * 5.0);
		float mask = vnoise(vec2(p.x / 40.0, dd / 30.0 + t * 0.2));
		float wv2 = sin(dd * 0.055 + t * 1.6 + vnoise(p / 90.0) * 5.0 - 0.18);
		if (wv > 0.985 && wv2 < wv && mask > 0.5) c = mix(c, vec3(0.86, 0.96, 0.99), 0.6);
		else if (wv > 0.95 && mask > 0.42) c = mix(c, vec3(0.62, 0.86, 0.92), 0.28);
		// пена у кромки
		float fw = 5.0 + vnoise(vec2(p.x * 0.06, t)) * 6.0;
		float fd = d - edge;
		if (fd < fw) {
			float br = vnoise(p / 6.0 + vec2(t * 0.7, 0.0));
			if (br > 0.32 || fd < 2.0) c = mix(c, vec3(0.97, 0.99, 1.0), fd < 2.0 ? 0.95 : 0.75);
		} else if (fd < fw + 6.0 && vnoise(p / 5.0 - vec2(t, 0.0)) > 0.72) {
			c = mix(c, vec3(0.9, 0.97, 1.0), 0.5);
		}
		// блики солнца
		vec2 cell = floor(p / 6.0);
		float sp = hash(cell + floor(t * 1.5 + hash(cell) * 7.0));
		if (sp > 0.992 && dd > 40.0) c = vec3(1.0, 1.0, 0.96);
		float a = fd < 3.0 ? 0.92 : 1.0;
		col = vec4(c, a);
	}
	COLOR = col;
}
