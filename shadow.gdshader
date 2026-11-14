shader_type canvas_item;
// Силуэт предмета для тени от солнца. Цвет общий, прозрачность задаёт группа теней.

uniform vec3 shadow_rgb = vec3(0.30, 0.24, 0.48);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(shadow_rgb, a > 0.6 ? 1.0 : 0.0);
}
