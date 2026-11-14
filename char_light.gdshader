shader_type canvas_item;
// Солнце на персонаже: тёплая подсветка края со стороны солнца,
// дальняя сторона чуть темнее, на закате общий тёплый оттенок.
// Тени от деревьев и домов: сетка 8x3 (по высоте и ширине тела), считается в main.gd.

uniform float sun_x = 0.5;        // -1 солнце слева, 1 справа
uniform float elevation = 1.0;    // высота солнца 0..1
uniform float strength = 1.0;     // 0 ночью
uniform float golden = 0.0;       // утро/вечер
uniform vec4 sun_color : source_color = vec4(1.0, 0.88, 0.66, 1.0);
uniform vec2 frames = vec2(6.0, 4.0);
uniform float shade[24];          // 1 — точка в тени
uniform float shade_k = 0.0;      // сила теней (0 ночью)
uniform vec4 shadow_tint : source_color = vec4(0.62, 0.56, 0.80, 1.0);
// режим «кусочек кадра» (слой лица): где этот кусочек лежит в кадре тела
uniform bool region_mode = false;
uniform vec2 reg_uv_pos = vec2(0.0);
uniform vec2 reg_uv_size = vec2(1.0);
uniform vec2 reg_body_px = vec2(0.0);
uniform vec2 reg_px_size = vec2(1.0);
uniform bool reg_flip = false;
// ветер: волосы и плащ — отдельные слои (art/<имя>_hair.png, _cape.png из tools/wind_mask_gen.gd), качаются целиком
global uniform float wind_force;
global uniform float wind_dir;
uniform float frame_w = 80.0;     // ширина кадра листа (у слоёв волос/плаща шире — с полями)
uniform int wind_part = 0;
// стыд: кожа головы краснеет сама (0 — нет, 1 — пунцовая), ниже blush_ymax (низ шеи в кадре) не трогаем
uniform float blush = 0.0;
uniform float sick = 0.0;               // тошнит: кожа лица зеленеет
uniform float blush_ymax = 40.0;        // 0 — не качается (тело), 1 — волосы, 2 — плащ (отдельные слои-листы)

varying float wind_phase;

void vertex() {
	wind_phase = MODEL_MATRIX[3].x * 0.043 + MODEL_MATRIX[3].y * 0.021;
}

float shade_at(float row, float col) {
	int r = int(clamp(row, 0.0, 7.0));
	int c = int(clamp(col, 0.0, 2.0));
	return shade[r * 3 + c];
}

