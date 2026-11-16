shader_type canvas_item;
// v32: улицы городов — точно как дороги мира (world_ground.gdshader): та же плитка wt_road,
// волнистый «рваный» край, кромка темнее (×0.72 / ×0.88), лёгкие большие пятна света.
// Линия (Line2D со STRETCH-текстурой) знает расстояние до края по UV.y; площадь — по эллипсу.
// mode 0 — край и всё покрытие; mode 1 — только середина (закрывает кромки на перекрёстках).

uniform sampler2D troad : filter_nearest, repeat_enable;
uniform float lw = 36.0;
uniform int mode = 0;
uniform bool plaza = false;
uniform vec2 pc;
uniform vec2 pr = vec2(170.0, 125.0);

varying vec2 wp;
varying vec2 uvv;

void vertex() {
	wp = VERTEX;
	uvv = UV;
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

void fragment() {
	vec2 p = floor(wp);
	vec2 p2 = floor(p / 2.0);
	float dist;
	if (plaza) {
		vec2 q = (p + 0.5 - pc) / pr;
		dist = (1.0 - length(q)) * min(pr.x, pr.y);
	} else {
		dist = min(uvv.y, 1.0 - uvv.y) * lw;
	}
	float d = dist - 6.0 + sin(p.x * 0.05) * 3.0 + cos(p.y * 0.043) * 3.0 + (hash(p2) - 0.5) * 1.6;
	if (d < 0.0 || (mode == 1 && d < 6.0)) {
		discard;
	}
	vec3 c = texture(troad, (p + 0.5) / 256.0).rgb;
	if (d < 2.5) c *= 0.72;
	else if (d < 5.0) c *= 0.88;
	float big = vnoise(p / 230.0) * 0.6 + vnoise(p / 90.0) * 0.4;
	c *= 0.94 + big * 0.12;
	COLOR = vec4(c, 1.0);
}
