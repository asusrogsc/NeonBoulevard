extends SceneTree
## Allège un personnage DAZ importé en FBX et l'exporte en GLB pour le jeu.
## Usage (dans un projet Godot, depuis un terminal) :
##   godot --headless --script res://outils/daz_vers_glb.gd -- res://chemin/perso.fbx res://models/perso.glb
## Corrige les défauts d'export DAZ (squelette décalé, lunettes non riggées, peau qui traverse
## les vêtements), allège la géométrie et réduit les textures à 1024 px.
## Les réglages KEEP (part de triangles gardée) visent la tenue de Lindsay : à adapter pour un autre personnage.

# Part des triangles à garder pour chaque maillage (repéré par le début de son nom)
const KEEP := {
	"CathyHair": 0.2, "Vivian_High_Boots": 0.4, "glasses": 0.15, "lsoskirt": 0.6,
	"Genesis3Female": 0.5, "lsotop": 0.7, "EEnvy": 0.5,
}
# Surfaces inutiles en jeu (cachées sous les vêtements, ou exportées opaques par DAZ)
const DROP := ["Labia Minora", "Anus", "Vagina&Rectum", "Cornea", "EyeMoisture", "Eyelashes"]
const MAX_TEX := 1024
const TEX_PROPS := ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture",
	"ao_texture", "emission_texture", "heightmap_texture"]

var tex_cache := {}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var src: String = a[0] if a.size() > 0 else "res://models/Lindsay.fbx"
	var dst: String = a[1] if a.size() > 1 else "res://out/jade.glb"
	var root: Node3D = (load(src) as PackedScene).instantiate()
	for ap in root.find_children("*", "AnimationPlayer", true, false):
		ap.get_parent().remove_child(ap)
		ap.free()
	var skel: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
	var ref_skin: Skin = null
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.skin and ref_skin == null:
			ref_skin = mi.skin
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.skin:
			_rebind(mi, skel)
	var before := 0
	var after := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var ratio := 1.0
		for k in KEEP:
			if String(mi.name).begins_with(k):
				ratio = KEEP[k]
		var res: Array = _rebuild(mi, ratio)
		before += res[0]
		after += res[1]
		if mi.skin == null:
			_skin_to_bone(mi, skel, ref_skin, "head")
	print("Triangles : %d -> %d" % [before, after])
	# DAZ exporte le squelette principal dans la pose de la scène : on le remet au repos (T-pose)
	skel.reset_bone_poses()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.image_format = "Lossy WebP"
	doc.lossy_quality = 0.82
	var err := doc.append_from_scene(root, state)
	if err != OK:
		push_error("append_from_scene: %d" % err)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dst.get_base_dir()))
	err = doc.write_to_filesystem(state, dst)
	print("Export %s : %s" % [dst, "OK" if err == OK else str(err)])
	quit()


func _rebuild(mi: MeshInstance3D, ratio: float) -> Array:
	var src: Mesh = mi.mesh
	var out := ArrayMesh.new()
	var t0 := 0
	var t1 := 0
	for si in src.get_surface_count():
		var mat: Material = src.surface_get_material(si)
		var sname: String = mat.resource_name if mat else ""
		var arrays: Array = src.surface_get_arrays(si)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		t0 += idx.size() / 3
		if sname in DROP:
			continue
		var new_idx := idx
		if ratio < 0.95 and idx.size() > 600:
			new_idx = _simplify(arrays, ratio, String(mi.name).contains("Hair"))
		var fmt: int = src.surface_get_format(si)
		var compact := _compact(arrays, new_idx)
		var flags := 0
		if fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS:
			flags |= Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, compact, [], {}, flags)
		out.surface_set_material(out.get_surface_count() - 1, _fix_material(mat, sname))
		t1 += new_idx.size() / 3
	mi.mesh = out
	print("  %-32s %7d -> %6d tris" % [mi.name, t0, t1])
	return [t0, t1]


