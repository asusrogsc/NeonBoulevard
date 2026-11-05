class_name KissScene
extends RefCounted
## Séquence d'animation entre deux personnages : l'un vient à genoux au-dessus
## de l'autre allongé, l'embrasse deux fois, puis se relève.
## Piste "a" = celui qui embrasse, piste "b" = celui qui est au sol.
## "tilt" = basculement du corps entier, appliqué au nœud 3D par main.gd
## (les os de vieux.glb ne répondent pas à "rot").

const DUR := 3.2

const A := [
	[0.00, {"tilt": 8.0, "ht": 0.0, "fl": [20, 25], "bl": [-15, 20], "fa": [10, 20], "ba": [5, 20], "ox": 0.0, "lift": 0.0, "lean": 5.0}],
	[0.40, {"tilt": 34.0, "ht": 5.0, "fl": [45, 70], "bl": [-30, 60], "fa": [15, 35], "ba": [8, 40], "ox": 0.0, "lift": 0.0, "lean": 15.0}],
	[0.80, {"tilt": 62.0, "ht": 6.0, "fl": [80, 140], "bl": [-62, 130], "fa": [22, 45], "ba": [14, 55], "ox": 0.0, "lift": 0.0, "lean": 20.0}],
	[1.15, {"tilt": 78.0, "ht": 10.0, "fl": [88, 152], "bl": [-70, 142], "fa": [30, 48], "ba": [22, 58], "ox": 0.0, "lift": 0.0, "lean": 12.0}],
	[1.50, {"tilt": 84.0, "ht": 12.0, "fl": [88, 152], "bl": [-70, 142], "fa": [32, 50], "ba": [24, 60], "ox": 0.0, "lift": 0.0, "lean": 10.0}],
	[1.85, {"tilt": 78.0, "ht": 8.0, "fl": [88, 152], "bl": [-70, 142], "fa": [30, 48], "ba": [22, 58], "ox": 0.0, "lift": 0.0, "lean": 12.0}],
	[2.20, {"tilt": 84.0, "ht": 13.0, "fl": [88, 152], "bl": [-70, 142], "fa": [33, 52], "ba": [25, 62], "ox": 0.0, "lift": 0.0, "lean": 10.0}],
	[2.60, {"tilt": 66.0, "ht": 4.0, "fl": [82, 145], "bl": [-64, 134], "fa": [22, 42], "ba": [16, 50], "ox": 0.0, "lift": 0.0, "lean": 16.0}],
	[3.20, {"tilt": 22.0, "ht": 0.0, "fl": [40, 60], "bl": [-28, 50], "fa": [10, 22], "ba": [6, 24], "ox": 0.0, "lift": 0.0, "lean": 6.0}],
]

const B := [
	[0.00, {"rot": 90.0, "ox": 20.0, "lift": 6.0, "lean": -6.0, "ht": 12.0, "fl": [4, 0], "bl": [-6, 0], "fa": [165, 10], "ba": [150, 0]}],
	[0.55, {"rot": 90.0, "ox": 20.0, "lift": 12.0, "lean": -10.0, "ht": 24.0, "fl": [4, 0], "bl": [-6, 0], "fa": [158, 40], "ba": [145, 25]}],
	[1.05, {"rot": 90.0, "ox": 20.0, "lift": 16.0, "lean": -14.0, "ht": 34.0, "fl": [4, 0], "bl": [-6, 0], "fa": [150, 78], "ba": [138, 58]}],
	[1.50, {"rot": 90.0, "ox": 20.0, "lift": 17.0, "lean": -15.0, "ht": 36.0, "fl": [4, 0], "bl": [-6, 0], "fa": [148, 82], "ba": [136, 62]}],
	[1.85, {"rot": 90.0, "ox": 20.0, "lift": 15.0, "lean": -13.0, "ht": 32.0, "fl": [4, 0], "bl": [-6, 0], "fa": [152, 76], "ba": [140, 56]}],
	[2.20, {"rot": 90.0, "ox": 20.0, "lift": 17.0, "lean": -15.0, "ht": 36.0, "fl": [4, 0], "bl": [-6, 0], "fa": [148, 82], "ba": [136, 62]}],
	[2.65, {"rot": 90.0, "ox": 20.0, "lift": 12.0, "lean": -10.0, "ht": 22.0, "fl": [4, 0], "bl": [-6, 0], "fa": [158, 45], "ba": [146, 30]}],
	[3.20, {"rot": 90.0, "ox": 20.0, "lift": 6.0, "lean": -6.0, "ht": 12.0, "fl": [4, 0], "bl": [-6, 0], "fa": [165, 10], "ba": [150, 0]}],
]

## Distance à la tête et enfoncement dans le sol, pour celui qui embrasse.
const POS := [
	[0.00, 30.0, 0.0], [0.40, 26.0, -6.0], [0.80, 20.0, -16.0], [1.15, 11.0, -26.0],
	[1.50, 9.0, -29.0], [1.85, 10.0, -27.0], [2.20, 9.0, -29.0], [2.60, 14.0, -21.0],
	[3.20, 26.0, -6.0],
]


static func _seg(keys: Array, t: float) -> Array:
	var c := clampf(t, 0.0, DUR)
	for i in keys.size() - 1:
		var k1: float = keys[i + 1][0]
		if c <= k1:
			var k0: float = keys[i][0]
			var f: float = 0.0 if k1 <= k0 else (c - k0) / (k1 - k0)
			return [keys[i], keys[i + 1], clampf(f, 0.0, 1.0)]
	return [keys[keys.size() - 1], keys[keys.size() - 1], 0.0]


static func pose(track: String, t: float) -> Dictionary:
	var keys: Array = A if track == "a" else B
	var s := _seg(keys, t)
	var p0: Dictionary = s[0][1]
	var p1: Dictionary = s[1][1]
	var f: float = s[2]
	var out := {}
	for k in p0:
		var v0 = p0[k]
		var v1 = p1.get(k, v0)
		if v0 is Array:
			var arr := []
			for i in v0.size():
				arr.append(lerpf(float(v0[i]), float(v1[i]), f))
			out[k] = arr
		else:
			out[k] = lerpf(float(v0), float(v1), f)
	return out


## Renvoie [distance, enfoncement] à l'instant t.
static func place(t: float) -> Array:
	var s := _seg(POS, t)
	return [lerpf(float(s[0][1]), float(s[1][1]), s[2]), lerpf(float(s[0][2]), float(s[1][2]), s[2])]