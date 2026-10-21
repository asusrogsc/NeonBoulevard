class_name Rig
extends Node3D
## Modèle 3D articulé d'un combattant, construit à partir de formes simples.
## Le personnage regarde vers +X ; on le retourne avec scale.x = -1.

const D := PI / 180.0

var u := 0.1
var look: Dictionary
var mats: Array = []
var tilt: Node3D
var pelvis: Node3D
var torso: Node3D
var neck: Node3D
var leg_f: Dictionary
var leg_b: Dictionary
var arm_f: Dictionary
var arm_b: Dictionary
var pony: Node3D = null
var cur := {}
var flash_state := "none"
var weapon_kind := ""
var weapon_node: Node3D = null


func _init(lk: Dictionary) -> void:
	look = lk
	u = 0.1 * float(lk.s)
	_build()


func _mat(col: String, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col)
	m.roughness = rough
	m.metallic = metal
	m.emission_enabled = true
	m.emission = Color(0, 0, 0)
	# lumière de contour : détache les personnages du décor sombre
	m.rim_enabled = true
	m.rim = 0.45
	m.rim_tint = 0.6
	mats.append(m)
	return m


func _mi(mesh: Mesh, mat: Material, parent: Node3D, pos := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0 + 0.002)
	c.radial_segments = 16
	c.rings = 6
	return c


func _sphere(r: float, hemi := false) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r if hemi else r * 2.0
	s.is_hemisphere = hemi
	s.radial_segments = 24
	s.rings = 12
	return s


func _cyl(rt: float, rb: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = 16
	return c


func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


func _limb(parent: Node3D, r: float, length: float, mat: Material, pos: Vector3) -> Node3D:
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)
	_mi(_capsule(r * u, (length + r) * u), mat, g, Vector3(0, -length * 0.5 * u, 0))
	return g


func _leg(z: float, M: Dictionary) -> Dictionary:
	var b: float = look.bulk
	var th := _limb(pelvis, 2.7 * b, 11.0, M.pants, Vector3(0, 0, z * u))
	var kn := _limb(th, 2.25 * b, 11.0, M.pants, Vector3(0, -11.0 * u, 0))
	var ft := Node3D.new()
	ft.position = Vector3(0, -11.0 * u, 0)
	kn.add_child(ft)
	var fw: float = 3.4 * maxf(1.0, b * 0.85)
	_mi(_box(6.2 * u, 2.6 * u, fw * u), M.shoe, ft, Vector3(1.7 * u, -0.2 * u, 0))
	_mi(_box(6.4 * u, 0.7 * u, (fw + 0.2) * u), M.acc, ft, Vector3(1.7 * u, -1.3 * u, 0))
	return {"th": th, "kn": kn, "ft": ft}


func _arm(z: float, up: Material, lo: Material, M: Dictionary) -> Dictionary:
	var b: float = look.bulk
	var sh := _limb(torso, 2.0 * b * 0.9, 7.5, up, Vector3(0, 12.6 * u, z * u))
	sh.rotation.x = 0.1 if z > 0.0 else -0.1
	var el := _limb(sh, 1.8 * b * 0.9, 7.5, lo, Vector3(0, -7.5 * u, 0))
	if look.get("sleeve", 0) and not look.get("coat", 0):
		_mi(_cyl(1.95 * b * 0.9 * u, 1.95 * b * 0.9 * u, 1.2 * u), M.acc, el, Vector3(0, -5.6 * u, 0))
	_mi(_sphere(2.2 * u * maxf(1.0, b * 0.85)), M.skin, el, Vector3(0, -8.0 * u, 0))
	return {"sh": sh, "el": el}


func _cap(thl: float, sc: float, rz: float, mat: Material, hr: float, yo := 0.0) -> MeshInstance3D:
	# calotte de cheveux : une demi-sphère inclinée vers l'arrière
	var drop := (thl - 0.5) * 2.0 * hr * sc
	var m := _mi(_sphere(hr * sc, true), mat, neck, Vector3(0.2 * u, (5.0 + yo) * u - drop, 0))
	m.scale = Vector3(1.0, 1.07 + (thl - 0.5), 0.96)
	m.rotation.z = rz
	return m