## Certains maillages DAZ sont liés au squelette avec un décalage (le corps : ~11 cm),
## et une partie de leurs sommets vers des os sans décalage. On ramène tout le maillage
## dans l'espace de repos du squelette et on recalcule les liaisons.
func _rebind(mi: MeshInstance3D, skel: Skeleton3D) -> void:
	var sk: Skin = mi.skin
	var counts := {}
	var deltas := []
	for i in sk.get_bind_count():
		var bi := _bind_bone(sk, i, skel)
		var d: Transform3D = skel.get_bone_global_rest(bi) * sk.get_bind_pose(i)
		deltas.append(d)
		var key := str(d.origin.snapped(Vector3.ONE * 0.001))
		counts[key] = counts.get(key, 0) + 1
	var best_key := ""
	for k in counts:
		if best_key == "" or counts[k] > counts[best_key]:
			best_key = k
	var T := Vector3.ZERO
	for d in deltas:
		if str(d.origin.snapped(Vector3.ONE * 0.001)) == best_key:
			T = d.origin
			break
	if T.length() < 0.0005:
		return
	print("  recalage du squelette de %s : %s" % [mi.name, -T])
	# le squelette principal (hip) est décalé par rapport au maillage et aux squelettes des vêtements
	var hip := skel.find_bone("hip")
	if hip >= 0 and not skel.has_meta("hip_fixed"):
		var r := skel.get_bone_rest(hip)
		r.origin -= T
		skel.set_bone_rest(hip, r)
		skel.set_meta("hip_fixed", true)
	var src: Mesh = mi.mesh
	var out := ArrayMesh.new()
	var has_boots := false
	for o in mi.get_parent().get_children():
		if String(o.name).contains("Boots"):
			has_boots = true
	var cover := _clothing_bounds(mi)
	print("  zones couvertes : ", cover)
	for si in src.get_surface_count():
		var arrays: Array = src.surface_get_arrays(si)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		arrays[Mesh.ARRAY_VERTEX] = v
		if not cover.is_empty():
			# peau entièrement couverte par le pull ou la jupe : retirée pour qu'elle ne traverse pas
			var idx0: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var keep0 := PackedInt32Array()
			for t in range(0, idx0.size(), 3):
				if _covered(v[idx0[t]], cover) and _covered(v[idx0[t + 1]], cover) and _covered(v[idx0[t + 2]], cover):
					continue
				keep0.append_array([idx0[t], idx0[t + 1], idx0[t + 2]])
			if keep0.size() < 3:
				continue
			arrays[Mesh.ARRAY_INDEX] = keep0
		if has_boots:
			# la partie de la jambe cachée dans les bottes à talons traverserait la botte
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var keep := PackedInt32Array()
			for t in range(0, idx.size(), 3):
				if v[idx[t]].y < 0.5 and v[idx[t + 1]].y < 0.5 and v[idx[t + 2]].y < 0.5:
					continue
				keep.append_array([idx[t], idx[t + 1], idx[t + 2]])
			if keep.size() < 3:
				continue
			arrays[Mesh.ARRAY_INDEX] = keep
		var fmt: int = src.surface_get_format(si)
		var flags := 0
		if fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS:
			flags |= Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
		out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(si))
	mi.mesh = out
	var ns := Skin.new()
	for i in sk.get_bind_count():
		var bi := _bind_bone(sk, i, skel)
		ns.add_named_bind(skel.get_bone_name(bi), skel.get_bone_global_rest(bi).affine_inverse())
	mi.skin = ns


## Limites du haut (pull) et de la jupe, mesurées sur leurs maillages en T-pose
func _clothing_bounds(body: MeshInstance3D) -> Dictionary:
	var c := {}
	for o in body.get_parent().get_children():
		if not (o is MeshInstance3D) or o == body:
			continue
		var nm := String(o.name)
		var a: AABB = (o as MeshInstance3D).mesh.get_aabb()
		if nm.begins_with("lsotop"):
			c["top"] = a
		elif nm.begins_with("lsoskirt"):
			c["skirt"] = a
	return c


