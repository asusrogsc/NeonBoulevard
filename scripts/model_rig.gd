class_name ModelRig
extends Node3D
## Personnage importé (GLB / FBX riggé, squelette DAZ Genesis ou proche) piloté par les
## mêmes poses que Rig (voir pose.gd). Même interface : apply_pose, set_flash, set_weapon.
## Le jeu regarde vers +X ; le modèle importé regarde vers +Z (convention DAZ / glTF).
## Les vêtements DAZ ont chacun leur copie du squelette (head_2, pelvis_3…) : chaque
## rotation est appliquée à l'os ET à toutes ses copies.

const D := PI / 180.0
const RIG_HEIGHT := 48.7  # hauteur du modèle en code (px de jeu), pour garder la même taille

var ok := false
var u := 0.1
var k := 1.0
var look: Dictionary
var tilt: Node3D
var yaw: Node3D
var skel: Skeleton3D   # squelette principal (corps)
var skels: Array = []  # tous les squelettes : l'import en crée parfois un par vêtement
var cur := {}
var flash_state := "none"
var weapon_kind := ""
var weapon_node: Node3D = null
var mats: Array = []
var groups := {}      # squelette principal : nom de base -> [index des os (original + copies)]
var down_r := Basis.IDENTITY
var down_l := Basis.IDENTITY
var feet: Array = []
var foot_rest := 0.0
var hand: BoneAttachment3D


func _init(lk: Dictionary) -> void:
	look = lk
	u = 0.1 * float(lk.get("s", 1.0))
	var ps: PackedScene = load(lk.model)
	if ps == null:
		return
	var model: Node3D = ps.instantiate()
	var found := model.find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		model.free()
		return
	skel = found[0]
	for s in found:
		if (s as Skeleton3D).find_bone("rShldrBend") >= 0 and (s as Skeleton3D).find_bone("head") >= 0:
			skel = s
			break
	for ap in model.find_children("*", "AnimationPlayer", true, false):
		ap.queue_free()
	for s in found:
		(s as Skeleton3D).reset_bone_poses()
	tilt = Node3D.new()
	add_child(tilt)
	yaw = Node3D.new()
	yaw.rotation.y = PI / 2.0
	tilt.add_child(yaw)
	yaw.add_child(model)
	for s in found:
		skels.append(_index_bones(s))
	groups = skels[found.find(skel)].groups
	var head := skel.find_bone("head")
	var top := 1.75
	if head >= 0:
		top = skel.get_bone_global_rest(head).origin.y + 0.16
	k = RIG_HEIGHT * u / top * float(lk.get("model_scale", 1.0))
	yaw.scale = Vector3(k, k, k)
	# bras : de la T-pose vers le long du corps
	down_r = _down_basis("rShldrBend", "rForearmBend", Vector3(-0.12, -1, 0))
	down_l = _down_basis("lShldrBend", "lForearmBend", Vector3(0.12, -1, 0))
	for n in ["lToe", "rToe", "lHeel", "rHeel", "lFoot", "rFoot"]:
		var b := skel.find_bone(n)
		if b >= 0:
			feet.append(b)
	foot_rest = INF
	for b in feet:
		foot_rest = minf(foot_rest, skel.get_bone_global_rest(b).origin.y)
	_collect_materials(model)
	var hb := skel.find_bone("rHand")
	if hb >= 0:
		hand = BoneAttachment3D.new()
		hand.bone_name = "rHand"
		skel.add_child(hand)
	ok = true


func _index_bones(sk: Skeleton3D) -> Dictionary:
	var re := RegEx.create_from_string("^(.*)_(\\d+)$")
	var d := {"skel": sk, "groups": {}, "base_of": {}, "rest": {}}
	for i in sk.get_bone_count():
		var n := sk.get_bone_name(i)
		var m := re.search(n)
		var base := n
		if m:
			base = m.get_string(1)
		d.base_of[i] = base
		if not d.groups.has(base):
			d.groups[base] = []
		d.groups[base].append(i)
		d.rest[i] = sk.get_bone_global_rest(i).basis.orthonormalized()
	return d