func _build() -> void:
	var b: float = look.bulk
	var M := {
		"skin": _mat(look.skin, 0.5),
		"hair": _mat(look.hair, 0.4, 0.05),
		"top": _mat(look.top, 0.62),
		"pants": _mat(look.pants, 0.78),
		"shoe": _mat(look.shoe, 0.32, 0.15),
		"acc": _mat(look.acc, 0.45),
		"eye": _mat("#120e18", 0.15, 0.2),
	}
	tilt = Node3D.new()
	add_child(tilt)
	pelvis = Node3D.new()
	tilt.add_child(pelvis)
	leg_b = _leg(-2.6 * b, M)
	leg_f = _leg(2.6 * b, M)

	torso = Node3D.new()
	pelvis.add_child(torso)
	_mi(_cyl(4.0 * b * u, 4.4 * b * u, 5.0 * u), M.pants, torso, Vector3(0, 0.6 * u, 0))
	_mi(_cyl(4.2 * b * u, 4.2 * b * u, 1.3 * u), M.acc, torso, Vector3(0, 2.8 * u, 0))
	var ch := _mi(_capsule(4.1 * b * u, (7.0 + 8.2 * b) * u), M.top, torso, Vector3(0, 9.0 * u, 0))
	ch.scale = Vector3(0.88, 1.0, 1.28)
	if not look.get("sleeve", 0) and not look.get("coat", 0):
		for zz in [-1.0, 1.0]:
			_mi(_sphere(2.3 * b * u), M.skin, torso, Vector3(0, 12.6 * u, zz * 4.6 * b * u))
	_mi(_cyl(1.7 * u * b * 0.9, 1.9 * u * b * 0.9, 3.4 * u), M.skin, torso, Vector3(0.2 * u, 15.0 * u, 0))
	if look.get("coat", 0):
		var coat := _mat(look.top, 0.62)
		coat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var cm := _cyl(4.8 * b * u, 6.4 * b * u, 10.0 * u)
		cm.cap_top = false
		cm.cap_bottom = false
		_mi(cm, coat, torso, Vector3(-0.3 * u, -2.4 * u, 0))
		_mi(_box(0.8 * u, 8.0 * u, 1.6 * u), M.acc, torso, Vector3(4.1 * b * u * 0.9, 10.0 * u, 0))

	neck = Node3D.new()
	neck.position.y = 15.5 * u
	torso.add_child(neck)
	var hr := 4.9 * u
	var head := _mi(_sphere(hr), M.skin, neck, Vector3(0.4 * u, 5.0 * u, 0))
	head.scale = Vector3(1.0, 1.07, 0.94)
	_mi(_sphere(1.1 * u), M.skin, neck, Vector3(4.8 * u, 4.6 * u, 0))
	for zz in [-1.0, 1.0]:
		_mi(_sphere(0.7 * u), M.eye, neck, Vector3(4.3 * u, 5.7 * u, zz * 1.75 * u))
		_mi(_box(0.6 * u, 0.45 * u, 2.0 * u), M.hair, neck, Vector3(4.4 * u, 7.1 * u, zz * 1.8 * u))
		_mi(_sphere(1.0 * u), M.skin, neck, Vector3(0.2 * u, 5.0 * u, zz * 4.5 * u))

	match look.hs:
		"pony":
			_cap(0.56, 1.07, 0.5, M.hair, hr)
			pony = Node3D.new()
			pony.position = Vector3(-4.4 * u, 7.2 * u, 0)
			neck.add_child(pony)
			_mi(_cyl(1.25 * u, 1.25 * u, 0.9 * u), M.acc, pony)
			_mi(_capsule(1.7 * u, 10.4 * u), M.hair, pony, Vector3(0, -4.6 * u, 0))
			_mi(_sphere(1.3 * u), M.hair, pony, Vector3(0, -9.4 * u, 0))
		"buzz":
			_cap(0.46, 1.03, 0.38, M.hair, hr)
		"mohawk":
			var mh := _mi(_box(9.5 * u, 4.6 * u, 1.8 * u), M.hair, neck, Vector3(-0.6 * u, 10.0 * u, 0))
			mh.rotation.z = 0.12
			for i in 4:
				var cone := _cyl(0.0, 1.0 * u, 3.0 * u)
				var sp := _mi(cone, M.hair, neck, Vector3((-4.0 + i * 2.6) * u, 12.4 * u, 0))
				sp.rotation.z = 0.4 - i * 0.18
		"hood":
			_cap(0.74, 1.24, 1.05, M.top, hr, -0.4)
		"slick":
			_cap(0.5, 1.05, 0.42, M.hair, hr)
			_mi(_box(3.4 * u, 2.6 * u, 6.0 * u), M.hair, neck, Vector3(2.8 * u, 2.6 * u, 0))
			var glasses := _mat("#0a0a0c", 0.1, 0.9)
			_mi(_box(1.2 * u, 1.4 * u, 5.6 * u), glasses, neck, Vector3(4.6 * u, 5.9 * u, 0))
	if look.get("band", 0):
		_mi(_cyl(hr * 1.02, hr * 1.02, 1.6 * u), M.acc, neck, Vector3(0.3 * u, 7.4 * u, 0))
		var tl := _mi(_box(4.0 * u, 1.2 * u, 0.8 * u), M.acc, neck, Vector3(-6.0 * u, 6.6 * u, -1.0 * u))
		tl.rotation.z = -0.5

	var up_mat: Material = M.top if look.get("sleeve", 0) else M.skin
	var lo_mat: Material = M.top if look.get("coat", 0) else M.skin
	arm_b = _arm(-5.4 * b, up_mat, lo_mat, M)
	arm_f = _arm(5.4 * b, up_mat, lo_mat, M)


