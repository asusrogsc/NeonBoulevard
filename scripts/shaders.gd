class_name Shaders
extends RefCounted
## Matières procédurales (aucune image) : briques, crépi, béton, asphalte, dalles,
## fenêtres avec pièce en perspective (« interior mapping »), rideau métallique, tôle ondulée,
## carrelage. Toutes utilisent la position dans le monde : pas de déformation, pas de raccord visible.

static var _cache := {}
static var _noise: NoiseTexture2D = null


static func noise() -> NoiseTexture2D:
	if _noise == null:
		var n := FastNoiseLite.new()
		n.seed = 77
		n.frequency = 0.012
		n.fractal_octaves = 5
		_noise = NoiseTexture2D.new()
		_noise.width = 512
		_noise.height = 512
		_noise.seamless = true
		_noise.noise = n
		_noise.generate_mipmaps = true
	return _noise


static func shader(name: String) -> Shader:
	if not _cache.has(name):
		var sh := Shader.new()
		sh.code = COMMON + CODES[name]
		_cache[name] = sh
	return _cache[name]


## Matériau prêt à l'emploi : mat("wall", {"brick_a": Color(...), ...})
static func mat(name: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(name)
	m.set_shader_parameter("noise_tex", noise())
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


const COMMON := """
shader_type spatial;
"""

const HELPERS := """
uniform sampler2D noise_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
varying vec3 wpos;
varying vec3 wnrm;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float nz(vec2 p) { return texture(noise_tex, p).r; }
// normale perturbée (bump) exprimée dans l'espace vue
vec3 bumped(vec3 n, vec3 tx, vec3 ty, vec2 b, mat4 view) {
	vec3 wn = normalize(n - tx * b.x - ty * b.y);
	return normalize((view * vec4(wn, 0.0)).xyz);
}
// ronds de pluie (flaques)
vec2 ripples(vec2 w, float t) {
	vec2 n = vec2(0.0);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			vec2 cell = floor(w) + vec2(float(i), float(j));
			float h = hash(cell);
			float k = fract(t * 0.8 + h);
			vec2 c = cell + vec2(hash(cell + 3.1), hash(cell + 7.7));
			vec2 d = w - c;
			float r = length(d);
			float front = k * 0.9;
			float a = exp(-pow((r - front) * 12.0, 2.0)) * (1.0 - k);
			n += d / max(r, 0.001) * a * cos((r - front) * 40.0);
		}
	}
	return n;
}
"""

const VERT_WORLD := """
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
"""

const CODES := {
	# ---------------------------------------------------------------- MURS
	"wall": HELPERS + VERT_WORLD + """
uniform vec3 brick_a : source_color = vec3(0.42, 0.18, 0.15);
uniform vec3 brick_b : source_color = vec3(0.28, 0.12, 0.11);
uniform vec3 mortar : source_color = vec3(0.32, 0.30, 0.30);
uniform int style = 0; // 0 briques, 1 crépi, 2 béton en panneaux
uniform vec2 brick = vec2(0.72, 0.26);
uniform float wet = 0.7;
void fragment() {
	bool front = abs(wnrm.z) >= abs(wnrm.x);
	vec2 p = front ? wpos.xy : wpos.zy;
	vec3 tx = front ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec3 ty = vec3(0.0, 1.0, 0.0);
	if (abs(wnrm.y) > 0.6) { p = wpos.xz; tx = vec3(1.0, 0.0, 0.0); ty = vec3(0.0, 0.0, 1.0); }
	float n1 = nz(p * 0.021);
	float n2 = nz(p * 0.13 + 0.37);
	float n3 = nz(p * 0.9 + 0.11);
	vec3 col;
	float rough = 0.85;
	vec2 bump = vec2(0.0);
	if (style == 0) {
		vec2 b = p / brick;
		float row = floor(b.y);
		b.x += mod(row, 2.0) * 0.5;
		vec2 id = floor(b);
		vec2 f = fract(b);
		float h = hash(id);
		col = mix(brick_a, brick_b, h) * (0.8 + 0.4 * n3) * (0.9 + 0.2 * hash(id + 9.1));
		vec2 m = min(f, 1.0 - f) * brick;
		float edge = min(m.x, m.y);
		float mort = 1.0 - smoothstep(0.014, 0.032, edge);
		col = mix(col, mortar * (0.75 + 0.4 * n3), mort);
		vec2 g = vec2(f.x < 0.5 ? 1.0 : -1.0, f.y < 0.5 ? 1.0 : -1.0);
		bump = (m.x < m.y ? vec2(g.x, 0.0) : vec2(0.0, g.y)) * mort * 0.55;
		bump += (vec2(n3, nz(p * 0.9 + 0.6)) - 0.5) * 0.25;
		rough = mix(0.78, 0.95, mort);
	} else if (style == 1) {
		col = brick_a * (0.78 + 0.35 * n2) * (0.9 + 0.2 * n3);
		bump = (vec2(n3, nz(p * 0.9 + 0.5)) - 0.5) * 0.6;
		float joint = 1.0 - smoothstep(0.0, 0.03, abs(fract(p.y / 3.9) - 0.02) * 3.9);
		col *= 1.0 - joint * 0.35;
		rough = 0.9;
	} else {
		vec2 pan = vec2(3.2, 3.9);
		vec2 f = fract(p / pan);
		vec2 m = min(f, 1.0 - f) * pan;
		float seam = 1.0 - smoothstep(0.02, 0.06, min(m.x, m.y));
		vec2 id = floor(p / pan);
		col = brick_a * (0.85 + 0.25 * hash(id)) * (0.85 + 0.3 * n2);
		col *= 1.0 - seam * 0.5;
		bump = (vec2(n3, nz(p * 0.9 + 0.5)) - 0.5) * 0.35 + vec2(f.x < 0.5 ? 1.0 : -1.0, 0.0) * seam * 0.3;
		rough = 0.88;
	}
	// saleté au pied du mur et coulures de pluie sous les rebords
	float grime = smoothstep(2.6, 0.0, wpos.y) * (0.35 + 0.25 * n1);
	float streak = nz(vec2(p.x * 0.35, p.y * 0.012) + 0.21);
	float rainmark = smoothstep(0.5, 0.78, streak) * 0.5;
	col *= 1.0 - grime - rainmark * 0.45;
	col *= 0.85 + 0.3 * n1;
	ALBEDO = col;
	ROUGHNESS = mix(rough, 0.35, wet * clamp(grime * 1.4 + rainmark, 0.0, 1.0));
	NORMAL = bumped(wnrm, tx, ty, bump, VIEW_MATRIX);
}
""",
	# ---------------------------------------------------------------- ASPHALTE
	"asphalt": HELPERS + VERT_WORLD + """
uniform float wet = 1.0;
uniform float lane_z = 0.8;
uniform float edge_z = -2.85;
uniform vec4 crossings = vec4(-999.0);
void fragment() {
	vec2 p = wpos.xz;
	float n1 = nz(p * 0.018);
	float n2 = nz(p * 0.11 + 0.3);
	float n3 = nz(p * 0.8 + 0.7);
	vec3 col = mix(vec3(0.09, 0.085, 0.1), vec3(0.19, 0.18, 0.2), n2) * (0.8 + 0.4 * n3);
	float sp = hash(floor(p * 24.0));
	col += step(0.94, sp) * 0.06;
	float patch_m = smoothstep(0.66, 0.68, nz(p * 0.01 + 0.73));
	col = mix(col, col * 0.62 + vec3(0.01), patch_m * 0.8);
	float c = abs(nz(p * 0.05 + 0.11) - 0.5);
	float crack = (1.0 - smoothstep(0.003, 0.01, c)) * step(0.48, n1);
	col *= 1.0 - crack * 0.7;
	// marquages : ligne centrale en pointillés, ligne de rive, passages piétons
	float paint = 0.0;
	vec3 pcol = vec3(0.85, 0.72, 0.25);
	if (abs(p.y - lane_z) < 0.11 && fract(p.x / 4.2) < 0.52) paint = 1.0;
	if (abs(p.y - edge_z) < 0.08) { paint = 1.0; pcol = vec3(0.8); }
	for (int i = 0; i < 4; i++) {
		float cx = crossings[i];
		if (abs(p.x - cx) < 2.0 && p.y > edge_z + 0.2 && fract(p.y / 1.25) < 0.55) { paint = 1.0; pcol = vec3(0.85); }
	}
	paint *= smoothstep(0.28, 0.55, n3 * 0.7 + n2 * 0.5);
	col = mix(col, pcol * (0.75 + 0.25 * n3), paint * 0.9);
	// flaques
	float pud = smoothstep(0.6, 0.66, nz(p * 0.035 + 0.53));
	col = mix(col, col * 0.4, pud);
	float rough = mix(0.62, 0.3, wet);
	rough = mix(rough, 0.5, paint);
	rough = mix(rough, 0.02, pud);
	rough = mix(rough, 0.75, crack);
	vec2 b = (vec2(n3, nz(p * 0.8 + 0.2)) - 0.5) * 0.5 * (1.0 - pud);
	b += ripples(p * 1.4, TIME) * 0.6 * pud * wet;
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.55;
	NORMAL = bumped(vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), b, VIEW_MATRIX);
}
""",
	# ---------------------------------------------------------------- DALLES (trottoir, quai)
	"tiles": HELPERS + VERT_WORLD + """
uniform vec3 tile_a : source_color = vec3(0.30, 0.29, 0.31);
uniform vec3 tile_b : source_color = vec3(0.24, 0.23, 0.26);
uniform vec3 grout : source_color = vec3(0.12, 0.12, 0.13);
uniform vec2 tile = vec2(1.4, 1.4);
uniform float wet = 0.8;
uniform float gloss = 0.0;
void fragment() {
	bool flat_up = abs(wnrm.y) > 0.6;
	bool front = abs(wnrm.z) >= abs(wnrm.x);
	vec2 p = flat_up ? wpos.xz : (front ? wpos.xy : wpos.zy);
	vec3 tx = flat_up ? vec3(1.0, 0.0, 0.0) : (front ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0));
	vec3 ty = flat_up ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);
	vec3 nn = flat_up ? vec3(0.0, 1.0, 0.0) : wnrm;
	vec2 id = floor(p / tile);
	vec2 f = fract(p / tile);
	vec2 m = min(f, 1.0 - f) * tile;
	float g = 1.0 - smoothstep(0.02, 0.045, min(m.x, m.y));
	float n2 = nz(p * 0.13 + 0.5);
	float n3 = nz(p * 0.85 + 0.2);
	vec3 col = mix(tile_a, tile_b, hash(id)) * (0.85 + 0.3 * n3) * (0.9 + 0.2 * n2);
	col = mix(col, grout, g);
	float stain = smoothstep(0.6, 0.78, nz(p * 0.04 + 0.9));
	col *= 1.0 - stain * 0.16 * (1.0 - gloss);
	vec2 b = vec2(f.x < 0.5 ? 1.0 : -1.0, f.y < 0.5 ? 1.0 : -1.0) * g * 0.35;
	b += (vec2(n3, nz(p * 0.85 + 0.6)) - 0.5) * 0.3;
	float pud = flat_up ? smoothstep(0.69, 0.74, nz(p * 0.05 + 0.31)) * wet : 0.0;
	col = mix(col, col * 0.75, pud);
	ALBEDO = col;
	ROUGHNESS = mix(mix(mix(0.8, 0.4, wet), 0.12, gloss), 0.03, pud);
	SPECULAR = 0.5 + 0.3 * gloss;
	NORMAL = bumped(nn, tx, ty, b * (1.0 - pud), VIEW_MATRIX);
}
""",
	# ---------------------------------------------------------------- FENÊTRES (pièce en perspective)
	"window": "render_mode cull_disabled;\n" + HELPERS + """
uniform vec2 size = vec2(2.4, 2.8);
uniform float depth = 1.0;
uniform float lit_chance = 0.45;
uniform bool shop = false;
uniform vec3 shop_light : source_color = vec3(1.0, 0.85, 0.7);
varying vec4 seed;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	seed = COLOR;
}
void fragment() {
	vec3 rw = normalize(wpos - CAMERA_POSITION_WORLD);
	vec3 rd = vec3(rw.x / size.x, rw.y / size.y, -rw.z / (size.x * depth));
	vec3 ro = vec3(UV.x, 1.0 - UV.y, 0.0);
	float tx = rd.x > 0.0 ? (1.0 - ro.x) / rd.x : -ro.x / min(rd.x, -1e-5);
	float ty = rd.y > 0.0 ? (1.0 - ro.y) / rd.y : -ro.y / min(rd.y, -1e-5);
	float tz = 1.0 / max(rd.z, 1e-4);
	float t = min(tx, min(ty, tz));
	vec3 h = ro + rd * t;
	float s1 = seed.r;
	float s2 = seed.g;
	float s3 = seed.b;
	vec3 wall = mix(vec3(0.78, 0.62, 0.46), vec3(0.5, 0.6, 0.72), s2);
	vec3 col;
	if (t == tz) {
		col = wall * 0.9;
		if (shop) {
			// étagères chargées de produits au fond de la boutique
			float shelf = step(0.82, fract(h.y * 4.0));
			float prod = step(0.35, hash(floor(vec2(h.x * 18.0, h.y * 4.0)) + s1));
			vec3 pc = vec3(hash(floor(vec2(h.x * 18.0, h.y * 4.0)) + 1.0), hash(floor(vec2(h.x * 18.0, h.y * 4.0)) + 2.0), hash(floor(vec2(h.x * 18.0, h.y * 4.0)) + 3.0));
			col = mix(col, pc * 0.9, prod * (1.0 - shelf) * step(h.y, 0.85) * step(0.12, h.y));
			col = mix(col, vec3(0.25, 0.2, 0.18), shelf);
		} else {
			if (abs(h.x - (0.3 + 0.4 * s3)) < 0.14 && abs(h.y - 0.6) < 0.1) col = mix(vec3(0.6, 0.2, 0.25), vec3(0.2, 0.45, 0.6), s1);
			if (h.y < 0.32 && abs(h.x - 0.5) < 0.3) col = mix(vec3(0.25, 0.18, 0.15), vec3(0.15, 0.2, 0.3), s2);
		}
	} else if (t == ty) {
		col = rd.y > 0.0 ? vec3(0.85, 0.83, 0.78) : vec3(0.38, 0.24, 0.16) * (0.75 + 0.5 * step(0.5, fract(h.x * 6.0)));
		if (shop && rd.y < 0.0) col = vec3(0.6, 0.6, 0.62) * (0.8 + 0.3 * step(0.5, fract(h.x * 4.0 + floor(h.z * 4.0) * 0.5)));
	} else {
		col = wall * 0.72;
	}
	bool lit = shop || s1 < lit_chance;
	vec3 light = shop ? shop_light * 1.6 : mix(vec3(1.0, 0.72, 0.42), vec3(0.75, 0.88, 1.0), step(0.72, s2));
	float fall = 1.0 - 0.45 * clamp(h.z, 0.0, 1.0);
	// plafonnier : tache plus claire au plafond
	if (t == ty && rd.y > 0.0) fall += 0.8 * exp(-pow(length(h.xz - vec2(0.5, 0.5)) * 3.0, 2.0));
	vec3 emis = lit ? col * light * fall * 1.25 : col * 0.012;
	if (!lit && s3 > 0.82) {
		float flick = 0.35 + 0.25 * sin(TIME * 7.0 + s1 * 40.0) * sin(TIME * 3.1 + s2 * 9.0);
		emis = col * vec3(0.3, 0.45, 0.95) * flick;
	}
	if (!shop) {
		if (s3 < 0.45) {
			float cw = 0.18 + 0.18 * s2;
			float curt = max(step(UV.x, cw), step(1.0 - cw, UV.x));
			vec3 cc = mix(vec3(0.72, 0.28, 0.24), vec3(0.88, 0.82, 0.66), s1);
			float folds = 0.75 + 0.25 * sin(UV.x * 70.0);
			emis = mix(emis, cc * folds * (lit ? 0.85 : 0.025), curt);
		} else if (s3 < 0.62) {
			float down = 0.25 + 0.5 * s2;
			float bl = step(UV.y, down) * (0.6 + 0.4 * step(0.4, fract(UV.y * 30.0)));
			emis = mix(emis, (lit ? vec3(0.95, 0.85, 0.62) : vec3(0.02)) * bl, step(UV.y, down));
		}
	}
	// saleté sur la vitre et reflet
	float dirt = nz(wpos.xy * 0.4 + s1) * 0.25;
	ALBEDO = vec3(0.015 + dirt * 0.05);
	EMISSION = emis * (1.0 - dirt * 0.5);
	ROUGHNESS = 0.04 + dirt * 0.3;
	SPECULAR = 0.9;
	METALLIC = 0.0;
}
""",
	# ---------------------------------------------------------------- RIDEAU MÉTALLIQUE / TÔLE ONDULÉE
	"corrugated": HELPERS + VERT_WORLD + """
uniform vec3 base : source_color = vec3(0.45, 0.47, 0.5);
uniform vec3 rust : source_color = vec3(0.35, 0.18, 0.1);
uniform float ribs = 9.0;
uniform bool vertical_ribs = false;
uniform float tags = 1.0;
uniform float metal = 0.6;
void fragment() {
	bool front = abs(wnrm.z) >= abs(wnrm.x);
	vec2 p = front ? wpos.xy : wpos.zy;
	vec3 tx = front ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
	vec3 ty = vec3(0.0, 1.0, 0.0);
	if (abs(wnrm.y) > 0.6) { p = wpos.xz; ty = vec3(0.0, 0.0, 1.0); }
	float coord = vertical_ribs ? p.x : p.y;
	float w = sin(coord * ribs * 6.2832);
	vec2 b = vertical_ribs ? vec2(cos(coord * ribs * 6.2832) * 0.8, 0.0) : vec2(0.0, cos(coord * ribs * 6.2832) * 0.8);
	float n2 = nz(p * 0.11 + 0.4);
	float n3 = nz(p * 0.7 + 0.2);
	vec3 col = base * (0.8 + 0.3 * n3) * (0.92 + 0.08 * w);
	float r = smoothstep(0.55, 0.75, n2 + n3 * 0.3 - (p.y * 0.02));
	col = mix(col, rust * (0.8 + 0.4 * n3), r * 0.8);
	// tags de graffiti
	if (tags > 0.0) {
		float g = nz(p * 0.06 + vec2(3.7, 1.3));
		float tag = smoothstep(0.62, 0.64, g) * step(p.y, 3.4) * step(0.4, p.y);
		vec3 tc = mix(vec3(0.95, 0.2, 0.55), vec3(0.2, 0.85, 0.9), step(0.5, hash(floor(p * 0.2))));
		float outline = smoothstep(0.6, 0.62, g) - tag;
		col = mix(col, tc, tag * tags);
		col = mix(col, vec3(0.02), outline * tags);
	}
	col *= 1.0 - smoothstep(2.0, 0.0, wpos.y) * 0.25;
	ALBEDO = col;
	METALLIC = metal * (1.0 - r);
	ROUGHNESS = mix(0.45, 0.85, r);
	NORMAL = bumped(abs(wnrm.y) > 0.6 ? vec3(0.0, 1.0, 0.0) : wnrm, tx, ty, b, VIEW_MATRIX);
}
""",
	# ---------------------------------------------------------------- EAU DU PORT
	"water": HELPERS + VERT_WORLD + """
uniform vec3 deep : source_color = vec3(0.02, 0.07, 0.1);
void fragment() {
	vec2 p = wpos.xz;
	vec2 a = vec2(nz(p * 0.04 + vec2(TIME * 0.012, TIME * 0.008)), nz(p * 0.04 + vec2(0.5 - TIME * 0.01, 0.3 + TIME * 0.014)));
	vec2 b = vec2(nz(p * 0.15 + vec2(TIME * 0.03, -TIME * 0.02)), nz(p * 0.15 + vec2(0.7 + TIME * 0.025, 0.1)));
	vec2 n = (a - 0.5) * 1.2 + (b - 0.5) * 0.6;
	ALBEDO = deep * (0.8 + 0.4 * a.x);
	ROUGHNESS = 0.03;
	METALLIC = 0.2;
	SPECULAR = 0.8;
	NORMAL = bumped(vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), n, VIEW_MATRIX);
}
""",
	# ---------------------------------------------------------------- MÉTAL PEINT (poteaux, rambardes, mobilier)
	"metal": HELPERS + VERT_WORLD + """
uniform vec3 paint : source_color = vec3(0.08, 0.09, 0.1);
uniform float chips = 0.4;
uniform float metal = 0.6;
void fragment() {
	vec2 p = wpos.xy + wpos.zz * 0.7;
	float n3 = nz(p * 0.9 + 0.3);
	float n2 = nz(p * 0.2 + 0.1);
	vec3 col = paint * (0.85 + 0.3 * n3);
	float chip = smoothstep(0.66, 0.7, n2 + n3 * 0.2) * chips;
	col = mix(col, vec3(0.35, 0.2, 0.12), chip);
	ALBEDO = col;
	METALLIC = metal * (1.0 - chip);
	ROUGHNESS = mix(0.4, 0.8, chip) + n3 * 0.1;
}
""",
}
