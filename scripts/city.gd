class_name CityBuilder
extends RefCounted
## Boulevard Néon, version détaillée : façades en relief (fenêtres creusées avec pièces
## visibles, rebords, linteaux, corniches), devantures, rideaux métalliques taggés, escaliers
## de secours, toits encombrés, lampadaires modélisés, mobilier urbain, plaques d'égout fumantes,
## passages piétons. La géométrie est fusionnée par matière et par tronçon (peu d'appels de dessin).
## Unités : 1 = 10 px de jeu. Façades à z = -7.4, trottoir de -7.4 à -3.3, chaussée au-delà.


const FRONT := -7.4


## Regroupe des formes en un seul maillage par (matière, tronçon de rue)
class Batch:
	var tools := {}
	var mats := {}
	var shadow := {}
	var quads := {}

	func add(key: String, m: Material, mesh: Mesh, xf: Transform3D, cast := true) -> void:
		var k := key + "@" + str(int(floor(xf.origin.x / 52.0)))
		if not tools.has(k):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[k] = st
			mats[k] = m
			shadow[k] = cast
		(tools[k] as SurfaceTool).append_from(mesh, 0, xf)

	func box(key: String, m: Material, size: Vector3, pos: Vector3, rot := Vector3.ZERO, cast := true) -> void:
		var b := BoxMesh.new()
		b.size = size
		add(key, m, b, Transform3D(Basis.from_euler(rot), pos), cast)

	func cyl(key: String, m: Material, r_top: float, r_bot: float, h: float, pos: Vector3, seg := 12, rot := Vector3.ZERO, cast := true) -> void:
		var c := CylinderMesh.new()
		c.top_radius = r_top
		c.bottom_radius = r_bot
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		add(key, m, c, Transform3D(Basis.from_euler(rot), pos), cast)

	## Quadrilatère face à +Z, avec une couleur de sommet (graine pour le shader des fenêtres)
	func quad(key: String, m: Material, w: float, h: float, pos: Vector3, seed: Color) -> void:
		var k := key + "@" + str(int(floor(pos.x / 52.0)))
		if not quads.has(k):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			quads[k] = st
			mats[k] = m
		var st: SurfaceTool = quads[k]
		var tl := pos + Vector3(-w / 2.0, h / 2.0, 0)
		var tr := pos + Vector3(w / 2.0, h / 2.0, 0)
		var br := pos + Vector3(w / 2.0, -h / 2.0, 0)
		var bl := pos + Vector3(-w / 2.0, -h / 2.0, 0)
		for v in [[tl, Vector2(0, 0)], [tr, Vector2(1, 0)], [br, Vector2(1, 1)], [tl, Vector2(0, 0)], [br, Vector2(1, 1)], [bl, Vector2(0, 1)]]:
			st.set_color(seed)
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(v[1])
			st.add_vertex(v[0])

	func commit(parent: Node3D) -> void:
		for k in tools:
			_emit(parent, (tools[k] as SurfaceTool).commit(), mats[k], shadow[k])
		for k in quads:
			_emit(parent, (quads[k] as SurfaceTool).commit(), mats[k], false)

	func _emit(parent: Node3D, mesh: Mesh, m: Material, cast: bool) -> void:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)


