shader_type canvas_item;
// Мостовая и тропинки городов: текстура лежит «в мире», поэтому на перекрёстках
// улицы сливаются без швов. tint — свой цвет камня у каждой земли.

uniform sampler2D cob : filter_nearest, repeat_enable;
uniform float size = 64.0;
uniform vec4 tint : source_color = vec4(1.0);

varying vec2 wp;

void vertex() {
	wp = VERTEX;
}

void fragment() {
	vec2 p = floor(wp);
	COLOR = texture(cob, p / size) * tint;
}
