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


static func neon(parent: Node3D, text: String, pos: Vector3, col: Color) -> void:
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


## ---------- BOULEVARD NÉON ----------
static func city(L: float) -> Dictionary:
	var root := Node3D.new()
	var R := RandomNumberGenerator.new()
	R.seed = 7
	var WW := L + 160.0
	# chaussée mouillée : la rugosité varie pour faire des zones luisantes
	var rm := mat(Color(1, 1, 1), 1.0, 0.3)
	rm.albedo_texture = noise_tex(0.09, 3, Color("#1c1926"), Color("#3c3650"))
	rm.roughness_texture = noise_tex(0.012, 11, Color(0.04, 0.04, 0.04), Color(0.85, 0.85, 0.85))
	rm.uv1_scale = Vector3(WW / 12.0, 48.0 / 12.0, 1)
	var road := PlaneMesh.new()
	road.size = Vector2(WW, 48)
	add(root, road, rm, Vector3(L / 2.0, 0, -3.2 + 24.0), false)
	var dm := emat("#d8bd4a", 0.25)
	dm.roughness = 0.6
	var dx := -20.0
	while dx < L + 60.0:
		add(root, box(2.2, 0.02, 0.2), dm, Vector3(dx, 0.01, 0.8), false)
		dx += 4.2
	var sw := mat(Color(1, 1, 1), 0.55, 0.1)
	sw.albedo_texture = noise_tex(0.2, 4, Color("#3a3550"), Color("#544d6e"), 256)
	sw.uv1_scale = Vector3(WW / 4.0, 1, 1)
	add(root, box(WW, 0.32, 4.2), sw, Vector3(L / 2.0, 0.16, -5.35))
	add(root, box(WW, 0.34, 0.3), mat("#6a6382", 0.6), Vector3(L / 2.0, 0.17, -3.3))
	var pm := mat("#0d0b16", 0.02, 0.6)
	for i in 24:
		var pd := add(root, cyl(1.0, 1.0, 0.01, 24), pm, Vector3(R.randf() * L, 0.006, -2.5 + R.randf() * 13.0), false)
		pd.scale = Vector3(1.5 + R.randf() * 2.5, 1, 0.6 + R.randf() * 0.6)

	var signs := [["RAMEN 24H", "#ff4f8b"], ["LAVERIE", "#3fe0d0"], ["BAR LUNE", "#ffd23f"], ["ARCADE", "#b47dff"],
		["PRÊTEUR", "#7cff6b"], ["KARAOKÉ", "#ff7a3c"], ["TATOUAGE", "#3fe0d0"], ["HÔTEL", "#ff4f8b"]]
	var cols := ["#3a2c55", "#4a2c40", "#2c2a4c", "#40283a"]
	var heights := [17.6, 19.2, 16.0, 20.8]
	var fnoise := noise_tex(0.18, 5, Color(0.72, 0.72, 0.72), Color(1, 1, 1), 256)
	var fmats := []
	for c in cols:
		var m := mat(Color(c), 0.9)
		m.albedo_texture = fnoise
		m.uv1_scale = Vector3(3, 3, 3)
		fmats.append(m)
	var warm := emat("#ffcf7a", 1.5)
	var cool := emat("#9fe6ff", 1.3)
	var glass := mat("#141228", 0.06, 0.6)
	var frame := mat("#0c0a12", 0.4, 0.6)
	var shopm := [emat("#ffcf9a", 1.1), emat("#8fe6ff", 1.0), emat("#ff9fd0", 1.0)]
	var doorm := emat("#2e2648", 0.5)
	var boardm := mat("#0b0812", 0.5, 0.4)
	var awn := [mat("#a8324a", 0.8), mat("#2a7a7a", 0.8), mat("#7a5a2a", 0.8)]
	var polem := mat("#16121f", 0.4, 0.7)
	var lampm := unlit("#fff1cf", 3.0)
	var i := 0
	var bx := -25.6
	while bx < L + 30.0:
		var h: float = heights[i % 4]
		add(root, box(12.6, h, 8), fmats[i % 4], Vector3(bx + 6.4, h / 2.0, -11.4))
		add(root, box(12.8, 0.5, 8.6), mat("#1a1626", 0.7), Vector3(bx + 6.4, h + 0.25, -11.4))
		add(root, box(12.62, 5.2, 0.1), mat("#120e1c", 0.8), Vector3(bx + 6.4, 2.6, -7.38), false)
		var fy := 6.8
		while fy + 2.8 < h - 1.0:
			for fx in [1.3, 5.2, 9.1]:
				var r := R.randf()
				var wm: Material = warm if r < 0.34 else (cool if r < 0.48 else glass)
				add(root, box(2.8, 3.2, 0.12), frame, Vector3(bx + fx + 1.2, fy + 1.4, -7.36), false)
				add(root, quad(2.4, 2.8), wm, Vector3(bx + fx + 1.2, fy + 1.4, -7.29), false)
			fy += 3.9
		add(root, quad(6.4, 3.6), shopm[i % 3], Vector3(bx + 4.2, 2.4, -7.3), false)
		add(root, box(6.8, 0.25, 0.25), frame, Vector3(bx + 4.2, 4.3, -7.25))
		add(root, box(6.8, 0.25, 0.25), frame, Vector3(bx + 4.2, 0.5, -7.25))
		add(root, box(0.18, 3.6, 0.2), frame, Vector3(bx + 4.2, 2.4, -7.25))
		add(root, quad(2.4, 4.2), doorm, Vector3(bx + 10.0, 2.1, -7.3), false)
		add(root, box(2.8, 0.3, 0.3), frame, Vector3(bx + 10.0, 4.3, -7.25))
		var s: Array = signs[i % signs.size()]
		var sc := Color(s[1])
		add(root, box(9.2, 1.8, 0.3), boardm, Vector3(bx + 6.4, 5.6, -7.2))
		var tube := emat(sc, 3.0)
		add(root, box(9.0, 0.08, 0.08), tube, Vector3(bx + 6.4, 6.42, -7.02), false)
		add(root, box(9.0, 0.08, 0.08), tube, Vector3(bx + 6.4, 4.78, -7.02), false)
		neon(root, s[0], Vector3(bx + 6.4, 5.6, -7.03), sc)
		omni(root, Vector3(bx + 6.4, 5.0, -5.4), sc, 2.2, 14.0)
		if i % 3 == 1:
			var aw := add(root, box(7.2, 0.15, 1.8), awn[i % 3], Vector3(bx + 4.2, 4.75, -6.5))
			aw.rotation.x = 0.35
		if i % 2 == 0:
			var lx := bx + 12.6
			add(root, cyl(0.12, 0.16, 8.6, 10), polem, Vector3(lx, 4.3, -4.2))
			add(root, box(1.8, 0.14, 0.14), polem, Vector3(lx - 0.85, 8.55, -4.2))
			add(root, box(0.9, 0.22, 0.5), lampm, Vector3(lx - 1.6, 8.4, -4.2), false)
			var sl := SpotLight3D.new()
			sl.position = Vector3(lx - 1.6, 8.3, -4.2)
			sl.rotation.x = -PI / 2.0
			sl.light_color = Color("#ffd9a0")
			sl.light_energy = 5.0
			sl.spot_range = 14.0
			sl.spot_angle = 42.0
			root.add_child(sl)
		i += 1
		bx += 12.8

	# ville lointaine
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
	return {
		"node": root,
		"env": make_env("#070514", "#7a2456", "#0b0814", "#2a1440", 0.011, 0.55),
		"sun": Color("#bfd0ff"), "sun_energy": 0.55, "rain": true,
	}