static func build(L: float) -> Dictionary:
	var root := Node3D.new()
	var R := RandomNumberGenerator.new()
	R.seed = 7
	var B := Batch.new()
	var WW := L + 160.0

	# ---------------- matières
	var walls := [
		Shaders.mat("wall", {"style": 0, "brick_a": Color("#7a3326"), "brick_b": Color("#4e1f19"), "mortar": Color("#5a5450")}),
		Shaders.mat("wall", {"style": 1, "brick_a": Color("#3d5a66"), "mortar": Color("#2a3c44")}),
		Shaders.mat("wall", {"style": 0, "brick_a": Color("#4a3a52"), "brick_b": Color("#2e2436"), "mortar": Color("#47424c")}),
		Shaders.mat("wall", {"style": 2, "brick_a": Color("#5e5a62")}),
		Shaders.mat("wall", {"style": 0, "brick_a": Color("#8a5a3a"), "brick_b": Color("#5e3a24"), "mortar": Color("#6a625a"), "brick": Vector2(0.78, 0.28)}),
		Shaders.mat("wall", {"style": 1, "brick_a": Color("#6e4a5a"), "mortar": Color("#4a3040")}),
	]
	var stone := Shaders.mat("wall", {"style": 1, "brick_a": Color("#8a8580"), "mortar": Color("#5a5652"), "wet": 0.9})
	var dark_stone := Shaders.mat("wall", {"style": 1, "brick_a": Color("#2e2c30"), "mortar": Color("#1a191c")})
	var iron := Shaders.mat("metal", {"paint": Color("#14161a"), "chips": 0.5, "metal": 0.7})
	var frame_m := Shaders.mat("metal", {"paint": Color("#1c1a20"), "chips": 0.2, "metal": 0.5})
	var light_metal := Shaders.mat("metal", {"paint": Color("#8a8e94"), "chips": 0.3, "metal": 0.8})
	var green_m := Shaders.mat("metal", {"paint": Color("#1f4a36"), "chips": 0.5, "metal": 0.3})
	var red_m := Shaders.mat("metal", {"paint": Color("#a8261e"), "chips": 0.6, "metal": 0.3})
	var yellow_m := Shaders.mat("metal", {"paint": Color("#d8a820"), "chips": 0.4, "metal": 0.2})
	var blue_m := Shaders.mat("metal", {"paint": Color("#1e4a8a"), "chips": 0.4, "metal": 0.2})
	var wood := Shaders.mat("wall", {"style": 1, "brick_a": Color("#5a3a22"), "mortar": Color("#3a2414")})
	var shutter := Shaders.mat("corrugated", {"base": Color("#6a6e74"), "ribs": 7.0, "tags": 1.0})
	var roof_m := Shaders.mat("tiles", {"tile_a": Color("#2a2a2e"), "tile_b": Color("#222226"), "tile": Vector2(2.0, 2.0)})
	var win_m := Shaders.mat("window", {"size": Vector2(2.4, 2.8), "depth": 1.1, "lit_chance": 0.42})
	var shop_mats := [
		Shaders.mat("window", {"size": Vector2(6.4, 3.4), "depth": 0.9, "shop": true, "shop_light": Color("#ffd8a8")}),
		Shaders.mat("window", {"size": Vector2(6.4, 3.4), "depth": 0.9, "shop": true, "shop_light": Color("#a8e8ff")}),
		Shaders.mat("window", {"size": Vector2(6.4, 3.4), "depth": 0.9, "shop": true, "shop_light": Color("#ffb0d8")}),
	]
	var door_glass := Shaders.mat("window", {"size": Vector2(1.9, 3.4), "depth": 2.5, "lit_chance": 0.7})
	var awn_m := [_stripes(Color("#a8324a"), Color("#e8e0d0")), _stripes(Color("#2a7a7a"), Color("#d8e8e0")), _stripes(Color("#1e3a6a"), Color("#d8c8a0"))]

	# ---------------- sol
	var road := PlaneMesh.new()
	road.size = Vector2(WW, 48)
	var crossings := Vector4(L * 0.31, L * 0.73, -999.0, -999.0)
	StageBuilder.add(root, road, Shaders.mat("asphalt", {"crossings": crossings}), Vector3(L / 2.0, 0, -3.2 + 24.0), false)
	var sidewalk := Shaders.mat("tiles", {"tile_a": Color("#4a4652"), "tile_b": Color("#3a3742"), "grout": Color("#1e1c22")})
	StageBuilder.add(root, StageBuilder.box(WW, 0.32, 4.2), sidewalk, Vector3(L / 2.0, 0.16, -5.35), false)
	var curb := Shaders.mat("tiles", {"tile_a": Color("#7a7880"), "tile_b": Color("#6a6870"), "grout": Color("#3a383e"), "tile": Vector2(2.4, 2.4)})
	StageBuilder.add(root, StageBuilder.box(WW, 0.36, 0.34), curb, Vector3(L / 2.0, 0.17, -3.3))
	# caniveau sombre et grilles d'évacuation
	StageBuilder.add(root, StageBuilder.box(WW, 0.01, 0.35), Shaders.mat("tiles", {"tile_a": Color("#1a181e"), "tile_b": Color("#141218"), "gloss": 1.0}), Vector3(L / 2.0, 0.006, -2.95), false)
	var gx := 6.0
	while gx < L:
		B.box("grate", iron, Vector3(1.0, 0.03, 0.4), Vector3(gx, 0.012, -2.95), Vector3.ZERO, false)
		for k in 6:
			B.box("grate_slot", frame_m, Vector3(0.06, 0.035, 0.32), Vector3(gx - 0.38 + k * 0.15, 0.014, -2.95), Vector3.ZERO, false)
		gx += 21.0 + R.randf() * 10.0
	# mur sombre derrière les immeubles (on ne voit pas le vide entre deux bâtiments)
	StageBuilder.add(root, StageBuilder.box(WW, 40, 1), dark_stone, Vector3(L / 2.0, 20, -15.8), false)

	# ---------------- immeubles
	var signs := [["RAMEN 24H", "#ff4f8b"], ["LAVERIE", "#3fe0d0"], ["BAR LUNE", "#ffd23f"], ["ARCADE", "#b47dff"],
		["PRÊTEUR", "#7cff6b"], ["KARAOKÉ", "#ff7a3c"], ["TATOUAGE", "#3fe0d0"], ["HÔTEL", "#ff4f8b"]]
	var heights := [17.6, 21.4, 16.0, 19.8, 23.2, 18.4]
	var boardm := StageBuilder.mat("#0b0812", 0.5, 0.4)
	var leaf_m := StageBuilder.mat("#3a6a2e", 0.8)
	var neons := []
	var i := 0
	var bx := -25.6
	while bx < L + 30.0:
		var h: float = heights[i % heights.size()] + R.randf() * 1.2
		var wall: Material = walls[(i * 7 + 3) % walls.size()]
		var cx := bx + 6.4
		var depth_off := (R.randf() - 0.5) * 0.3
		var front := FRONT + depth_off
		B.box("wall%d" % walls.find(wall), wall, Vector3(12.6, h, 8.0), Vector3(cx, h / 2.0, front - 4.0))
		# -------- rez-de-chaussée
		var closed := i % 5 == 3
		B.box("stone", stone, Vector3(0.7, 5.3, 0.45), Vector3(bx + 0.35, 2.65, front + 0.15))
		B.box("stone", stone, Vector3(0.7, 5.3, 0.45), Vector3(bx + 12.25, 2.65, front + 0.15))
		B.box("stone", stone, Vector3(12.8, 0.35, 0.55), Vector3(cx, 5.1, front + 0.2))
		B.box("stone", dark_stone, Vector3(6.9, 0.65, 0.3), Vector3(bx + 4.2, 0.32, front + 0.12))
		if closed:
			B.box("shutter", shutter, Vector3(6.8, 3.6, 0.12), Vector3(bx + 4.2, 2.45, front + 0.08))
			B.box("frame", frame_m, Vector3(7.0, 0.55, 0.5), Vector3(bx + 4.2, 4.45, front + 0.2))
		else:
			B.quad("shop%d" % (i % 3), shop_mats[i % 3], 6.4, 3.4, Vector3(bx + 4.2, 2.4, front + 0.02), Color(R.randf(), R.randf(), R.randf()))
			for fx in [-3.25, 0.0, 3.25]:
				B.box("frame", frame_m, Vector3(0.14, 3.6, 0.16), Vector3(bx + 4.2 + fx, 2.4, front + 0.09))
			B.box("frame", frame_m, Vector3(6.7, 0.14, 0.16), Vector3(bx + 4.2, 4.15, front + 0.09))
			B.box("frame", frame_m, Vector3(6.7, 0.14, 0.18), Vector3(bx + 4.2, 0.68, front + 0.1))
			# petite enseigne « OUVERT » allumée dans la vitrine
			if R.randf() < 0.5:
				var ov := StageBuilder.neon(root, "OUVERT", Vector3(bx + 2.2, 3.4, front + 0.06), Color("#ff3048") if R.randf() < 0.5 else Color("#30b8ff"))
				ov.pixel_size = 0.0035
		# porte d'entrée de l'immeuble, en retrait
		B.box("frame", frame_m, Vector3(2.4, 4.0, 0.22), Vector3(bx + 10.0, 2.0, front + 0.06))
		B.quad("door", door_glass, 1.9, 3.4, Vector3(bx + 10.0, 1.9, front + 0.18), Color(R.randf(), R.randf(), R.randf()))
		B.box("stone", stone, Vector3(2.8, 0.25, 0.6), Vector3(bx + 10.0, 0.12, front + 0.3))
		# enseigne lumineuse
		var s: Array = signs[i % signs.size()]
		var sc := Color(s[1])
		B.box("board", boardm, Vector3(9.2, 1.8, 0.35), Vector3(cx, 5.95, front + 0.45))
		var tube := StageBuilder.emat(sc, 3.0)
		StageBuilder.add(root, StageBuilder.box(9.0, 0.08, 0.08), tube, Vector3(cx, 6.77, front + 0.64), false)
		StageBuilder.add(root, StageBuilder.box(9.0, 0.08, 0.08), tube, Vector3(cx, 5.13, front + 0.64), false)
		var lb := StageBuilder.neon(root, s[0], Vector3(cx, 5.95, front + 0.64), sc)
		var ol := StageBuilder.omni(root, Vector3(cx, 5.3, front + 2.0), sc, 2.4, 14.0)
		ol.light_volumetric_fog_energy = 2.5
		StageBuilder.road_reflection(root, cx, 7.5, sc, -3.1, 13.0, 1.9)
		StageBuilder.road_reflection(root, bx + 4.2, 6.0, Color("#ffe0c0"), -3.1, 7.0, 0.5 if not closed else 0.0)
		if i % 3 == 1:
			neons.append(StageBuilder.flicker([lb], [tube], [ol]))
		# store rayé au-dessus de la vitrine
		if i % 3 == 1 and not closed:
			var aw := StageBuilder.add(root, StageBuilder.box(7.2, 0.12, 2.0), awn_m[i % 3], Vector3(bx + 4.2, 4.65, front + 1.0))
			aw.rotation.x = 0.38
			B.box("frame", frame_m, Vector3(7.3, 0.12, 0.12), Vector3(bx + 4.2, 4.28, front + 1.92))
		# -------- étages
		var fy := 7.0
		var floor_i := 0
		while fy + 2.8 < h - 1.4:
			B.box("stone", stone, Vector3(12.7, 0.22, 0.3), Vector3(cx, fy - 0.75, front + 0.14))
			for fx in [2.5, 6.4, 10.3]:
				var wx: float = bx + fx
				var wy := fy + 1.4
				B.quad("win", win_m, 2.4, 2.8, Vector3(wx, wy, front + 0.015), Color(R.randf(), R.randf(), R.randf()))
				# encadrement en relief, rebord, linteau
				B.box("frame", frame_m, Vector3(2.64, 0.12, 0.16), Vector3(wx, wy + 1.46, front + 0.08))
				B.box("frame", frame_m, Vector3(0.12, 2.9, 0.16), Vector3(wx - 1.26, wy, front + 0.08))
				B.box("frame", frame_m, Vector3(0.12, 2.9, 0.16), Vector3(wx + 1.26, wy, front + 0.08))
				B.box("frame", frame_m, Vector3(0.07, 2.8, 0.1), Vector3(wx, wy, front + 0.06))
				B.box("frame", frame_m, Vector3(2.5, 0.07, 0.1), Vector3(wx, wy + 0.5, front + 0.06))
				B.box("stone", stone, Vector3(2.95, 0.17, 0.4), Vector3(wx, wy - 1.52, front + 0.2))
				B.box("stone", stone, Vector3(2.85, 0.34, 0.2), Vector3(wx, wy + 1.66, front + 0.1))
				var r := R.randf()
				if r < 0.13:
					# climatiseur avec sa grille
					B.box("ac", light_metal, Vector3(0.95, 0.62, 0.62), Vector3(wx + 0.6, wy - 1.95, front + 0.32))
					for g in 4:
						B.box("frame", frame_m, Vector3(0.8, 0.04, 0.02), Vector3(wx + 0.6, wy - 2.15 + g * 0.13, front + 0.64))
				elif r < 0.22:
					# jardinière
					B.box("wood", wood, Vector3(2.2, 0.32, 0.36), Vector3(wx, wy - 1.27, front + 0.32))
					for pl in 5:
						var leaf := SphereMesh.new()
						leaf.radius = 0.22
						leaf.height = 0.36
						leaf.radial_segments = 8
						leaf.rings = 4
						B.add("leaf", leaf_m, leaf, Transform3D(Basis(), Vector3(wx - 0.85 + pl * 0.42, wy - 1.0, front + 0.32)))
			fy += 3.9
			floor_i += 1
		# corniche et acrotère
		B.box("stone", stone, Vector3(12.9, 0.4, 0.7), Vector3(cx, h - 0.15, front + 0.25))
		B.box("stone", stone, Vector3(12.8, 0.18, 0.9), Vector3(cx, h + 0.12, front + 0.35))
		B.box("wall%d" % walls.find(wall), wall, Vector3(12.6, 0.9, 0.4), Vector3(cx, h + 0.6, front + 0.05))
		for d in 24:
			B.box("stone", stone, Vector3(0.22, 0.22, 0.25), Vector3(bx + 0.4 + d * 0.52, h - 0.48, front + 0.2))
		# descente d'eau pluviale
		B.cyl("pipe", iron, 0.09, 0.09, h - 0.4, Vector3(bx + 12.45, (h - 0.4) / 2.0, front + 0.28), 8)
		var by := 1.5
		while by < h - 1.0:
			B.box("pipe", iron, Vector3(0.3, 0.06, 0.3), Vector3(bx + 12.45, by, front + 0.2))
			by += 3.0
		# escalier de secours
		if i % 3 == 2:
			_fire_escape(B, iron, bx, front, h)
		# toit
		_roof(B, R, wood, iron, light_metal, roof_m, bx, front, h)
		# lampadaire
		if i % 2 == 0:
			_lamp(B, root, iron, frame_m, bx + 12.6)
		i += 1
		bx += 12.8

	# ---------------- mobilier urbain sur le trottoir
	var x := 3.0
	while x < L - 3.0:
		var near_lamp := fmod(x + 25.6 - 12.6, 25.6)
		if near_lamp < 1.6 or near_lamp > 24.0:
			x += 1.8
			continue
		var r := R.randf()
		var z := -4.05 if R.randf() < 0.7 else -6.6
		if r < 0.16:
			_hydrant(B, red_m, x, z)
		elif r < 0.34:
			_bin(B, green_m, iron, x, z)
		elif r < 0.44:
			_news_box(B, blue_m if R.randf() < 0.5 else red_m, frame_m, x, z)
		elif r < 0.56:
			for k in 2:
				B.cyl("bollard", iron, 0.09, 0.11, 0.9, Vector3(x + k * 1.2, 0.77, -3.75), 10)
				B.cyl("bollard", light_metal, 0.1, 0.1, 0.06, Vector3(x + k * 1.2, 1.1, -3.75), 10)
		elif r < 0.64:
			_bench(B, wood, iron, x, -6.7)
		elif r < 0.7:
			_mailbox(B, yellow_m, iron, x, z)
		x += 6.0 + R.randf() * 9.0
	# feux tricolores aux passages piétons
	for cxp in [crossings.x, crossings.y]:
		_traffic_light(B, root, iron, cxp - 2.6)

	# ---------------- plaques d'égout (dont une fumante)
	var steam_done := 0
	for k in 7:
		var mx := 10.0 + k * (L / 7.0) + R.randf() * 8.0
		var mz := 1.5 + R.randf() * 9.0
		B.cyl("manhole", iron, 0.85, 0.85, 0.04, Vector3(mx, 0.012, mz), 24, Vector3.ZERO, false)
		B.cyl("manhole_rim", light_metal, 0.95, 0.95, 0.02, Vector3(mx, 0.006, mz), 24, Vector3.ZERO, false)
		if steam_done < 3 and R.randf() < 0.6:
			root.add_child(_steam(Vector3(mx, 0.05, mz)))
			steam_done += 1

	B.commit(root)

	# ---------------- ville lointaine et lune
	StageBuilder.far_city(root, L, R)
	return {
		"node": root,
		"env": StageBuilder.make_env("#070514", "#7a2456", "#0b0814", "#2a1440", 0.011, 0.55),
		"sun": Color("#b8c8ff"), "sun_energy": 0.8, "rain": true, "neons": neons,
		"vfog": {"density": 0.009, "albedo": Color("#a898d0"), "emission": Color("#05020a")},
	}