func _down_basis(a: String, b: String, target: Vector3) -> Basis:
	var ia := skel.find_bone(a)
	var ib := skel.find_bone(b)
	if ia < 0 or ib < 0:
		return Basis.IDENTITY
	var dir := (skel.get_bone_global_rest(ib).origin - skel.get_bone_global_rest(ia).origin).normalized()
	return Basis(Quaternion(dir, target.normalized()))


func _collect_materials(model: Node) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		for si in mesh.get_surface_count():
			var m = mi.get_active_material(si)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.emission_enabled = true
				d.emission = Color(0, 0, 0)
				d.rim_enabled = true
				d.rim = 0.35
				d.rim_tint = 0.6
				mi.set_surface_override_material(si, d)
				mats.append(d)


## rotation de jeu autour de +Z (personnage tourné vers +X) -> espace du modèle (tourné vers +Z)
static func _g(theta: float) -> Basis:
	return Basis(Vector3.RIGHT, -theta)


func apply_pose(p: Dictionary, dt: float, snap := false) -> void:
	if not ok:
		return
	var rot := 0.0
	var ox := 0.0
	var ty := 0.0
	if p.has("rot"):
		rot = float(p.rot)
		ox = float(p.get("ox", 0.0))
		ty = 3.4 * minf(1.0, rot / 90.0) + float(p.get("lift", 0.0))
	var fl: Array = p.get("fl", [10, 10])
	var bl: Array = p.get("bl", [-10, 10])
	var fa: Array = p.get("fa", [30, 100])
	var ba: Array = p.get("ba", [15, 100])
	var T := {
		"lean": -float(p.get("lean", 0.0)) * D, "ht": -float(p.get("ht", 0.0)) * D,
		"f0": float(fl[0]) * D, "f1": -float(fl[1]) * D, "b0": float(bl[0]) * D, "b1": -float(bl[1]) * D,
		"a0": float(fa[0]) * D, "a1": float(fa[1]) * D, "c0": float(ba[0]) * D, "c1": float(ba[1]) * D,
		"rot": rot * D, "ox": ox, "ty": ty, "lift": float(p.get("lift", 0.0)),
	}
	var kk := 1.0 if snap else 1.0 - exp(-dt * 26.0)
	for key in T:
		cur[key] = lerpf(cur[key], T[key], kk) if cur.has(key) else T[key]
	var c := cur
	var air: bool = p.get("air", false)
	var ff := 0.25 if air else clampf(1.0 - absf(c.f0) / (60.0 * D), 0.0, 1.0)
	var fb := 0.25 if air else clampf(1.0 - absf(c.b0) / (60.0 * D), 0.0, 1.0)
	var L: float = c.lean
	# rotation voulue de chaque os, dans l'espace du squelette
	var E := {
		"abdomenLower": _g(L * 0.35), "abdomenUpper": _g(L * 0.7), "chestLower": _g(L),
		"neckLower": _g(L + c.ht * 0.5), "head": _g(L + c.ht),
		"rThighBend": _g(c.f0), "rShin": _g(c.f0 + c.f1), "rFoot": _g((c.f0 + c.f1) * (1.0 - ff)),
		"lThighBend": _g(c.b0), "lShin": _g(c.b0 + c.b1), "lFoot": _g((c.b0 + c.b1) * (1.0 - fb)),
		"rShldrBend": _g(L + c.a0) * down_r, "rForearmBend": _g(L + c.a0 + c.a1) * down_r,
		"lShldrBend": _g(L + c.c0) * down_l, "lForearmBend": _g(L + c.c0 + c.c1) * down_l,
	}
	# poings fermés
	var fr: Basis = E.rForearmBend
	var fl2: Basis = E.lForearmBend
	var curl := [0.8, 1.85, 2.6]
	for f in ["Index", "Mid", "Ring", "Pinky"]:
		for j in 3:
			E["r%s%d" % [f, j + 1]] = fr * Basis(Vector3.BACK, -curl[j])
			E["l%s%d" % [f, j + 1]] = fl2 * Basis(Vector3.BACK, curl[j])
	for j in 2:
		E["rThumb%d" % (j + 2)] = fr * Basis(Vector3.UP, 0.5 * (j + 1))
		E["lThumb%d" % (j + 2)] = fl2 * Basis(Vector3.UP, -0.5 * (j + 1))
	for d in skels:
		var sk: Skeleton3D = d.skel
		for base in E:
			if not d.groups.has(base):
				continue
			var Ec: Basis = E[base]
			for bi in d.groups[base]:
				var par := sk.get_bone_parent(bi)
				var Bp: Basis = d.rest[par] if par >= 0 else Basis.IDENTITY
				var Ep := _effective(d, par, E)
				var Bc: Basis = d.rest[bi]
				var local := (Ep * Bp).inverse() * (Ec * Bc)
				sk.set_bone_pose_rotation(bi, local.get_rotation_quaternion())
	skel.force_update_all_bone_transforms()
	# posé au sol : on garde le point le plus bas des pieds sur le sol
	var off := 0.0
	if air:
		off = float(c.lift) * u
	elif rot == 0.0:
		var low := INF
		for b in feet:
			low = minf(low, skel.get_bone_global_pose(b).origin.y)
		if low < INF:
			off = -(low - foot_rest) * k
	yaw.position.y = off
	tilt.rotation.z = c.rot
	tilt.position = Vector3(float(c.ox) * u, float(c.ty) * u, 0)


