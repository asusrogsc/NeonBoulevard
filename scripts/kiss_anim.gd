class_name KissAnim
extends RefCounted
## Animation du baiser : clés temporelles sur les os réels du modèle, évaluées dans
## apply_pose (model_rig.gd). Aucun AnimationPlayer, aucun chemin de nœud à résoudre.
## Espace de travail : espace squelette (le personnage regarde vers +Z).
## ModelRig._g(theta) = rotation autour de +X : positif = membre vers l'avant, buste vers l'avant.
## Les angles s'empilent le long de la colonne : la bascule se fait au BASSIN, pas dans le dos.
## Les os sont résolus par NOM quand c'est possible, sinon par POSITION anatomique : les
## modèles sans table "bones" (jade.glb) et les copies de squelette des vêtements marchent.

const D := PI / 180.0
const DUR := 3.0

const BONES := [
	"hip", "abdomenLower", "abdomenUpper", "chestLower", "chestUpper",
	"neckLower", "head",
	"rThighBend", "rShin", "rFoot", "lThighBend", "lShin", "lFoot",
	"rShldrBend", "rForearmBend", "lShldrBend", "lForearmBend",
]
const ARM_R := ["rShldrBend", "rForearmBend"]
const ARM_L := ["lShldrBend", "lForearmBend"]

## positions d'articulation attendues (mètres, modèle de 1,61 m de haut, face à +Z)
const JOINTS := {
	"hip": Vector3(0.0, 0.86, -0.07),
	"abdomenLower": Vector3(0.0, 0.92, -0.07),
	"abdomenUpper": Vector3(0.0, 1.04, -0.07),
	"chestLower": Vector3(0.0, 1.16, -0.065),
	"chestUpper": Vector3(0.0, 1.27, -0.05),
	"neckLower": Vector3(0.0, 1.37, 0.0),
	"head": Vector3(0.0, 1.45, 0.08),
	"rShldrBend": Vector3(-0.19, 1.29, -0.06),
	"rForearmBend": Vector3(-0.40, 1.01, -0.04),
	"lShldrBend": Vector3(0.19, 1.29, -0.06),
	"lForearmBend": Vector3(0.40, 1.01, -0.04),
	"rThighBend": Vector3(-0.12, 0.80, -0.07),
	"rShin": Vector3(-0.15, 0.40, -0.06),
	"rFoot": Vector3(-0.16, 0.10, -0.12),
	"lThighBend": Vector3(0.12, 0.80, -0.07),
	"lShin": Vector3(0.15, 0.40, -0.06),
	"lFoot": Vector3(0.16, 0.10, -0.12),
}

# ---- clés : [temps, {os: angle en degrés, "hip_y": descente du bassin en mètres}]

const KISSER := [
	[0.00, {"rThighBend": 2, "rShin": 5, "rFoot": -3, "lThighBend": -2, "lShin": 5, "lFoot": 3,
			"rForearmBend": 10, "lForearmBend": 10}],
	[0.85, {"hip_y": -0.30, "hip": 14, "abdomenLower": 8, "abdomenUpper": 10, "chestLower": 13,
			"chestUpper": 12, "neckLower": 12, "head": 16, "rThighBend": 78, "rShin": 106, "rFoot": -22,
			"lThighBend": 64, "lShin": 86, "lFoot": -16, "rShldrBend": 56, "rForearmBend": 40,
			"lShldrBend": 48, "lForearmBend": 48}],
	[1.30, {"hip_y": -0.51, "hip": 25, "abdomenLower": 12, "abdomenUpper": 15, "chestLower": 20,
			"chestUpper": 18, "neckLower": 16, "head": 24, "rThighBend": 100, "rShin": 135, "rFoot": -28,
			"lThighBend": 86, "lShin": 110, "lFoot": -20, "rShldrBend": 84, "rForearmBend": 26,
			"lShldrBend": 76, "lForearmBend": 34}],
	[1.75, {"hip_y": -0.50, "hip": 25, "abdomenLower": 12, "abdomenUpper": 15, "chestLower": 20,
			"chestUpper": 18, "neckLower": 19, "head": 30, "rThighBend": 100, "rShin": 135, "rFoot": -28,
			"lThighBend": 86, "lShin": 110, "lFoot": -20, "rShldrBend": 84, "rForearmBend": 32,
			"lShldrBend": 76, "lForearmBend": 40}],
	[2.05, {"hip_y": -0.51, "hip": 25, "abdomenLower": 12, "abdomenUpper": 15, "chestLower": 20,
			"chestUpper": 18, "neckLower": 13, "head": 21, "rThighBend": 100, "rShin": 135, "rFoot": -28,
			"lThighBend": 86, "lShin": 110, "lFoot": -20, "rShldrBend": 84, "rForearmBend": 22,
			"lShldrBend": 76, "lForearmBend": 30}],
	[2.35, {"hip_y": -0.505, "hip": 25, "abdomenLower": 12, "abdomenUpper": 15, "chestLower": 20,
			"chestUpper": 18, "neckLower": 18, "head": 29, "rThighBend": 100, "rShin": 135, "rFoot": -28,
			"lThighBend": 86, "lShin": 110, "lFoot": -20, "rShldrBend": 84, "rForearmBend": 30,
			"lShldrBend": 76, "lForearmBend": 38}],
	[3.00, {"rThighBend": 2, "rShin": 5, "rFoot": -3, "lThighBend": -2, "lShin": 5, "lFoot": 3,
			"rForearmBend": 10, "lForearmBend": 10}],
]