static func _stripes(a: Color, b: Color) -> StandardMaterial3D:
	var img := Image.create(32, 2, false, Image.FORMAT_RGB8)
	for x in 32:
		for y in 2:
			img.set_pixel(x, y, a if (x / 4) % 2 == 0 else b)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_scale = Vector3(4, 1, 1)
	m.roughness = 0.85
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _fire_escape(B: Batch, iron: Material, bx: float, front: float, h: float) -> void:
	var x0 := bx + 1.0
	var w := 7.0
	var z := front + 0.75
	var fy := 10.15  # au-dessus de l'enseigne du rez-de-chaussée
	var level := 0
	while fy < h - 3.0:
		B.box("iron", iron, Vector3(w, 0.07, 1.4), Vector3(x0 + w / 2.0, fy, z))
		# garde-corps
		B.box("iron", iron, Vector3(w, 0.05, 0.05), Vector3(x0 + w / 2.0, fy + 1.0, z + 0.68))
		B.box("iron", iron, Vector3(w, 0.04, 0.04), Vector3(x0 + w / 2.0, fy + 0.5, z + 0.68))
		var px := 0.0
		while px <= w + 0.01:
			B.box("iron", iron, Vector3(0.035, 1.0, 0.035), Vector3(x0 + px, fy + 0.5, z + 0.68))
			px += 0.5
		for sx in [0.0, w]:
			B.box("iron", iron, Vector3(0.05, 0.05, 1.4), Vector3(x0 + sx, fy + 1.0, z))
		# consoles sous la plateforme
		for sx in [0.4, w - 0.4]:
			B.box("iron", iron, Vector3(0.06, 0.06, 1.5), Vector3(x0 + sx, fy - 0.45, z - 0.05), Vector3(-0.55, 0, 0))
		# escalier vers l'étage suivant
		if fy + 3.9 < h - 3.0:
			var left := level % 2 == 0
			var ax := x0 + (1.0 if left else w - 4.6)
			var ang := atan2(3.9, 3.6) * (1.0 if left else -1.0)
			B.box("iron", iron, Vector3(5.3, 0.06, 0.62), Vector3(ax + 1.8, fy + 1.95, z - 0.25), Vector3(0, 0, ang))
			for st in 9:
				var t := (st + 0.5) / 9.0
				var sxp := ax + (t * 3.6 if left else (1.0 - t) * 3.6)
				B.box("iron", iron, Vector3(0.36, 0.04, 0.6), Vector3(sxp, fy + t * 3.9 + 0.05, z - 0.25))
		fy += 3.9
		level += 1
	# échelle relevée sous la première plateforme
	for sx in [0.0, 0.5]:
		B.box("iron", iron, Vector3(0.04, 2.6, 0.04), Vector3(x0 + w - 1.0 + sx, 10.15 - 1.3, z + 0.5))
	for r in 7:
		B.box("iron", iron, Vector3(0.5, 0.035, 0.035), Vector3(x0 + w - 0.75, 10.15 - 0.3 - r * 0.36, z + 0.5))


