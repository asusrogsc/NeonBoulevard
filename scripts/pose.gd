class_name Pose
extends RefCounted
## Poses des combattants : angles (en degrés) dans le plan de profil.
## lean = inclinaison du buste, fl/bl = jambe avant/arrière [cuisse, flexion genou],
## fa/ba = bras avant/arrière [épaule, flexion coude], rot = basculement (au sol).

const D := PI / 180.0


static func _foot_y(hy: float, a: Array) -> float:
	var A: float = float(a[0]) * D
	var B: float = (float(a[0]) - float(a[1])) * D
	return hy + cos(A) * 11.0 + cos(B) * 11.0


## Hauteur du bassin (en px de jeu) pour que les pieds touchent le sol.
static func hip_height(p: Dictionary) -> float:
	var hy := -22.0
	var fl: Array = p.get("fl", [10, 10])
	var bl: Array = p.get("bl", [-10, 10])
	var y := hy
	if not p.get("air", false):
		y -= maxf(_foot_y(hy, fl), _foot_y(hy, bl))
	y -= float(p.get("lift", 0.0))
	return -y


static func get_pose(e, time: float) -> Dictionary:
	var t: float = e.t
	var st: String = e.st
	var br := sin(time * 5.0 + float(e.ph)) * 1.6
	var idle := {"lean": 6.0 + br, "fl": [12, 18], "bl": [-10, 16], "fa": [30, 112], "ba": [14, 108]}
	if e.moving and st in ["idle", "walk", "enter", "charge"]:
		var a := sin(float(e.wph))
		var run := st == "charge"
		var sw := 40.0 if run else 26.0
		var fa_run: Array = [-50, 15]
		var ba_run: Array = [-60, 15]
		return {
			"lean": 28.0 if run else 8.0,
			"fl": [a * sw, 12.0 + maxf(0.0, a) * 24.0],
			"bl": [-a * sw, 12.0 + maxf(0.0, -a) * 24.0],
			"fa": fa_run if run else [30.0 - a * 14.0, 110],
			"ba": ba_run if run else [14.0 + a * 14.0, 105],
		}
	match st:
		"idle", "walk", "enter", "land", "wait":
			return idle
		"atk", "eatk":
			var A: Dictionary = e.atk
			var s: float = A.s
			var ac: float = A.a
			var ph := 0 if t < s else (1 if t < s + ac else 2)
			var id: String = A.id
			match id:
				"jab":
					if ph == 0:
						return {"lean": 2, "fl": [14, 16], "bl": [-10, 14], "fa": [15, 140], "ba": [14, 108]}
					return {"lean": 13, "fl": [20, 10], "bl": [-16, 8], "fa": [88, 3], "ba": [20, 110]}
				"cross":
					if ph == 0:
						return {"lean": 0, "fl": [14, 16], "bl": [-10, 14], "fa": [30, 112], "ba": [-5, 130]}
					return {"lean": 20, "fl": [22, 8], "bl": [-20, 6], "fa": [25, 115], "ba": [86, 4]}
				"kick":
					if ph == 0:
						return {"lean": -4, "fl": [70, 120], "bl": [-6, 10], "fa": [40, 110], "ba": [0, 90]}
					return {"lean": -18, "fl": [97, 4], "bl": [-8, 6], "fa": [40, 120], "ba": [-25, 60]}
				"upper":
					if ph == 0:
						return {"lean": 22, "fl": [35, 55], "bl": [-22, 45], "fa": [-10, 50], "ba": [14, 110]}
					return {"lean": -8, "ht": -10, "fl": [8, 6], "bl": [-6, 6], "fa": [172, 6], "ba": [10, 100]}
				"dash":
					if ph == 0:
						return {"lean": 25, "fl": [40, 70], "bl": [-30, 60], "fa": [30, 100], "ba": [0, 90]}
					return {"air": true, "lift": 4, "lean": -15, "fl": [82, 2], "bl": [-30, 110], "fa": [60, 100], "ba": [-40, 60]}
				"heavy":
					if ph == 0:
						return {"lean": -10, "fl": [16, 14], "bl": [-12, 12], "fa": [-40, 70], "ba": [10, 100]}
					return {"lean": 24, "fl": [26, 10], "bl": [-26, 8], "fa": [90, 2], "ba": [10, 110]}
			return idle
		"jump":
			return {"air": true, "lean": 5, "fl": [55, 95], "bl": [10, 110], "fa": [110, 40], "ba": [90, 50]}
		"jkick":
			return {"air": true, "lean": -12, "fl": [72, 2], "bl": [-15, 110], "fa": [50, 90], "ba": [-30, 60]}
		"hurt":
			return {"lean": -22, "ht": -15, "fl": [6, 6], "bl": [-16, 10], "fa": [-30, 20], "ba": [-50, 20]}
		"held":
			return {"lean": 18, "ht": 20, "fl": [6, 10], "bl": [-10, 12], "fa": [20, 30], "ba": [0, 30]}
		"fall", "thrown":
			return {"air": true, "rot": minf(80.0, 25.0 + t * 160.0), "ox": 0, "lean": -10, "fl": [20, 30], "bl": [-10, 20], "fa": [150, 20], "ba": [120, 30]}
		"lying", "dead":
			return {"rot": 90.0, "ox": 20, "fl": [4, 0], "bl": [-6, 0], "fa": [165, 10], "ba": [150, 0]}
		"getup":
			return {"lean": 38, "fl": [72, 120], "bl": [-12, 100], "fa": [60, 40], "ba": [40, 40]}
		"grab":
			return {"lean": 12, "fl": [16, 12], "bl": [-14, 12], "fa": [78, 40], "ba": [72, 50]}
		"knee":
			if t < 0.08:
				return {"lean": 6, "fl": [50, 80], "bl": [-10, 10], "fa": [75, 45], "ba": [70, 50]}
			return {"lean": 14, "fl": [95, 125], "bl": [-6, 6], "fa": [75, 45], "ba": [70, 50]}
		"throw":
			if t < 0.14:
				return {"lean": -6, "fl": [16, 14], "bl": [-12, 12], "fa": [110, 50], "ba": [100, 50]}
			return {"lean": -35, "fl": [20, 10], "bl": [-20, 10], "fa": [170, 10], "ba": [160, 10]}
		"spec":
			return {"lean": -10, "fl": [92, 2], "bl": [-6, 8], "fa": [90, 10], "ba": [-90, 10]}
		"bwind":
			return {"lean": -8, "fl": [30, 45], "bl": [-30, 40], "fa": [-30, 30], "ba": [-45, 30]}
		"brec":
			return {"lean": 26, "ht": 15, "fl": [16, 20], "bl": [-14, 16], "fa": [10, 30], "ba": [0, 30]}
		"stomp":
			if t < 0.4:
				return {"air": true, "lean": -5, "fl": [85, 100], "bl": [-6, 8], "fa": [120, 30], "ba": [110, 30]}
			return {"lean": 24, "fl": [30, 40], "bl": [-28, 30], "fa": [60, 10], "ba": [40, 10]}
		"win":
			return {"lean": -4, "fl": [10, 6], "bl": [-10, 6], "fa": [175, 0], "ba": [30, 110]}
		"show":
			return {"lean": -18, "fl": [97, 4], "bl": [-8, 6], "fa": [40, 120], "ba": [-25, 60]}
	return idle