void fragment() {
	vec2 uvs = UV;
	if (!region_mode && wind_part > 0) {
		// каждая строка слоя сдвигается по ветру: у корня почти нет, к концу сильнее;
		// порыв бежит вдоль пряди/плаща волной
		vec2 ts = TEXTURE_PIXEL_SIZE;
		float y = fract(UV.y * frames.y) * 160.0;
		float f = wind_force;
		float tm = TIME * (1.7 + f * 3.4) + wind_phase;
		float wave = sin(tm - y * 0.085) * 0.65 + sin(tm * 1.9 - y * 0.15 + 1.3) * 0.35;
		float lean = wind_dir * f;
		float flut = wave * (0.12 + 0.95 * f);
		float d = 0.0;
		if (wind_part == 1) {
			d = (lean * 6.0 + flut * 3.6) * pow(clamp((y - 24.0) / 48.0, 0.0, 1.0), 1.4);
		} else {
			d = (lean * 6.5 + flut * 3.6) * pow(clamp((y - 40.0) / 118.0, 0.0, 1.0), 1.1);
			// плащ раздувается: край по ветру улетает дальше, край против ветра держится ближе к телу
			float lx = fract(UV.x * frames.x) * frame_w - 48.0;
			float side = clamp((lx - 40.0) / 24.0, -1.0, 1.0) * (wind_dir >= 0.0 ? 1.0 : -1.0);
			d *= 0.35 + 0.65 * (side * 0.5 + 0.5);
		}
		float cell0 = floor(UV.x * frames.x) / frames.x;
		float cell1 = cell0 + 1.0 / frames.x - ts.x;
		uvs.x = clamp(UV.x - round(d) * ts.x, cell0, cell1);
	}
	vec4 c = texture(TEXTURE, uvs);
	vec3 col = c.rgb;
	if (c.a > 0.01) {
		vec2 local = fract(UV * frames);
		if (region_mode) {
			vec2 lu = (UV - reg_uv_pos) / reg_uv_size;
			if (reg_flip) lu.x = 1.0 - lu.x;
			local = (reg_body_px + lu * reg_px_size) / vec2(80.0, 160.0);
		}
		if (blush > 0.001 || sick > 0.001) {
			// кожа: тёплая, зелёный почти как синий (у русых волос зелёный заметно выше синего)
			float ly = local.y * 160.0;
			bool skin = c.r > 0.45 && c.r >= c.g && (c.r - c.b) > 0.06 && (c.g - c.b) < 0.10;
			if (skin && ly < blush_ymax) {
				// всё лицо розовеет ровно, без усиления на щеках и подбородке
				float k = clamp(blush, 0.0, 1.0) * 0.85;
				vec3 pink = vec3(min(col.r * 1.02 + 0.03, 1.0), col.g * 0.6, col.b * 0.74 + 0.02);
				col = mix(col, pink, k * step(0.001, blush));
				// тошнота: бледно-зелёная кожа
				vec3 green = vec3(col.r * 0.80, min(col.g * 1.02 + 0.02, 1.0), col.b * 0.62);
				col = mix(col, green, clamp(sick, 0.0, 1.0) * 0.8);
			}
		}
		// какая точка сетки: высота над стопой и сдвиг от центра (в пикселях мира)
		float h = (157.0 - local.y * 160.0) * 0.5;
		float dx = (local.x - 0.5) * frame_w * 0.5;
		float fr = clamp((74.0 - h) / 71.0 * 7.0, 0.0, 7.0);
		float fc = clamp(dx / 7.0 + 1.0, 0.0, 2.0);
		float r0 = floor(fr);
		float c0 = floor(fc);
		float tr = fr - r0;
		float tc = fc - c0;
		float s = mix(mix(shade_at(r0, c0), shade_at(r0, c0 + 1.0), tc), mix(shade_at(r0 + 1.0, c0), shade_at(r0 + 1.0, c0 + 1.0), tc), tr);
		float lit = 1.0 - s;
		if (strength > 0.001) {
			vec2 ts = TEXTURE_PIXEL_SIZE;
			float sx = sun_x >= 0.0 ? 1.0 : -1.0;
			float side_rim = 0.0;
			if (texture(TEXTURE, uvs + vec2(sx * ts.x * 2.0, 0.0)).a < 0.5) side_rim = 1.0;
			else if (texture(TEXTURE, uvs + vec2(sx * ts.x * 3.0, 0.0)).a < 0.5) side_rim = 0.45;
			float top_rim = 0.0;
			if (texture(TEXTURE, uvs + vec2(0.0, -ts.y * 2.0)).a < 0.5) top_rim = 1.0;
			float lum = dot(c.rgb, vec3(0.3, 0.59, 0.11));
			float rim = max(side_rim * clamp(abs(sun_x) * 1.3, 0.0, 1.0), top_rim * elevation * 0.7);
			if (lum < 0.2 || region_mode) rim = 0.0;
			col = mix(col, min(col * sun_color.rgb * 1.3 + vec3(0.07), vec3(1.0)), rim * 0.78 * strength * lit);
			float toward = (local.x - 0.5) * sx;
			col *= 1.0 - strength * 0.22 * clamp(-toward * 2.4, 0.0, 1.0) * clamp(abs(sun_x) * 1.5, 0.3, 1.0);
			col = mix(col, col * sun_color.rgb * 1.08, golden * 0.35 * strength * lit);
		}
		// тень от предмета — тот же сиреневый, что и тени на земле
		col = mix(col, col * shadow_tint.rgb, s * shade_k * 0.75);
	}
	COLOR = vec4(col, c.a) * COLOR;
}