func _covered(p: Vector3, c: Dictionary) -> bool:
	if c.has("top"):
		var t: AABB = c.top
		var sleeve := maxf(absf(t.position.x), absf(t.end.x)) - 0.05
		if p.y > t.position.y + 0.03 and p.y < t.end.y - 0.05 and absf(p.x) < sleeve:
			# le torse jusqu'au col, et les bras jusqu'aux poignets
			if absf(p.x) < 0.17 or p.y > t.end.y - 0.3:
				return true
	if c.has("skirt"):
		var k: AABB = c.skirt
		if p.y > k.position.y + 0.04 and p.y < k.end.y - 0.02 and absf(p.x) < maxf(absf(k.position.x), absf(k.end.x)) - 0.01:
			return true
	return false


func _bind_bone(sk: Skin, i: int, skel: Skeleton3D) -> int:
	var bn := sk.get_bind_name(i)
	return skel.find_bone(bn) if bn != "" else sk.get_bind_bone(i)


func _simplify(arrays: Array, ratio: float, can_thin: bool) -> PackedInt32Array:
	# meshoptimizer (via ImporterMesh) : on prend le niveau de détail le plus proche de la cible
	var im := ImporterMesh.new()
	var a2 := []
	a2.resize(Mesh.ARRAY_MAX)
	a2[Mesh.ARRAY_VERTEX] = arrays[Mesh.ARRAY_VERTEX]
	a2[Mesh.ARRAY_NORMAL] = arrays[Mesh.ARRAY_NORMAL]
	a2[Mesh.ARRAY_TEX_UV] = arrays[Mesh.ARRAY_TEX_UV]
	a2[Mesh.ARRAY_INDEX] = arrays[Mesh.ARRAY_INDEX]
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, a2)
	im.generate_lods(25.0, 60.0, [])
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var want := int(idx.size() * ratio)
	var best := idx
	var best_d := absi(idx.size() - want)
	var sizes := []
	for l in im.get_surface_lod_count(0):
		sizes.append(im.get_surface_lod_indices(0, l).size() / 3)

	for l in im.get_surface_lod_count(0):
		var li: PackedInt32Array = im.get_surface_lod_indices(0, l)
		var d := absi(li.size() - want)
		if d < best_d and li.size() >= 3:
			best = li
			best_d = d
	# trop de pièces séparées (mèches de cheveux) : on retire des mèches entières
	if can_thin and best.size() > want * 1.6:
		best = _thin(idx, float(want) / idx.size())
	return best


func _thin(idx: PackedInt32Array, keep: float) -> PackedInt32Array:
	var nv := 0
	for i in idx:
		nv = maxi(nv, i + 1)
	var par := PackedInt32Array()
	par.resize(nv)
	for i in nv:
		par[i] = i
	for t in range(0, idx.size(), 3):
		var a := _find(par, idx[t])
		for k in [1, 2]:
			var b := _find(par, idx[t + k])
			if a != b:
				par[b] = a
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var keep_comp := {}
	var out := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		var c := _find(par, idx[t])
		if not keep_comp.has(c):
			keep_comp[c] = rng.randf() < keep
		if keep_comp[c]:
			out.append_array([idx[t], idx[t + 1], idx[t + 2]])
	return out if out.size() >= 3 else idx


func _find(par: PackedInt32Array, i: int) -> int:
	while par[i] != i:
		par[i] = par[par[i]]
		i = par[i]
	return i


