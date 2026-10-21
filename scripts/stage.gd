class_name StageBuilder
extends RefCounted
## Construit les décors 3D (boulevard de nuit, docks au crépuscule) uniquement avec du code.
## Unités : 1 unité monde = 10 px de jeu. La zone de combat va de z = -2.8 à z = +2.8.


static func mat(col, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col if col is Color else Color(col)
	m.roughness = rough
	m.metallic = metal
	return m


static func emat(col, energy := 2.0) -> StandardMaterial3D:
	var c: Color = col if col is Color else Color(col)
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


static func unlit(col, energy := 1.0) -> StandardMaterial3D:
	var c: Color = col if col is Color else Color(col)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(c.r * energy, c.g * energy, c.b * energy, 1.0)
	return m


static func add(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


static func quad(w: float, h: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	return q


static func cyl(rt: float, rb: float, h: float, seg := 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	return c


static func omni(parent: Node3D, pos: Vector3, col: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	parent.add_child(l)
	return l


static func noise_tex(freq: float, seed_: int, c0: Color, c1: Color, size := 512) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = freq
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.width = size
	t.height = size
	t.seamless = true
	t.noise = n
	var g := Gradient.new()
	g.set_color(0, c0)
	g.set_color(1, c1)
	t.color_ramp = g
	return t


static func neon(parent: Node3D, text: String, pos: Vector3, col: Color) -> Label3D:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Impact", "Arial Black", "Segoe UI Black", "Arial"])
	f.font_weight = 800
	var l := Label3D.new()
	l.font = f
	l.text = text
	l.font_size = 120
	l.pixel_size = 0.0105
	l.outline_size = 22
	l.modulate = Color(minf(1.0, col.r * 1.3 + 0.25), minf(1.0, col.g * 1.3 + 0.25), minf(1.0, col.b * 1.3 + 0.25))
	l.outline_modulate = Color(col.r, col.g, col.b, 0.85)
	l.shaded = false
	l.position = pos
	parent.add_child(l)
	return l


## Dégradé vertical (haut opaque -> bas transparent) pour les reflets et les cônes de lumière
static func fade_tex(a0: float, a1: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, a0))
	g.set_color(1, Color(1, 1, 1, a1))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.5, 0.0)
	t.fill_to = Vector2(0.5, 1.0)
	t.width = 16
	t.height = 128
	return t


static func glow_mat(col: Color, tex: Texture2D, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = tex
	m.albedo_color = Color(col.r * energy, col.g * energy, col.b * energy, 1.0)
	m.disable_receive_shadows = true
	return m


static var _streak: ImageTexture = null

## Texture de reflet mouillé : traînées verticales irrégulières, bords fondus, fondu vers la caméra
static func streak_tex() -> ImageTexture:
	if _streak:
		return _streak
	var w := 96
	var h := 192
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 42
	n.frequency = 0.09
	for x in w:
		var u := float(x) / (w - 1)
		var side := pow(clampf(1.0 - absf(u * 2.0 - 1.0), 0.0, 1.0), 1.6)
		var col_n := 0.55 + 0.45 * n.get_noise_2d(x * 3.0, 0.0)
		for y in h:
			var v := float(y) / (h - 1)
			var along := pow(1.0 - v, 1.1) * smoothstep(0.0, 0.05, v)
			var ripple := 0.75 + 0.25 * n.get_noise_2d(x * 1.5, y * 0.35)
			var a := clampf(side * along * col_n * ripple, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_streak = ImageTexture.create_from_image(img)
	return _streak


## Reflet d'une source lumineuse sur la chaussée mouillée : une traînée qui descend vers la caméra
static func road_reflection(parent: Node3D, x: float, width: float, col: Color, z0: float, length: float, energy: float) -> MeshInstance3D:
	var p := PlaneMesh.new()
	p.size = Vector2(width, length)
	var mi := add(parent, p, glow_mat(col, streak_tex(), energy), Vector3(x, 0.012, z0 + length / 2.0), false)
	return mi


const CONE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 color : source_color = vec3(1.0, 0.85, 0.6);
uniform float strength = 0.3;
void fragment() {
	// bords fondus (vu de profil le cône s'efface) et fondu vers le sol
	float facing = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.6);
	float down = pow(1.0 - UV.y, 1.3) * smoothstep(0.0, 0.08, UV.y);
	ALBEDO = color * strength * facing * down;
}
"""


## Cône de lumière visible sous un lampadaire
static func light_cone(parent: Node3D, pos: Vector3, h: float, r: float, col: Color, energy: float) -> void:
	var c := CylinderMesh.new()
	c.top_radius = 0.22
	c.bottom_radius = r
	c.height = h
	c.cap_top = false
	c.cap_bottom = false
	c.radial_segments = 32
	var cm := ShaderMaterial.new()
	cm.shader = Shader.new()
	cm.shader.code = CONE_SHADER
	cm.set_shader_parameter("color", col)
	cm.set_shader_parameter("strength", 0.7 * energy)
	add(parent, c, cm, pos - Vector3(0, h / 2.0, 0), false)
	# tache de lumière au sol
	var pool := PlaneMesh.new()
	pool.size = Vector2(r * 2.2, r * 1.6)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.35))
	g.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	add(parent, pool, glow_mat(col, gt, energy * 0.8), Vector3(pos.x, 0.015, pos.z + 1.2), false)


## Enseigne qui pourra grésiller (animée par gfx.gd)
static func flicker(labels: Array, mats: Array, lights: Array) -> Dictionary:
	for m in mats:
		m.set_meta("e0", m.emission_energy_multiplier)
	for l in lights:
		l.set_meta("e0", l.light_energy)
	return {"labels": labels, "mats": mats, "lights": lights}


const PUDDLE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 base_color = vec3(0.07, 0.06, 0.12);
uniform float freq = 1.7;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	// ronds de pluie qui s'agrandissent dans la flaque
	vec2 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz * freq;
	vec2 n = vec2(0.0);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			vec2 cell = floor(w) + vec2(float(i), float(j));
			float h = hash(cell);
			float t = fract(TIME * 0.8 + h);
			vec2 c = cell + vec2(hash(cell + 3.1), hash(cell + 7.7));
			vec2 d = w - c;
			float r = length(d);
			float front = t * 0.9;
			float a = exp(-pow((r - front) * 12.0, 2.0)) * (1.0 - t);
			n += d / max(r, 0.001) * a * cos((r - front) * 40.0);
		}
	}
	vec3 wn = normalize(vec3(n.x * 0.5, 1.0, n.y * 0.5));
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	ALBEDO = base_color;
	METALLIC = 0.6;
	ROUGHNESS = 0.06;
	SPECULAR = 0.7;
}
"""


static func make_env(top: String, horizon: String, ground: String, fogc: String, fog_d: float, amb: float) -> Environment:
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(top)
	sm.sky_horizon_color = Color(horizon)
	sm.ground_horizon_color = Color(horizon)
	sm.ground_bottom_color = Color(ground)
	sm.sun_angle_max = 2.0
	var sky := Sky.new()
	sky.sky_material = sm
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = amb
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(fogc)
	env.fog_density = fog_d
	env.fog_sky_affect = 0.25
	return env


## ---------- BOULEVARD NÉON ---------- (voir city.gd)
static func city(L: float) -> Dictionary:
	return CityBuilder.build(L)


## Ville lointaine (silhouettes d'immeubles et fenêtres allumées) et lune
static func far_city(root: Node3D, L: float, R: RandomNumberGenerator) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 110
	var wins_w := []
	var wins_c := []
	for k in 110:
		var w := 6.0 + R.randf() * 10.0
		var hh := 14.0 + R.randf() * 46.0
		var d := 6.0 + R.randf() * 8.0
		var x := -60.0 + k * ((L + 180.0) / 110.0) + R.randf() * 4.0
		var z := -34.0 - R.randf() * 50.0
		mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(w, hh, d)), Vector3(x, hh / 2.0 - 1.0, z)))
		var yy := 2.0
		while yy < hh - 2.0:
			var xx := -w / 2.0 + 1.0
			while xx < w / 2.0 - 1.0:
				if R.randf() < 0.3:
					var p := Vector3(x + xx, yy, z + d / 2.0 + 0.05)
					if R.randf() < 0.75:
						wins_w.append(p)
					else:
						wins_c.append(p)
				xx += 1.6
			yy += 2.2
	var far := MultiMeshInstance3D.new()
	far.multimesh = mm
	far.material_override = mat("#1b1530", 0.9)
	root.add_child(far)
	for pair in [[wins_w, "#ffcf8a"], [wins_c, "#8fe0ff"]]:
		var arr: Array = pair[0]
		var wm2 := MultiMesh.new()
		wm2.transform_format = MultiMesh.TRANSFORM_3D
		wm2.mesh = quad(0.7, 0.9)
		wm2.instance_count = arr.size()
		for k in arr.size():
			wm2.set_instance_transform(k, Transform3D(Basis(), arr[k]))
		var wmi := MultiMeshInstance3D.new()
		wmi.multimesh = wm2
		wmi.material_override = emat(pair[1], 1.2)
		wmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(wmi)
	var moon := SphereMesh.new()
	moon.radius = 9.0
	moon.height = 18.0
	add(root, moon, unlit("#f6e9c8", 1.8), Vector3(L * 0.6, 90, -320), false)


## ---------- LE MÉTRO ----------
static func metro(L: float) -> Dictionary:
	var root := Node3D.new()
	var R := RandomNumberGenerator.new()
	R.seed = 33
	var WW := L + 160.0
	# quai carrelé, légèrement brillant
	var MB := CityBuilder.Batch.new()
	var fm := Shaders.mat("tiles", {"tile_a": Color("#8f897e"), "tile_b": Color("#7a746a"), "grout": Color("#34312c"), "tile": Vector2(1.0, 1.0), "wet": 0.0, "gloss": 0.75})
	var fl := PlaneMesh.new()
	fl.size = Vector2(WW, 30)
	add(root, fl, fm, Vector3(L / 2.0, 0, -4.0 + 15.0), false)
	# bande d'éveil podotactile et bord du quai
	add(root, box(WW, 0.03, 0.6), Shaders.mat("tiles", {"tile_a": Color("#d8b030"), "tile_b": Color("#c8a028"), "grout": Color("#7a5a10"), "tile": Vector2(0.3, 0.3), "wet": 0.0, "gloss": 0.3}), Vector3(L / 2.0, 0.012, -3.5), false)
	add(root, box(WW, 1.7, 0.3), Shaders.mat("wall", {"style": 1, "brick_a": Color("#3a3832"), "mortar": Color("#22201c"), "wet": 0.0}), Vector3(L / 2.0, -0.85, -4.05))
	# fosse et voies
	add(root, box(WW, 0.1, 7.0), Shaders.mat("tiles", {"tile_a": Color("#2a2620"), "tile_b": Color("#1e1b17"), "grout": Color("#121010"), "tile": Vector2(0.4, 0.4), "wet": 0.3}), Vector3(L / 2.0, -1.65, -7.6), false)
	var railm := Shaders.mat("metal", {"paint": Color("#6a6e76"), "chips": 0.6, "metal": 0.95})
	var sleeper := Shaders.mat("wall", {"style": 1, "brick_a": Color("#3a2c20"), "mortar": Color("#20180f"), "wet": 0.0})
	for rz in [-6.6, -8.2]:
		add(root, box(WW, 0.18, 0.14), railm, Vector3(L / 2.0, -1.5, rz), false)
	var sx := -20.0
	while sx < L + 60.0:
		add(root, box(0.45, 0.1, 3.0), sleeper, Vector3(sx, -1.58, -7.4), false)
		sx += 1.3
	# mur du tunnel en carreaux blancs
	var wm := Shaders.mat("tiles", {"tile_a": Color("#dfe6dd"), "tile_b": Color("#cdd5cc"), "grout": Color("#7e867e"), "tile": Vector2(0.6, 0.3), "wet": 0.0, "gloss": 0.85})
	add(root, box(WW, 10.0, 0.4), wm, Vector3(L / 2.0, 3.3, -11.4))
	var green_t := Shaders.mat("tiles", {"tile_a": Color("#1f6f64"), "tile_b": Color("#185a51"), "grout": Color("#0c2e2a"), "tile": Vector2(0.6, 0.3), "wet": 0.0, "gloss": 0.85})
	add(root, box(WW, 0.9, 0.42), green_t, Vector3(L / 2.0, 5.2, -11.38), false)
	add(root, box(WW, 0.3, 10.0), mat("#1a1c20", 0.8), Vector3(L / 2.0, 8.4, -7.2), false)
	# affiches et enseignes de station
	var ads := ["#ff4f8b", "#3fe0d0", "#ffd23f", "#b47dff", "#7cff6b"]
	var mneons := []
	var frame := mat("#0c0a12", 0.4, 0.6)
	var ax := 6.0
	var k := 0
	while ax < L:
		add(root, box(5.4, 3.4, 0.1), frame, Vector3(ax, 2.6, -11.15), false)
		add(root, quad(5.0, 3.0), emat(ads[k % ads.size()], 0.9), Vector3(ax, 2.6, -11.08), false)
		if k % 3 == 1:
			var st := neon(root, "STATION NÉON", Vector3(ax + 9.0, 6.6, -11.1), Color("#3fe0d0"))
			if k % 2 == 0:
				mneons.append(flicker([st], [], []))
		k += 1
		ax += 17.0
	# tubes fluorescents sous l'auvent
	var tubem := unlit("#e8fff4", 2.6)
	var lx := 0.0
	while lx < L + 20.0:
		if int(lx) % 18 == 0:
			var tl := omni(root, Vector3(lx, 7.0, -3.0), Color("#d8fff0"), 2.4, 16.0)
			tl.light_volumetric_fog_energy = 1.6
			if int(lx) % 54 == 18:
				# un tube fluorescent fatigué qui clignote
				var tm := emat("#e8fff4", 2.6)
				add(root, box(3.0, 0.12, 0.25), tm, Vector3(lx, 8.2, -4.8), false)
				mneons.append(flicker([], [tm], [tl]))
			else:
				add(root, box(3.0, 0.12, 0.25), tubem, Vector3(lx, 8.2, -4.8), false)
		else:
			add(root, box(3.0, 0.12, 0.25), tubem, Vector3(lx, 8.2, -4.8), false)
		lx += 6.0
	# piliers au bord du quai
	var pil := Shaders.mat("tiles", {"tile_a": Color("#e2dacb"), "tile_b": Color("#d2cabb"), "grout": Color("#8a8476"), "tile": Vector2(0.5, 0.25), "wet": 0.0, "gloss": 0.8})
	var iron := Shaders.mat("metal", {"paint": Color("#1c2024"), "chips": 0.3, "metal": 0.6})
	var px := 10.0
	var pk := 0
	while px < L:
		add(root, box(1.0, 9.6, 1.0), pil, Vector3(px, 4.8, -3.6))
		add(root, box(1.05, 0.8, 1.05), green_t, Vector3(px, 2.0, -3.6))
		# banc ou poubelle ou distributeur contre les piliers
		if pk % 3 == 0:
			for bk in 3:
				MB.box("bench", iron, Vector3(0.5, 0.08, 0.5), Vector3(px + 1.2 + bk * 0.55, 0.9, -3.45))
				MB.box("bench", iron, Vector3(0.5, 0.6, 0.06), Vector3(px + 1.2 + bk * 0.55, 1.25, -3.68))
			MB.box("bench", iron, Vector3(1.8, 0.85, 0.06), Vector3(px + 1.75, 0.43, -3.5))
		elif pk % 3 == 1:
			var vend := Shaders.mat("window", {"size": Vector2(1.2, 1.9), "depth": 0.25, "shop": true, "shop_light": Color("#ffd8f0")})
			MB.box("vend", Shaders.mat("metal", {"paint": Color("#a81e3a"), "chips": 0.2, "metal": 0.3}), Vector3(1.6, 3.0, 0.9), Vector3(px + 1.6, 1.5, -3.3))
			MB.quad("vend_glass", vend, 1.2, 1.9, Vector3(px + 1.4, 1.85, -2.84), Color(R.randf(), R.randf(), R.randf()))
			omni(root, Vector3(px + 1.6, 1.8, -2.2), Color("#ffb0d8"), 0.8, 4.0)
		else:
			MB.cyl("bin", iron, 0.38, 0.32, 1.1, Vector3(px + 1.3, 0.55, -3.45), 14)
			MB.cyl("bin", Shaders.mat("metal", {"paint": Color("#d8a820"), "chips": 0.3, "metal": 0.3}), 0.4, 0.4, 0.12, Vector3(px + 1.3, 1.12, -3.45), 14)
		pk += 1
		px += 22.0
	# rame à quai sur la première moitié
	var body := Shaders.mat("corrugated", {"base": Color("#c4c8ce"), "ribs": 2.0, "vertical_ribs": true, "tags": 0.6, "metal": 0.8, "rust": Color("#5a4a40")})
	var dark_m := Shaders.mat("metal", {"paint": Color("#22262c"), "chips": 0.3, "metal": 0.5})
	var stripe := emat("#ff4f8b", 1.6)
	var train_win := Shaders.mat("window", {"size": Vector2(2.4, 1.4), "depth": 1.3, "lit_chance": 1.0})
	var door_win := Shaders.mat("window", {"size": Vector2(0.6, 1.4), "depth": 2.2, "lit_chance": 1.0})
	var cx := 4.0
	while cx < L * 0.55:
		MB.box("train", body, Vector3(21.0, 4.0, 3.2), Vector3(cx + 10.5, 1.2, -7.4))
		MB.box("train_dark", dark_m, Vector3(21.0, 0.6, 3.0), Vector3(cx + 10.5, -1.05, -7.4))
		MB.box("train_dark", dark_m, Vector3(20.6, 0.3, 3.0), Vector3(cx + 10.5, 3.35, -7.4))
		add(root, box(21.0, 0.22, 0.04), stripe, Vector3(cx + 10.5, 0.1, -5.78), false)
		for wi in 4:
			var wxp := cx + 2.4 + wi * 5.4 if wi < 2 else cx + 2.4 + wi * 5.4 - 0.6
			MB.quad("train_win", train_win, 2.4, 1.4, Vector3(wxp, 2.0, -5.785), Color(R.randf(), R.randf(), 0.66 + 0.15 * R.randf()))
			MB.box("train_dark", dark_m, Vector3(2.6, 1.6, 0.04), Vector3(wxp, 2.0, -5.81))
		for di in [5.4, 15.6]:
			MB.box("train_dark", dark_m, Vector3(1.8, 3.4, 0.06), Vector3(cx + di, 0.95, -5.77))
			for dw in [-0.38, 0.38]:
				MB.quad("door_win", door_win, 0.6, 1.4, Vector3(cx + di + dw, 2.0, -5.735), Color(R.randf(), 0.5, 0.9))
		omni(root, Vector3(cx + 10.5, 2.0, -5.0), Color("#ffe0a8"), 1.2, 9.0)
		cx += 22.2
	MB.commit(root)
	# entrée du tunnel et quai du boss
	add(root, box(14, 10, 0.5), mat("#0a0a0c", 0.9), Vector3(L + 8.0, 3.3, -11.0), false)
	var q0 := neon(root, "QUAI 0", Vector3(L - 12.0, 6.6, -11.1), Color("#ff4f8b"))
	var q0l := omni(root, Vector3(L - 12.0, 5.5, -8.0), Color("#ff4f8b"), 3.0, 18.0)
	mneons.append(flicker([q0], [], [q0l]))
	neon(root, "SORTIE →", Vector3(L * 0.3, 7.4, -11.1), Color("#7cff6b"))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#040608")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#4a5a58")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color("#10201c")
	env.fog_density = 0.012
	return {
		"node": root, "env": env,
		"sun": Color("#cfe8ff"), "sun_energy": 0.3, "rain": false, "neons": mneons,
		"vfog": {"density": 0.008, "albedo": Color("#c0e0d4"), "emission": Color("#010403")},
	}


## ---------- LES DOCKS ----------
static func docks(L: float) -> Dictionary:
	var root := Node3D.new()
	var R := RandomNumberGenerator.new()
	R.seed = 21
	var WW := L + 160.0
	var DB := CityBuilder.Batch.new()
	var fm := Shaders.mat("tiles", {"tile_a": Color("#6a6a70"), "tile_b": Color("#5a5a62"), "grout": Color("#2a2a30"), "tile": Vector2(6.0, 6.0), "wet": 0.9})
	var fl := PlaneMesh.new()
	fl.size = Vector2(WW, 48)
	add(root, fl, fm, Vector3(L / 2.0, 0, -8.0 + 24.0), false)
	# bord du quai : bande de danger jaune et noire
	var hazard := CityBuilder._stripes(Color("#e8c23a"), Color("#141416"))
	hazard.uv1_scale = Vector3(WW / 2.0, 1, 1)
	add(root, box(WW, 0.02, 0.35), hazard, Vector3(L / 2.0, 0.01, -3.6), false)
	add(root, box(WW, 2.4, 0.8), Shaders.mat("wall", {"style": 2, "brick_a": Color("#4a4a52"), "wet": 1.0}), Vector3(L / 2.0, -1.1, -8.3))
	var water := PlaneMesh.new()
	water.size = Vector2(L + 800.0, 400)
	add(root, water, Shaders.mat("water"), Vector3(L / 2.0, -1.5, -8.7 - 200.0), false)
	var ccols := ["#9a3b2a", "#2b5d8a", "#3c7a4a", "#b88a2a", "#6a3a7a", "#c4682a"]
	var cm := []
	for c in ccols:
		cm.append(Shaders.mat("corrugated", {"base": Color(c), "ribs": 3.2, "vertical_ribs": true, "tags": 0.0, "metal": 0.35, "rust": Color("#4a2412")}))
	var cdark := Shaders.mat("metal", {"paint": Color("#18181c"), "chips": 0.6, "metal": 0.5})
	var brands := ["NEONCO", "MARÉE", "KAIJU LINE", "BOREAL", "TRANSAT"]
	var x := -10.0
	while x < L - 30.0:
		for row in 2:
			if R.randf() < (0.78 if row == 0 else 0.7):
				var zc := -5.6 if row == 0 else -7.0
				var xo := x + 3.0 + (R.randf() * 0.6 if row == 1 else 0.0)
				for j in 1 + R.randi() % (2 if row == 0 else 3):
					var cy := 1.3 + j * 2.6
					DB.box("cont%d" % (R.randi() % cm.size()), cm[R.randi() % cm.size()], Vector3(6, 2.6, 2.4), Vector3(xo, cy, zc))
					# pièces de coin et rails haut/bas
					for ex in [-2.95, 2.95]:
						for ey in [-1.25, 1.25]:
							DB.box("cont_dark", cdark, Vector3(0.18, 0.18, 2.46), Vector3(xo + ex, cy + ey, zc))
					DB.box("cont_dark", cdark, Vector3(6.0, 0.12, 0.06), Vector3(xo, cy + 1.24, zc + 1.21))
					DB.box("cont_dark", cdark, Vector3(6.0, 0.12, 0.06), Vector3(xo, cy - 1.24, zc + 1.21))
					if row == 0 and R.randf() < 0.45:
						var lb := Label3D.new()
						lb.text = brands[R.randi() % brands.size()]
						lb.font_size = 96
						lb.pixel_size = 0.009
						lb.modulate = Color(0.92, 0.92, 0.9, 0.85)
						lb.outline_size = 0
						lb.shaded = true
						lb.position = Vector3(xo, cy + 0.2, zc + 1.22)
						root.add_child(lb)
		# fûts et palettes devant les conteneurs
		var r := R.randf()
		if r < 0.35:
			for b in 2 + R.randi() % 3:
				var bm: Material = cm[1] if R.randf() < 0.5 else cm[0]
				DB.cyl("barrel", bm, 0.38, 0.38, 1.2, Vector3(x + 1.0 + b * 0.8, 0.6, -3.95 - (b % 2) * 0.3), 14)
				DB.cyl("barrel_rim", cdark, 0.4, 0.4, 0.06, Vector3(x + 1.0 + b * 0.8, 1.2, -3.95 - (b % 2) * 0.3), 14)
		elif r < 0.6:
			var pal := Shaders.mat("wall", {"style": 1, "brick_a": Color("#7a5a3a"), "mortar": Color("#4a3420"), "wet": 0.5})
			for py in 3 + R.randi() % 3:
				for sl in 4:
					DB.box("pallet", pal, Vector3(1.6, 0.05, 0.28), Vector3(x + 2.0, 0.1 + py * 0.16, -4.3 + sl * 0.33))
				DB.box("pallet", pal, Vector3(1.6, 0.1, 1.2), Vector3(x + 2.0, 0.04 + py * 0.16, -3.8))
		x += 6.4 + R.randf() * 3.0
	var yellow := Shaders.mat("metal", {"paint": Color("#e8c23a"), "chips": 0.5, "metal": 0.3})
	var dark := Shaders.mat("metal", {"paint": Color("#1c1c22"), "chips": 0.5, "metal": 0.6})
	var bxp := 4.0
	while bxp < L:
		DB.cyl("bollard", dark, 0.28, 0.32, 0.8, Vector3(bxp, 0.4, -3.95), 14)
		DB.cyl("bollard_top", yellow, 0.36, 0.3, 0.2, Vector3(bxp, 0.85, -3.95), 14)
		bxp += 18.0
	DB.commit(root)
	var polem := Shaders.mat("metal", {"paint": Color("#1f2228"), "chips": 0.5, "metal": 0.7})
	var lampm := unlit("#ffcf8a", 3.0)
	var lx := 10.0
	while lx < L - 20.0:
		add(root, cyl(0.16, 0.2, 10, 10), polem, Vector3(lx, 5, -4.6))
		add(root, box(2.2, 0.18, 0.18), polem, Vector3(lx + 0.9, 9.9, -4.6))
		add(root, box(1.0, 0.25, 0.6), lampm, Vector3(lx + 1.8, 9.75, -4.6), false)
		var sl := SpotLight3D.new()
		sl.position = Vector3(lx + 1.8, 9.6, -4.4)
		sl.rotation.x = -PI / 2.0
		sl.light_color = Color("#ffb46a")
		sl.light_energy = 7.0
		sl.light_volumetric_fog_energy = 8.0
		light_cone(root, Vector3(lx + 1.8, 9.6, -4.4), 9.6, 3.6, Color("#ffb46a"), 0.55)
		road_reflection(root, lx + 1.8, 2.6, Color("#ffb46a"), -3.2, 12.0, 1.6)
		sl.spot_range = 16.0
		sl.spot_angle = 45.0
		root.add_child(sl)
		lx += 32.0
	var crane := Shaders.mat("metal", {"paint": Color("#b8442e"), "chips": 0.5, "metal": 0.4})
	var tipm := unlit("#ff3030", 4.0)
	var cx := 0.0
	while cx < L + 40.0:
		var z := -28.0
		for ddx in [0.0, 9.0]:
			for ddz in [0.0, -8.0]:
				add(root, box(0.9, 26, 0.9), crane, Vector3(cx + ddx, 13, z + ddz), false)
		add(root, box(10, 1.2, 9), crane, Vector3(cx + 4.5, 26, z - 4.0), false)
		add(root, box(1.4, 1.4, 46), crane, Vector3(cx + 4.5, 27.2, z - 10.0), false)
		add(root, box(4, 3, 4), mat("#e3dccb", 0.6), Vector3(cx + 4.5, 28.6, z - 2.0), false)
		var tip := SphereMesh.new()
		tip.radius = 0.4
		tip.height = 0.8
		add(root, tip, tipm, Vector3(cx + 4.5, 28.4, z - 32.0), false)
		cx += 46.0
	var ship := Node3D.new()
	ship.position = Vector3(L * 0.45, -1.5, -95)
	root.add_child(ship)
	add(ship, box(90, 9, 16), mat("#16212a", 0.7), Vector3(0, 2, 0), false)
	add(ship, box(18, 10, 12), mat("#d8d4c8", 0.7), Vector3(-30, 11, 0), false)
	var shipw := emat("#ffcf8a", 2.0)
	for k in 6:
		add(ship, quad(1.6, 1.0), shipw, Vector3(-36.0 + k * 2.4, 12, 6.05), false)
	var cl := MultiMesh.new()
	cl.transform_format = MultiMesh.TRANSFORM_3D
	cl.mesh = box(0.8, 0.8, 0.8)
	cl.instance_count = 160
	for k in 160:
		cl.set_instance_transform(k, Transform3D(Basis(), Vector3(-150.0 + R.randf() * (L + 400.0), R.randf() * 6.0, -230.0 - R.randf() * 40.0)))
	var cli := MultiMeshInstance3D.new()
	cli.multimesh = cl
	cli.material_override = emat("#ffc48a", 2.0)
	root.add_child(cli)
	# entrepôt du boss
	var wx0 := L - 34.0
	var corr := Shaders.mat("corrugated", {"base": Color("#4a4e58"), "ribs": 2.5, "vertical_ribs": true, "tags": 1.0, "metal": 0.6})
	add(root, box(60, 16, 14), corr, Vector3(wx0 + 20.0, 8, -16))
	add(root, quad(16, 10), mat("#14151b", 0.6, 0.2), Vector3(wx0 + 14.0, 5, -8.98), false)
	add(root, box(16, 0.8, 0.05), emat("#e8c23a", 1.2), Vector3(wx0 + 14.0, 10.2, -8.96), false)
	add(root, box(10.4, 2.2, 0.3), mat("#0b0812", 0.5, 0.4), Vector3(wx0 + 14.0, 13, -8.95))
	var q9 := neon(root, "QUAI 9", Vector3(wx0 + 14.0, 13, -8.78), Color("#ff4f8b"))
	var q9l := omni(root, Vector3(wx0 + 14.0, 12, -6.0), Color("#ff4f8b"), 3.0, 20.0)
	return {
		"node": root,
		"env": make_env("#04101a", "#d0603a", "#0b0d10", "#2a3a44", 0.008, 0.6),
		"sun": Color("#ffd2b0"), "sun_energy": 0.7, "rain": false,
		"neons": [flicker([q9], [], [q9l])],
		"vfog": {"density": 0.006, "albedo": Color("#e0c0a8"), "emission": Color("#040201")},
	}