static func _roof(B: Batch, R: RandomNumberGenerator, wood: Material, iron: Material, light_metal: Material, roof_m: Material, bx: float, front: float, h: float) -> void:
	B.box("roof", roof_m, Vector3(12.4, 0.1, 7.6), Vector3(bx + 6.4, h + 0.05, front - 4.0), Vector3.ZERO, false)
	if R.randf() < 0.55:
		# réservoir d'eau en bois sur pieds
		var tx := bx + 3.0 + R.randf() * 6.0
		var tz := front - 4.5
		for lx in [-1.0, 1.0]:
			for lz in [-1.0, 1.0]:
				B.box("iron", iron, Vector3(0.12, 2.0, 0.12), Vector3(tx + lx, h + 1.0, tz + lz))
		B.cyl("tank", wood, 1.45, 1.45, 2.4, Vector3(tx, h + 3.2, tz), 16)
		B.cyl("tank_roof", iron, 0.1, 1.6, 0.9, Vector3(tx, h + 4.85, tz), 16)
		for band in 3:
			B.cyl("iron", iron, 1.48, 1.48, 0.06, Vector3(tx, h + 2.3 + band * 0.9, tz), 16)
	if R.randf() < 0.7:
		B.box("ac", light_metal, Vector3(1.6, 1.0, 1.2), Vector3(bx + 2.0 + R.randf() * 8.0, h + 0.55, front - 2.0))
	if R.randf() < 0.5:
		var ax := bx + 1.0 + R.randf() * 10.0
		B.cyl("iron", iron, 0.03, 0.05, 4.0, Vector3(ax, h + 2.0, front - 3.0), 6)
		B.box("iron", iron, Vector3(1.6, 0.04, 0.04), Vector3(ax, h + 3.4, front - 3.0))
		B.box("iron", iron, Vector3(1.0, 0.04, 0.04), Vector3(ax, h + 3.8, front - 3.0))