func _effective(d: Dictionary, bi: int, E: Dictionary) -> Basis:
	var sk: Skeleton3D = d.skel
	while bi >= 0:
		var base: String = d.base_of[bi]
		if E.has(base):
			return E[base]
		bi = sk.get_bone_parent(bi)
	return Basis.IDENTITY


func set_flash(mode: String) -> void:
	if mode == flash_state:
		return
	flash_state = mode
	var col := Color(0, 0, 0)
	var energy := 0.0
	if mode == "w":
		col = Color(1, 1, 1)
		energy = 0.7
	elif mode == "r":
		col = Color(1, 0.12, 0.18)
		energy = 1.0
	for m in mats:
		m.emission = col
		m.emission_energy_multiplier = energy


## Arme dans la main droite (côté caméra) : "pipe", "knife" ou "".
func set_weapon(kind: String) -> void:
	weapon_kind = kind
	if weapon_node:
		weapon_node.queue_free()
		weapon_node = null
	if kind == "" or hand == null:
		return
	weapon_node = Node3D.new()
	hand.add_child(weapon_node)
	# en T-pose l'avant-bras droit pointe vers -X : l'arme prolonge le poing dans cette direction
	weapon_node.transform = Transform3D(Basis(Vector3.BACK, -PI / 2.0), Vector3(-0.07, -0.01, 0.0))
	weapon_node.scale = Vector3.ONE * 0.8 / k
	var w := 0.1
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("#a9b2c4")
	steel.metallic = 0.9
	steel.roughness = 0.25
	var grip := StandardMaterial3D.new()
	grip.albedo_color = Color("#1a1416")
	grip.roughness = 0.7
	if kind == "pipe":
		_part(_cyl(0.8 * w, 22.0 * w), steel, Vector3(0, -8.0 * w, 0))
		_part(_cyl(1.05 * w, 1.4 * w), steel, Vector3(0, -18.6 * w, 0))
		_part(_cyl(1.0 * w, 4.0 * w), grip, Vector3(0, 1.0 * w, 0))
	else:
		_part(_box(Vector3(1.0, 4.0, 1.3) * w), grip, Vector3(0, 0.6 * w, 0))
		_part(_box(Vector3(1.8, 0.5, 2.2) * w), steel, Vector3(0, -1.6 * w, 0))
		_part(_box(Vector3(0.35, 8.0, 1.5) * w), steel, Vector3(0.2 * w, -6.0 * w, 0))


func _part(mesh: Mesh, m: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	weapon_node.add_child(mi)


func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 12
	return c


func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b