func _compact(arrays: Array, idx: PackedInt32Array) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n := verts.size()
	var remap := PackedInt32Array()
	remap.resize(n)
	remap.fill(-1)
	var order := PackedInt32Array()
	for i in idx:
		if remap[i] < 0:
			remap[i] = order.size()
			order.append(i)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	for k in Mesh.ARRAY_MAX:
		var arr = arrays[k]
		if arr == null or k == Mesh.ARRAY_INDEX:
			continue
		var per := 1
		if k == Mesh.ARRAY_TANGENT:
			per = 4
		elif k == Mesh.ARRAY_BONES or k == Mesh.ARRAY_WEIGHTS:
			per = arr.size() / n
		var dst = arr.duplicate()
		dst.resize(order.size() * per)
		for j in order.size():
			var o: int = order[j]
			for c in per:
				dst[j * per + c] = arr[o * per + c]
		out[k] = dst
	var ni := PackedInt32Array()
	ni.resize(idx.size())
	for j in idx.size():
		ni[j] = remap[idx[j]]
	out[Mesh.ARRAY_INDEX] = ni
	return out


func _fix_material(mat: Material, sname: String) -> Material:
	if not (mat is StandardMaterial3D):
		return mat
	var m: StandardMaterial3D = mat.duplicate()
	for p in TEX_PROPS:
		var t = m.get(p)
		if t is Texture2D:
			m.set(p, _small(t))
	# cheveux et verres : transparence par découpe (pas de problème de tri)
	if m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.45
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if sname == "Lenses":
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.85, 0.9, 1.0, 0.18)
		m.albedo_texture = null
	m.roughness = clampf(m.roughness, 0.35, 1.0)
	return m


func _small(t: Texture2D) -> Texture2D:
	if tex_cache.has(t):
		return tex_cache[t]
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var s := minf(1.0, float(MAX_TEX) / maxf(w, h))
	if s < 1.0:
		img.resize(maxi(1, int(w * s)), maxi(1, int(h * s)), Image.INTERPOLATE_LANCZOS)
	if img.has_mipmaps():
		img.clear_mipmaps()
	var nt := ImageTexture.create_from_image(img)
	nt.resource_name = t.resource_name
	tex_cache[t] = nt
	return nt


func _skin_to_bone(mi: MeshInstance3D, skel: Skeleton3D, _ref: Skin, bone: String) -> void:
	# Maillage non riggé (les lunettes) : on le lie entièrement à un os (la tête)
	var bi := skel.find_bone(bone)
	var to_skel := mi.transform
	var p := mi.get_parent()
	while p and p != skel:
		if p is BoneAttachment3D:
			var ab := skel.find_bone((p as BoneAttachment3D).bone_name)
			to_skel = skel.get_bone_global_rest(ab) * to_skel
			break
		if p is Node3D:
			to_skel = (p as Node3D).transform * to_skel
		p = p.get_parent()
	print("  lunettes : parent=%s (%s)" % [mi.get_parent().name, mi.get_parent().get_class()])
	var src: ArrayMesh = mi.mesh
	var out := ArrayMesh.new()
	for si in src.get_surface_count():
		var arrays: Array = src.surface_get_arrays(si)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var nor: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in verts.size():
			verts[i] = to_skel * verts[i]
			if nor.size() > i:
				nor[i] = (to_skel.basis * nor[i]).normalized()
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = nor
		arrays[Mesh.ARRAY_TANGENT] = null
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		for i in verts.size():
			bones.append_array([0, 0, 0, 0])
			weights.append_array([1.0, 0.0, 0.0, 0.0])
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(si, src.surface_get_material(si))
	mi.mesh = out
	mi.transform = Transform3D.IDENTITY
	if mi.get_parent() != skel:
		var oldp := mi.get_parent()
		oldp.remove_child(mi)
		mi.owner = null
		skel.add_child(mi)
		mi.owner = skel.get_parent()
		if oldp is BoneAttachment3D and oldp.get_child_count() == 0:
			oldp.get_parent().remove_child(oldp)
	var ns := Skin.new()
	ns.add_named_bind(bone, skel.get_bone_global_rest(bi).affine_inverse())
	mi.skin = ns
	mi.skeleton = NodePath("..")


func _to_root(n: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	while n and n is Node3D and n.get_parent() != null:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