static func _lamp(B: Batch, root: Node3D, iron: Material, frame_m: Material, lx: float) -> void:
	var z := -4.2
	B.cyl("lamp", iron, 0.28, 0.34, 0.7, Vector3(lx, 0.35 + 0.3, z), 12)
	B.cyl("lamp", iron, 0.2, 0.24, 0.2, Vector3(lx, 1.05, z), 12)
	B.cyl("lamp", iron, 0.1, 0.15, 7.8, Vector3(lx, 4.95, z), 12)
	B.cyl("lamp", iron, 0.14, 0.14, 0.12, Vector3(lx, 2.6, z), 12)
	# bras courbé en trois segments
	B.box("lamp", iron, Vector3(0.8, 0.09, 0.09), Vector3(lx - 0.32, 8.95, z), Vector3(0, 0, 0.5))
	B.box("lamp", iron, Vector3(0.9, 0.09, 0.09), Vector3(lx - 1.05, 9.17, z), Vector3(0, 0, 0.1))
	B.box("lamp", iron, Vector3(0.5, 0.09, 0.09), Vector3(lx - 1.6, 9.12, z), Vector3(0, 0, -0.35))
	# tête du lampadaire et vasque lumineuse
	B.box("lamp", frame_m, Vector3(1.1, 0.22, 0.6), Vector3(lx - 1.75, 8.95, z))
	B.box("lamp", frame_m, Vector3(0.9, 0.1, 0.45), Vector3(lx - 1.75, 9.1, z))
	StageBuilder.add(root, StageBuilder.box(0.95, 0.06, 0.5), StageBuilder.unlit("#fff1cf", 4.0), Vector3(lx - 1.75, 8.82, z), false)
	var sl := SpotLight3D.new()
	sl.position = Vector3(lx - 1.75, 8.75, z)
	sl.rotation.x = -PI / 2.0
	sl.light_color = Color("#ffd9a0")
	sl.light_energy = 7.0
	sl.spot_range = 14.0
	sl.spot_angle = 42.0
	sl.light_volumetric_fog_energy = 9.0
	root.add_child(sl)
	StageBuilder.light_cone(root, Vector3(lx - 1.75, 8.78, z), 8.7, 3.2, Color("#ffd9a0"), 0.55)
	StageBuilder.road_reflection(root, lx - 1.75, 2.4, Color("#ffd9a0"), -2.8, 11.0, 1.8)