## ---------- LE MÉTRO ----------
static func metro(L: float) -> Dictionary:
	var root := Node3D.new()
	var R := RandomNumberGenerator.new()
	R.seed = 33
	var WW := L + 160.0
	# quai carrelé, légèrement brillant
	var fm := mat(Color(1, 1, 1), 0.35, 0.05)
	fm.albedo_texture = noise_tex(0.08, 12, Color("#5a5650"), Color("#8a857a"))
	fm.roughness_texture = noise_tex(0.02, 13, Color(0.12, 0.12, 0.12), Color(0.6, 0.6, 0.6))
	fm.uv1_scale = Vector3(WW / 10.0, 30.0 / 10.0, 1)
	var fl := PlaneMesh.new()
	fl.size = Vector2(WW, 30)
	add(root, fl, fm, Vector3(L / 2.0, 0, -4.0 + 15.0), false)
	var joint := mat("#3a3732", 0.8)
	var gx := -20.0
	while gx < L + 60.0:
		add(root, box(0.05, 0.01, 30), joint, Vector3(gx, 0.004, 11), false)
		gx += 2.0
	# bande d'éveil jaune et bord du quai
	add(root, box(WW, 0.02, 0.6), emat("#e8c23a", 0.35), Vector3(L / 2.0, 0.01, -3.5), false)
	add(root, box(WW, 1.7, 0.3), mat("#2a2826", 0.8), Vector3(L / 2.0, -0.85, -4.05))
	# fosse et voies
	add(root, box(WW, 0.1, 7.0), mat("#141312", 0.95), Vector3(L / 2.0, -1.65, -7.6), false)
	var railm := mat("#8a8f98", 0.3, 0.9)
	var sleeper := mat("#2a2018", 0.9)
	for rz in [-6.6, -8.2]:
		add(root, box(WW, 0.18, 0.14), railm, Vector3(L / 2.0, -1.5, rz), false)
	var sx := -20.0
	while sx < L + 60.0:
		add(root, box(0.45, 0.1, 3.0), sleeper, Vector3(sx, -1.58, -7.4), false)
		sx += 1.3
	# mur du tunnel en carreaux blancs
	var wm := mat(Color(1, 1, 1), 0.3, 0.05)
	wm.albedo_texture = noise_tex(0.5, 14, Color("#bfc8bf"), Color("#e4ebe2"), 256)
	wm.uv1_scale = Vector3(WW / 3.0, 3, 1)
	add(root, box(WW, 10.0, 0.4), wm, Vector3(L / 2.0, 3.3, -11.4))
	add(root, box(WW, 0.9, 0.42), mat("#1f6f64", 0.5), Vector3(L / 2.0, 5.2, -11.38), false)
	add(root, box(WW, 0.3, 10.0), mat("#1a1c20", 0.8), Vector3(L / 2.0, 8.4, -7.2), false)
	# affiches et enseignes de station
	var ads := ["#ff4f8b", "#3fe0d0", "#ffd23f", "#b47dff", "#7cff6b"]
	var frame := mat("#0c0a12", 0.4, 0.6)
	var ax := 6.0
	var k := 0
	while ax < L:
		add(root, box(5.4, 3.4, 0.1), frame, Vector3(ax, 2.6, -11.15), false)
		add(root, quad(5.0, 3.0), emat(ads[k % ads.size()], 0.9), Vector3(ax, 2.6, -11.08), false)
		if k % 3 == 1:
			neon(root, "STATION NÉON", Vector3(ax + 9.0, 6.6, -11.1), Color("#3fe0d0"))
		k += 1
		ax += 17.0
	# tubes fluorescents sous l'auvent
	var tubem := unlit("#e8fff4", 2.6)
	var lx := 0.0
	while lx < L + 20.0:
		add(root, box(3.0, 0.12, 0.25), tubem, Vector3(lx, 8.2, -4.8), false)
		if int(lx) % 18 == 0:
			omni(root, Vector3(lx, 7.0, -3.0), Color("#d8fff0"), 2.4, 16.0)
		lx += 6.0
	# piliers au bord du quai
	var pil := mat("#d8d0c0", 0.5)
	var band := mat("#1f6f64", 0.5)
	var px := 10.0
	while px < L:
		add(root, box(1.0, 9.6, 1.0), pil, Vector3(px, 4.8, -3.6))
		add(root, box(1.05, 0.8, 1.05), band, Vector3(px, 2.0, -3.6))
		px += 22.0
	# rame à quai sur la première moitié
	var body := mat("#c9ccd2", 0.35, 0.7)
	var winm := emat("#ffe8b0", 1.3)
	var doorm := mat("#3a3e48", 0.4, 0.6)
	var stripe := emat("#ff4f8b", 1.6)
	var cx := 4.0
	while cx < L * 0.55:
		add(root, box(21.0, 4.4, 3.2), body, Vector3(cx + 10.5, 1.0, -7.4))
		add(root, box(21.0, 0.22, 0.04), stripe, Vector3(cx + 10.5, 0.1, -5.78), false)
		for wi in 5:
			add(root, quad(2.4, 1.4), winm, Vector3(cx + 2.0 + wi * 4.2, 2.0, -5.79), false)
		for di in [5.4, 15.6]:
			add(root, quad(1.6, 3.2), doorm, Vector3(cx + di, 0.9, -5.785), false)
		omni(root, Vector3(cx + 10.5, 2.0, -5.0), Color("#ffe0a8"), 1.2, 9.0)
		cx += 22.2
	# entrée du tunnel et quai du boss
	add(root, box(14, 10, 0.5), mat("#0a0a0c", 0.9), Vector3(L + 8.0, 3.3, -11.0), false)
	neon(root, "QUAI 0", Vector3(L - 12.0, 6.6, -11.1), Color("#ff4f8b"))
	omni(root, Vector3(L - 12.0, 5.5, -8.0), Color("#ff4f8b"), 3.0, 18.0)
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
		"sun": Color("#cfe8ff"), "sun_energy": 0.3, "rain": false,
	}