const VICTIM := [
	[0.00, {"abdomenLower": -4, "abdomenUpper": -4, "chestLower": -2, "neckLower": 6, "head": 8,
			"rThighBend": 4, "rShin": 8, "rFoot": -4, "lThighBend": -6, "lShin": 6, "lFoot": 4,
			"rShldrBend": 160, "rForearmBend": 14, "lShldrBend": 148, "lForearmBend": 8}],
	[0.85, {"abdomenLower": -10, "abdomenUpper": -8, "neckLower": 12, "head": -6,
			"rThighBend": -12, "rShin": 16, "lThighBend": -12, "lShin": 16,
			"rShldrBend": 130, "rForearmBend": 46, "lShldrBend": 122, "lForearmBend": 52}],
	[1.30, {"abdomenLower": -14, "abdomenUpper": -10, "neckLower": 18, "head": -22,
			"rThighBend": -16, "rShin": 22, "rFoot": -8, "lThighBend": -16, "lShin": 22, "lFoot": -8,
			"rShldrBend": 108, "rForearmBend": 62, "lShldrBend": 100, "lForearmBend": 70}],
	[1.75, {"neckLower": 20, "head": -26, "rForearmBend": 68, "lForearmBend": 76}],
	[2.05, {"neckLower": 16, "head": -19, "rForearmBend": 58, "lForearmBend": 66}],
	[2.35, {"neckLower": 19, "head": -25, "rForearmBend": 66, "lForearmBend": 74}],
	[3.00, {"abdomenLower": -4, "abdomenUpper": -4, "chestLower": -2, "neckLower": 6, "head": 8,
			"rThighBend": 4, "rShin": 8, "rFoot": -4, "lThighBend": -6, "lShin": 6, "lFoot": 4,
			"rShldrBend": 160, "rForearmBend": 14, "lShldrBend": 148, "lForearmBend": 8}],
]


## Traduit les clés d'un rôle en index d'os du squelette principal :
## { "keys": [[t, hip_y, {index: Basis}], …], "hip": index ou -1 }
static func compile(rig, role: String) -> Dictionary:
	var keys: Array = KISSER if role == "kisser" else VICTIM
	var out := []
	var hip := -1
	for kf in keys:
		var angles: Dictionary = kf[1]
		var E := {}
		for logical in angles:
			if logical == "hip_y":
				continue
			var idx: int = _resolve(rig, logical)
			if idx < 0:
				continue
			if logical == "hip":
				hip = idx
			var b := ModelRig._g(float(angles[logical]) * D)
			if logical in ARM_R:
				b = b * rig.down_r
			elif logical in ARM_L:
				b = b * rig.down_l
			E[idx] = b
		if not rig.bmap.is_empty() or rig.Cb != Basis.IDENTITY:
			var Ci: Basis = rig.Cb.inverse()
			for i in E:
				E[i] = Ci * E[i] * rig.Cb
		out.append([float(kf[0]), float(angles.get("hip_y", 0.0)), E])
	return {"keys": out, "hip": hip}


## Os correspondant à un nom logique : par nom, sinon par proximité de l'articulation attendue.
static func _resolve(rig, logical: String) -> int:
	var sk: Skeleton3D = rig.skel
	var i: int = rig._find(sk, logical)
	if i >= 0:
		return i
	if not JOINTS.has(logical):
		return -1
	var want: Vector3 = JOINTS[logical] * rig.hs
	var best := -1
	var bd := 0.12 * maxf(rig.hs, 0.5)
	for j in sk.get_bone_count():
		var d := want.distance_to(sk.get_bone_global_rest(j).origin)
		if d < bd:
			bd = d
			best = j
	return best


## Échantillonne les clés à l'instant t : [hip_y, {index: Basis}]
static func sample(keys: Array, t: float) -> Array:
	if keys.is_empty():
		return [0.0, {}]
	if t <= float(keys[0][0]):
		return [float(keys[0][1]), keys[0][2]]
	if t >= float(keys[-1][0]):
		return [float(keys[-1][1]), keys[-1][2]]
	var i := 0
	while i < keys.size() - 2 and float(keys[i + 1][0]) <= t:
		i += 1
	var a: Array = keys[i]
	var b: Array = keys[i + 1]
	var span: float = maxf(float(b[0]) - float(a[0]), 0.0001)
	var f: float = clampf((t - float(a[0])) / span, 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)  # entrée/sortie douces
	var E := {}
	var EA: Dictionary = a[2]
	var EB: Dictionary = b[2]
	for idx in EA:
		var qa: Quaternion = EA[idx].get_rotation_quaternion()
		var qb: Quaternion = EB[idx].get_rotation_quaternion() if EB.has(idx) else qa
		E[idx] = Basis(qa.slerp(qb, f))
	return [lerpf(float(a[1]), float(b[1]), f), E]