static func _hydrant(B: Batch, m: Material, x: float, z: float) -> void:
	B.cyl("hydrant", m, 0.22, 0.26, 0.9, Vector3(x, 0.77, z), 12)
	B.cyl("hydrant", m, 0.17, 0.22, 0.25, Vector3(x, 1.33, z), 12)
	B.cyl("hydrant", m, 0.3, 0.3, 0.08, Vector3(x, 0.4, z), 12)
	B.cyl("hydrant", m, 0.08, 0.08, 0.7, Vector3(x, 0.95, z), 8, Vector3(0, 0, PI / 2.0))


static func _bin(B: Batch, m: Material, iron: Material, x: float, z: float) -> void:
	B.cyl("bin", m, 0.42, 0.36, 1.2, Vector3(x, 0.92, z), 14)
	B.cyl("bin", iron, 0.46, 0.46, 0.1, Vector3(x, 1.55, z), 14)
	B.cyl("bin", iron, 0.15, 0.15, 0.12, Vector3(x, 1.65, z), 8)


static func _news_box(B: Batch, m: Material, frame_m: Material, x: float, z: float) -> void:
	B.box("news", m, Vector3(0.75, 1.05, 0.6), Vector3(x, 0.85, z))
	B.box("news", frame_m, Vector3(0.6, 0.4, 0.04), Vector3(x, 1.05, z + 0.31))
	for lx in [-0.3, 0.3]:
		B.box("news", frame_m, Vector3(0.05, 0.35, 0.05), Vector3(x + lx, 0.5, z))


