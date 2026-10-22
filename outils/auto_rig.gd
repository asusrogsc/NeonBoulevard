extends SceneTree
## Ajoute un squelette à un personnage 3D qui n'en a pas (export Substance Painter, sculpt…)
## et l'exporte en GLB prêt pour le jeu (même noms d'os que les personnages DAZ : model_rig.gd
## le pilote avec les poses de pose.gd).
##
## Usage (dans le projet, depuis un terminal) :
##   godot --headless --script res://outils/auto_rig.gd -- res://models/Oldman.glb res://models/vieux.glb
##
## Le personnage est remis à l'échelle (HEIGHT mètres), les pieds au sol, face à +Z.
## Les articulations JOINTS sont données en mètres pour ce modèle (vieil homme voûté en pose A) :
## pour un autre personnage, il faut les ajuster (outils : un rendu de face et de profil avec une grille).

const HEIGHT := 1.68
const MAX_TEX := 1024

# nom de l'os : [parent, position de l'articulation]
const JOINTS := {
	"hip": ["", Vector3(0.0, 0.86, -0.07)],
	"abdomenLower": ["hip", Vector3(0.0, 0.92, -0.07)],
	"abdomenUpper": ["abdomenLower", Vector3(0.0, 1.04, -0.07)],
	"chestLower": ["abdomenUpper", Vector3(0.0, 1.16, -0.065)],
	"chestUpper": ["chestLower", Vector3(0.0, 1.27, -0.05)],
	"neckLower": ["chestUpper", Vector3(0.0, 1.37, 0.0)],
	"head": ["neckLower", Vector3(0.0, 1.45, 0.08)],
	"rShldrBend": ["chestUpper", Vector3(-0.19, 1.29, -0.06)],
	"rForearmBend": ["rShldrBend", Vector3(-0.40, 1.01, -0.04)],
	"rHand": ["rForearmBend", Vector3(-0.465, 0.855, 0.0)],
	"lShldrBend": ["chestUpper", Vector3(0.19, 1.29, -0.06)],
	"lForearmBend": ["lShldrBend", Vector3(0.40, 1.01, -0.04)],
	"lHand": ["lForearmBend", Vector3(0.465, 0.855, 0.0)],
	"rThighBend": ["hip", Vector3(-0.12, 0.80, -0.07)],
	"rShin": ["rThighBend", Vector3(-0.15, 0.40, -0.06)],
	"rFoot": ["rShin", Vector3(-0.16, 0.10, -0.12)],
	"rToe": ["rFoot", Vector3(-0.16, 0.02, 0.07)],
	"rHeel": ["rFoot", Vector3(-0.16, 0.01, -0.19)],
	"lThighBend": ["hip", Vector3(0.12, 0.80, -0.07)],
	"lShin": ["lThighBend", Vector3(0.15, 0.40, -0.06)],
	"lFoot": ["lShin", Vector3(0.16, 0.10, -0.12)],
	"lToe": ["lFoot", Vector3(0.16, 0.02, 0.07)],
	"lHeel": ["lFoot", Vector3(0.16, 0.01, -0.19)],
}

# segments qui « attirent » les sommets : os, début, fin, rayon (épaisseur du membre)
const SEGS := [
	["hip", Vector3(0.0, 0.78, -0.07), Vector3(0.0, 0.92, -0.07), 0.17],
	["abdomenLower", Vector3(0.0, 0.92, -0.07), Vector3(0.0, 1.04, -0.07), 0.17],
	["abdomenUpper", Vector3(0.0, 1.04, -0.07), Vector3(0.0, 1.16, -0.065), 0.17],
	["chestLower", Vector3(0.0, 1.16, -0.065), Vector3(0.0, 1.27, -0.05), 0.17],
	["chestUpper", Vector3(0.0, 1.27, -0.05), Vector3(0.0, 1.37, 0.0), 0.15],
	["neckLower", Vector3(0.0, 1.37, 0.0), Vector3(0.0, 1.45, 0.08), 0.06],
	["head", Vector3(0.0, 1.45, 0.08), Vector3(0.0, 1.62, 0.12), 0.11],
	["rShldrBend", Vector3(-0.19, 1.29, -0.06), Vector3(-0.40, 1.01, -0.04), 0.06],
	["rForearmBend", Vector3(-0.40, 1.01, -0.04), Vector3(-0.465, 0.855, 0.0), 0.05],
	["rHand", Vector3(-0.465, 0.855, 0.0), Vector3(-0.49, 0.68, 0.02), 0.045],
	["lShldrBend", Vector3(0.19, 1.29, -0.06), Vector3(0.40, 1.01, -0.04), 0.06],
	["lForearmBend", Vector3(0.40, 1.01, -0.04), Vector3(0.465, 0.855, 0.0), 0.05],
	["lHand", Vector3(0.465, 0.855, 0.0), Vector3(0.49, 0.68, 0.02), 0.045],
	["rThighBend", Vector3(-0.12, 0.80, -0.07), Vector3(-0.15, 0.40, -0.06), 0.09],
	["rShin", Vector3(-0.15, 0.40, -0.06), Vector3(-0.16, 0.10, -0.12), 0.07],
	["rFoot", Vector3(-0.16, 0.10, -0.12), Vector3(-0.16, 0.03, 0.08), 0.06],
	["lThighBend", Vector3(0.12, 0.80, -0.07), Vector3(0.15, 0.40, -0.06), 0.09],
	["lShin", Vector3(0.15, 0.40, -0.06), Vector3(0.16, 0.10, -0.12), 0.07],
	["lFoot", Vector3(0.16, 0.10, -0.12), Vector3(0.16, 0.03, 0.08), 0.06],
]