func apply_pose(p: Dictionary, dt: float, snap := false) -> void:
	var py := 0.0
	var rot := 0.0
	var ox := 0.0
	var ty := 0.0
	if p.has("rot"):
		py = 22.0
		rot = float(p.rot)
		ox = float(p.get("ox", 0.0))
		ty = 3.4 * minf(1.0, rot / 90.0) + float(p.get("lift", 0.0))
	else:
		py = Pose.hip_height(p)
	py += 1.0
	var fl: Array = p.get("fl", [10, 10])
	var bl: Array = p.get("bl", [-10, 10])
	var fa: Array = p.get("fa", [30, 100])
	var ba: Array = p.get("ba", [15, 100])
	var T := {
		"lean": -float(p.get("lean", 0.0)) * D, "ht": -float(p.get("ht", 0.0)) * D,
		"f0": float(fl[0]) * D, "f1": -float(fl[1]) * D, "b0": float(bl[0]) * D, "b1": -float(bl[1]) * D,
		"a0": float(fa[0]) * D, "a1": float(fa[1]) * D, "c0": float(ba[0]) * D, "c1": float(ba[1]) * D,
		"py": py, "rot": rot * D, "ox": ox, "ty": ty,
	}
	var k := 1.0 if snap else 1.0 - exp(-dt * 26.0)
	for key in T:
		if cur.has(key):
			cur[key] = lerpf(cur[key], T[key], k)
		else:
			cur[key] = T[key]
	var c := cur
	torso.rotation.z = c.lean
	neck.rotation.z = c.ht
	leg_f.th.rotation.z = c.f0
	leg_f.kn.rotation.z = c.f1
	leg_b.th.rotation.z = c.b0
	leg_b.kn.rotation.z = c.b1
	var air: bool = p.get("air", false)
	var ff := 0.25 if air else clampf(1.0 - absf(c.f0) / (60.0 * D), 0.0, 1.0)
	var fb := 0.25 if air else clampf(1.0 - absf(c.b0) / (60.0 * D), 0.0, 1.0)
	leg_f.ft.rotation.z = -(c.f0 + c.f1) * ff
	leg_b.ft.rotation.z = -(c.b0 + c.b1) * fb
	arm_f.sh.rotation.z = c.a0
	arm_f.el.rotation.z = c.a1
	arm_b.sh.rotation.z = c.c0
	arm_b.el.rotation.z = c.c1
	pelvis.position.y = c.py * u
	tilt.rotation.z = c.rot
	tilt.position.x = c.ox * u
	tilt.position.y = c.ty * u
	if pony:
		pony.rotation.z = -0.45 + sin(Time.get_ticks_msec() * 0.007) * 0.12 - c.lean * 0.6


## Arme dans la main avant : "pipe" (tuyau), "knife" (couteau) ou "" (aucune).
func set_weapon(kind: String) -> void:
	weapon_kind = kind
	if weapon_node:
		weapon_node.queue_free()
		weapon_node = null
	if kind == "":
		return
	weapon_node = Node3D.new()
	weapon_node.position = Vector3(0.5 * u, -8.0 * u, 0)
	arm_f.el.add_child(weapon_node)
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("#a9b2c4")
	steel.metallic = 0.9
	steel.roughness = 0.25
	var grip := StandardMaterial3D.new()
	grip.albedo_color = Color("#1a1416")
	grip.roughness = 0.7
	if kind == "pipe":
		_mi(_cyl(0.8 * u, 0.8 * u, 22.0 * u), steel, weapon_node, Vector3(0, -8.0 * u, 0))
		_mi(_cyl(1.05 * u, 1.05 * u, 1.4 * u), steel, weapon_node, Vector3(0, -18.6 * u, 0))
		_mi(_cyl(1.0 * u, 1.0 * u, 4.0 * u), grip, weapon_node, Vector3(0, 1.0 * u, 0))
	else:
		_mi(_box(1.0 * u, 4.0 * u, 1.3 * u), grip, weapon_node, Vector3(0, 0.6 * u, 0))
		_mi(_box(1.8 * u, 0.5 * u, 2.2 * u), steel, weapon_node, Vector3(0, -1.6 * u, 0))
		_mi(_box(0.35 * u, 8.0 * u, 1.5 * u), steel, weapon_node, Vector3(0.2 * u, -6.0 * u, 0))


func set_flash(mode: String) -> void:
	if mode == flash_state:
		return
	flash_state = mode
	var col := Color(0, 0, 0)
	var energy := 0.0
	if mode == "w":
		col = Color(1, 1, 1)
		energy = 0.9
	elif mode == "r":
		col = Color(1, 0.12, 0.18)
		energy = 1.2
	for m in mats:
		m.emission = col
		m.emission_energy_multiplier = energy