static func _bench(B: Batch, wood: Material, iron: Material, x: float, z: float) -> void:
	for k in 3:
		B.box("bench", wood, Vector3(2.4, 0.07, 0.16), Vector3(x, 0.85, z - 0.2 + k * 0.2))
	for k in 2:
		B.box("bench", wood, Vector3(2.4, 0.14, 0.06), Vector3(x, 1.2 + k * 0.22, z - 0.36), Vector3(-0.15, 0, 0))
	for lx in [-1.0, 1.0]:
		B.box("bench", iron, Vector3(0.08, 0.55, 0.5), Vector3(x + lx, 0.6, z))
		B.box("bench", iron, Vector3(0.06, 0.7, 0.06), Vector3(x + lx, 1.2, z - 0.36))


static func _mailbox(B: Batch, m: Material, iron: Material, x: float, z: float) -> void:
	B.cyl("mail", iron, 0.06, 0.06, 1.0, Vector3(x, 0.82, z), 8)
	B.box("mail", m, Vector3(0.6, 0.75, 0.4), Vector3(x, 1.55, z))
	B.box("mail", iron, Vector3(0.4, 0.05, 0.05), Vector3(x, 1.7, z + 0.21))


static func _traffic_light(B: Batch, root: Node3D, iron: Material, x: float) -> void:
	var z := -3.8
	B.cyl("tl", iron, 0.09, 0.12, 4.6, Vector3(x, 2.62, z), 10)
	B.box("tl", iron, Vector3(0.5, 1.4, 0.45), Vector3(x, 5.3, z + 0.1))
	B.box("tl", iron, Vector3(0.62, 0.06, 0.2), Vector3(x, 6.02, z + 0.3))
	var cols := ["#ff2a1e", "#ffb21e", "#2aff6a"]
	for k in 3:
		var on := k == 0
		var lm := StageBuilder.emat(cols[k], 3.0 if on else 0.15)
		var lens := SphereMesh.new()
		lens.radius = 0.15
		lens.height = 0.3
		StageBuilder.add(root, lens, lm, Vector3(x, 5.75 - k * 0.42, z + 0.33), false)
		B.box("tl", iron, Vector3(0.36, 0.05, 0.2), Vector3(x, 5.92 - k * 0.42, z + 0.42))
	StageBuilder.road_reflection(root, x, 0.8, Color("#ff2a1e"), -2.8, 6.0, 1.0)


static func _steam(pos: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = 26
	p.lifetime = 3.2
	p.preprocess = 3.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.5
	pm.direction = Vector3(0.15, 1, 0)
	pm.spread = 14.0
	pm.initial_velocity_min = 0.7
	pm.initial_velocity_max = 1.2
	pm.gravity = Vector3(0.15, 0.25, 0)
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.4))
	sc.add_point(Vector2(1, 2.6))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.2, Color(1, 1, 1, 0.22))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 1.6)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(0.78, 0.74, 0.86)
	var rg := Gradient.new()
	rg.set_color(0, Color(1, 1, 1, 1))
	rg.set_color(1, Color(1, 1, 1, 0))
	var rt := GradientTexture2D.new()
	rt.gradient = rg
	rt.fill = GradientTexture2D.FILL_RADIAL
	rt.fill_from = Vector2(0.5, 0.5)
	rt.fill_to = Vector2(1.0, 0.5)
	m.albedo_texture = rt
	m.disable_receive_shadows = true
	q.material = m
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-4, -1, -4), Vector3(8, 12, 8))
	return p