var bone_idx := {}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var src: String = a[0] if a.size() > 0 else "res://models/Oldman.glb"
	var dst: String = a[1] if a.size() > 1 else "res://models/vieux.glb"
	var scene: Node3D = (load(src) as PackedScene).instantiate()
	var meshes := scene.find_children("*", "MeshInstance3D", true, false)
	# ---- mise à l'échelle : on cuit la transformation dans les sommets
	var xfs := []
	var lo := INF
	var hi := -INF
	for mi in meshes:
		var t := _to_root(mi, scene)
		xfs.append(t)
		var ab: AABB = t * (mi as MeshInstance3D).get_aabb()
		lo = minf(lo, ab.position.y)
		hi = maxf(hi, ab.end.y)
	var k := HEIGHT / (hi - lo)
	var bake := Transform3D(Basis().scaled(Vector3(k, k, k)), Vector3(0, -lo * k, 0))
	# ---- squelette
	var root := Node3D.new()
	root.name = src.get_file().get_basename()
	var skel := Skeleton3D.new()
	skel.name = "Skeleton3D"
	root.add_child(skel)
	for n in JOINTS:
		var i := skel.get_bone_count()
		skel.add_bone(n)
		bone_idx[n] = i
	for n in JOINTS:
		var par: String = JOINTS[n][0]
		var pos: Vector3 = JOINTS[n][1]
		var i: int = bone_idx[n]
		if par != "":
			skel.set_bone_parent(i, bone_idx[par])
			pos -= JOINTS[par][1]
		skel.set_bone_rest(i, Transform3D(Basis(), pos))
	skel.reset_bone_poses()
	var skin := Skin.new()
	for n in JOINTS:
		skin.add_named_bind(n, Transform3D(Basis(), -JOINTS[n][1]))
	# ---- maillages
	for mi_i in meshes.size():
		var mi: MeshInstance3D = meshes[mi_i]
		var t: Transform3D = bake * xfs[mi_i]
		var out := ArrayMesh.new()
		for si in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nrm: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var tan: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT] if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			bones.resize(v.size() * 4)
			weights.resize(v.size() * 4)
			for vi in v.size():
				v[vi] = t * v[vi]
				if nrm.size() > vi:
					nrm[vi] = (t.basis * nrm[vi]).normalized()
				if tan.size() > vi * 4:
					var tv := (t.basis * Vector3(tan[vi * 4], tan[vi * 4 + 1], tan[vi * 4 + 2])).normalized()
					tan[vi * 4] = tv.x
					tan[vi * 4 + 1] = tv.y
					tan[vi * 4 + 2] = tv.z
				var w := _weights(v[vi])
				for j in 4:
					bones[vi * 4 + j] = w[j][0]
					weights[vi * 4 + j] = w[j][1]
			arr[Mesh.ARRAY_VERTEX] = v
			arr[Mesh.ARRAY_NORMAL] = nrm
			if tan.size() > 0:
				arr[Mesh.ARRAY_TANGENT] = tan
			arr[Mesh.ARRAY_BONES] = bones
			arr[Mesh.ARRAY_WEIGHTS] = weights
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			out.surface_set_material(si, _small_mat(mi.get_active_material(si)))
		var nm := MeshInstance3D.new()
		nm.name = String(mi.name)
		nm.mesh = out
		nm.skin = skin
		skel.add_child(nm)
		nm.skeleton = NodePath("..")
	_own(root, root)
	scene.free()
	var doc := GLTFDocument.new()
	doc.image_format = "Lossy WebP"
	doc.lossy_quality = 0.85
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, dst)
	print("Export %s : %s" % [dst, "OK" if err == OK else str(err)])
	quit()


## Poids des os pour un sommet : les 4 segments les plus proches (distance relative à
## l'épaisseur du membre), avec quelques règles pour la barbe, la tête et le tablier.
func _weights(p: Vector3) -> Array:
	# tête, chapeau et barbe suivent la tête
	if p.y > 1.43 or (p.y > 1.2 and p.z > 0.1 and absf(p.x) < 0.1):
		return [[bone_idx.head, 1.0], [0, 0.0], [0, 0.0], [0, 0.0]]
	var cand := []
	for s in SEGS:
		var b: String = s[0]
		# un membre gauche ne prend pas de sommets à droite (et inversement)
		if b.begins_with("l") and p.x < -0.03:
			continue
		if b.begins_with("r") and p.x > 0.03:
			continue
		var d := _seg_dist(p, s[1], s[2]) / float(s[3])
		cand.append([bone_idx[b], d])
	cand.sort_custom(func(x, y): return x[1] < y[1])
	var out := []
	var total := 0.0
	for j in 4:
		var w := 1.0 / pow(maxf(cand[j][1], 0.05), 5.0)
		out.append([cand[j][0], w])
		total += w
	for j in 4:
		out[j][1] = out[j][1] / total
	return out


static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _small_mat(m: Material) -> Material:
	if not (m is StandardMaterial3D):
		return m
	var d: StandardMaterial3D = m.duplicate()
	for prop in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "ao_texture", "emission_texture"]:
		var tex = d.get(prop)
		if tex is Texture2D:
			var img: Image = tex.get_image()
			if img.is_compressed():
				img.decompress()
			if img.has_mipmaps():
				img.clear_mipmaps()
			var s := minf(1.0, float(MAX_TEX) / maxf(img.get_width(), img.get_height()))
			if s < 1.0:
				img.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_LANCZOS)
			d.set(prop, ImageTexture.create_from_image(img))
	return d


func _to_root(n: Node, root: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	while n and n != root:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)
