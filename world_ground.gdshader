shader_type canvas_item;
// Земля большого мира: по карте биомов (1 тексель = 16 пикселей мира) выбирается плитка биома.
// Границы биомов и дорог «рваные» пиксельным шумом, чтобы не было ступенек.

uniform sampler2D biome_map : filter_nearest;
uniform vec2 world_origin;
uniform vec2 world_size;
uniform float cell = 16.0;
uniform sampler2D atlas : filter_nearest, repeat_enable;
uniform float nb = 17.0;
uniform sampler2D troad : filter_nearest, repeat_enable;
uniform sampler2D road_map : filter_linear;   // расстояние до края дороги (см. world_data.gd road_value)

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

vec3 tile(int b, vec2 uv) {
	vec2 f = fract(uv);
	return texture(atlas, vec2(f.x, (f.y + float(b)) / nb)).rgb;
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	return length(p - (a + ab * t));
}

void fragment() {
	vec2 p = floor(wp);
	// сдвиг выборки: крупный волнистый + мелкий «зубчатый» по блокам 2x2
	vec2 p2 = floor(p / 2.0);
	vec2 jw = (vec2(vnoise(p / 37.0), vnoise(p / 41.0 + 9.0)) - 0.5) * cell * 1.6;
	vec2 j = jw + (vec2(hash(p2), hash(p2 + 31.7)) - 0.5) * cell * 1.3;
	vec2 uv = (p + j - world_origin) / world_size;
	vec4 m = texture(biome_map, uv);
	int b = int(m.r * 255.0 + 0.5);
	vec2 tuv = (p + 0.5) / 256.0;
	vec3 c = tile(b, tuv);
	// дорога: расстояние из карты дорог (как road_value в world_data.gd), края волнистые, кромка темнее
	float d = texture(road_map, (p + 0.5 - world_origin) / world_size).r * 128.0 - 32.0;
	d += sin(p.x * 0.05) * 3.0 + cos(p.y * 0.043) * 3.0 + (hash(p2) - 0.5) * 1.6;
	if (d < 0.0) {
		c = texture(troad, tuv).rgb;
		if (d > -2.5) c *= 0.72;
		else if (d > -5.0) c *= 0.88;
	} else if (d < 2.5 && hash(p2 + 7.0) < 0.55) {
		// травинки нависают над краем дороги
		c *= 1.08;
	}
	// лёгкие пятна света и тени на больших расстояниях, чтобы плитка не повторялась
	float big = vnoise(p / 230.0) * 0.6 + vnoise(p / 90.0) * 0.4;
	c *= 0.94 + big * 0.12;
	COLOR = vec4(c, 1.0);
}