## ---------- LES DOCKS ----------
static func docks(L: float) -> Dictionary:
	var root := Node3D.new()
	var R := RandomNumberGenerator.new()
	R.seed = 21
	var WW := L + 160.0
	var fm := mat(Color(1, 1, 1), 0.8, 0.1)
	fm.albedo_texture = noise_tex(0.06, 8, Color("#4c4c55"), Color("#7a7a84"))
	fm.roughness_texture = noise_tex(0.015, 9, Color(0.35, 0.35, 0.35), Color(0.95, 0.95, 0.95))
	fm.uv1_scale = Vector3(WW / 14.0, 48.0 / 14.0, 1)
	var fl := PlaneMesh.new()
	fl.size = Vector2(WW, 48)
	add(root, fl, fm, Vector3(L / 2.0, 0, -8.0 + 24.0), false)
	var seams := mat("#2e2e36", 0.9)
	var sx := -20.0
	while sx < L + 60.0:
		add(root, box(0.08, 0.01, 40), seams, Vector3(sx, 0.006, 12), false)
		sx += 6.0
	add(root, box(WW, 0.01, 0.3), emat("#e8c23a", 0.3), Vector3(L / 2.0, 0.008, -3.6), false)
	add(root, box(WW, 2.4, 0.8), mat("#3a3a42", 0.8), Vector3(L / 2.0, -1.1, -8.3))
	var water := PlaneMesh.new()
	water.size = Vector2(L + 800.0, 400)
	add(root, water, mat("#0b2a38", 0.05, 0.85), Vector3(L / 2.0, -1.5, -8.7 - 200.0), false)
	var ccols := ["#9a3b2a", "#2b5d8a", "#3c7a4a", "#b88a2a", "#6a3a7a", "#c4682a"]
	var rib := noise_tex(0.5, 2, Color(0.7, 0.7, 0.7), Color(1, 1, 1), 128)
	var cm := []
	for c in ccols:
		var m := mat(Color(c), 0.5, 0.4)
		m.albedo_texture = rib
		m.uv1_scale = Vector3(6, 1, 1)
		cm.append(m)
	var x := -10.0
	while x < L - 30.0:
		if R.randf() < 0.78:
			for j in 1 + R.randi() % 2:
				add(root, box(6, 2.6, 2.4), cm[R.randi() % cm.size()], Vector3(x + 3.0, 1.3 + j * 2.6, -5.6))
		if R.randf() < 0.7:
			for j in 1 + R.randi() % 3:
				add(root, box(6, 2.6, 2.4), cm[R.randi() % cm.size()], Vector3(x + 3.0 + R.randf() * 0.6, 1.3 + j * 2.6, -7.0))
		x += 6.4 + R.randf() * 3.0
	var yellow := mat("#e8c23a", 0.5, 0.2)
	var dark := mat("#1c1c22", 0.6, 0.3)
	var bxp := 4.0
	while bxp < L:
		add(root, cyl(0.28, 0.32, 0.8, 12), dark, Vector3(bxp, 0.4, -3.95))
		add(root, cyl(0.3, 0.3, 0.18, 12), yellow, Vector3(bxp, 0.75, -3.95))
		bxp += 18.0
	var polem := mat("#1f2228", 0.4, 0.7)
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
		sl.light_energy = 6.0
		sl.spot_range = 16.0
		sl.spot_angle = 45.0
		root.add_child(sl)
		lx += 32.0
	var crane := mat("#b8442e", 0.6, 0.4)
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
	var corr := mat(Color(1, 1, 1), 0.7, 0.3)
	corr.albedo_texture = noise_tex(0.3, 6, Color("#2c2e36"), Color("#4a4c58"), 256)
	corr.uv1_scale = Vector3(12, 1, 1)
	add(root, box(60, 16, 14), corr, Vector3(wx0 + 20.0, 8, -16))
	add(root, quad(16, 10), mat("#14151b", 0.6, 0.2), Vector3(wx0 + 14.0, 5, -8.98), false)
	add(root, box(16, 0.8, 0.05), emat("#e8c23a", 1.2), Vector3(wx0 + 14.0, 10.2, -8.96), false)
	add(root, box(10.4, 2.2, 0.3), mat("#0b0812", 0.5, 0.4), Vector3(wx0 + 14.0, 13, -8.95))
	neon(root, "QUAI 9", Vector3(wx0 + 14.0, 13, -8.78), Color("#ff4f8b"))
	omni(root, Vector3(wx0 + 14.0, 12, -6.0), Color("#ff4f8b"), 3.0, 20.0)
	return {
		"node": root,
		"env": make_env("#04101a", "#d0603a", "#0b0d10", "#2a3a44", 0.008, 0.6),
		"sun": Color("#ffd2b0"), "sun_energy": 0.7, "rain": false,
	}
