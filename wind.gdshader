shader_type canvas_item;
// Лёгкое покачивание на ветру: верх спрайта качается, низ стоит.
// (Сильный переменный ветер отключён 2026-11-11, его версия лежит в wind_storm_backup.gdshader.txt)

uniform float strength = 1.0;
uniform float speed = 1.4;

void vertex() {
	float phase = (MODEL_MATRIX[3].x * 0.031) + (MODEL_MATRIX[3].y * 0.017);
	float t = TIME * speed + phase;
	float sway = sin(t) * 0.7 + sin(t * 2.3 + 1.7) * 0.3;
	VERTEX.x += sway * strength * (1.0 - UV.y);
}
