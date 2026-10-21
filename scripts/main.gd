extends Node3D
## NÉON BOULEVARD — beat'em up 2.5D façon Streets of Rage.
## Logique en "px de jeu" : x = avancée, y = profondeur (150..206), z = hauteur.
## Le rendu convertit en 3D : 1 unité = 10 px.

const W := 384.0
const H := 216.0
const TOP := 150.0
const BOT := 206.0
const GRAV := 620.0
const S3 := 0.1
const K := 5.0

const LOOKS := {
	"jade": {"skin": "#eab48c", "hair": "#1c1730", "hs": "pony", "top": "#1db3a6", "sleeve": 1, "pants": "#2b2f52", "shoe": "#f1efe8", "acc": "#ff5a3c", "bulk": 1.0, "s": 1.0},
	"bruno": {"skin": "#b47448", "hair": "#24160c", "hs": "buzz", "top": "#e3dccb", "sleeve": 0, "pants": "#38598c", "shoe": "#3a281c", "acc": "#e0363a", "bulk": 1.22, "s": 1.06, "band": 1},
	"punk": {"skin": "#d9a07a", "hair": "#ff3f9e", "hs": "mohawk", "top": "#5d2b8a", "sleeve": 0, "pants": "#23212b", "shoe": "#121016", "acc": "#c9c9d6", "bulk": 1.0, "s": 1.0},
	"punk2": {"skin": "#c98e66", "hair": "#ffd23f", "hs": "mohawk", "top": "#2a5f8a", "sleeve": 0, "pants": "#2b2420", "shoe": "#121016", "acc": "#c9c9d6", "bulk": 1.0, "s": 1.0},
	"rodeur": {"skin": "#c08660", "hair": "#3f7d3a", "hs": "hood", "top": "#3f7d3a", "sleeve": 1, "pants": "#4a4b55", "shoe": "#1a1a1f", "acc": "#9ed36a", "bulk": 0.95, "s": 1.0},
	"costaud": {"skin": "#a86f48", "hair": "#000000", "hs": "bald", "top": "#c4682a", "sleeve": 0, "pants": "#c4682a", "shoe": "#2a1d14", "acc": "#ffd23f", "bulk": 1.45, "s": 1.28},
	"boss": {"skin": "#d9a686", "hair": "#e9e9ef", "hs": "slick", "top": "#3b3a48", "sleeve": 1, "pants": "#22222b", "shoe": "#0e0e12", "acc": "#d8263a", "bulk": 1.4, "s": 1.42, "coat": 1},
}

const HEROES := {
	"jade": {"name": "JADE", "look": "jade", "spd": 74.0, "hp": 100.0, "blurb": "Rapide, combos vifs", "stat": [4, 2, 5],
		"atk": [{"id": "jab", "s": 0.04, "a": 0.07, "r": 0.11, "d": 4, "reach": 24.0},
			{"id": "cross", "s": 0.04, "a": 0.07, "r": 0.13, "d": 5, "reach": 25.0},
			{"id": "kick", "s": 0.09, "a": 0.1, "r": 0.24, "d": 10, "reach": 31.0, "ko": true, "step": 30.0}],
		"jk": {"d": 11, "reach": 26.0}, "knee": 6, "thr": 18},
	"bruno": {"name": "BRUNO", "look": "bruno", "spd": 56.0, "hp": 110.0, "blurb": "Lent, frappe très fort", "stat": [2, 5, 3],
		"atk": [{"id": "jab", "s": 0.06, "a": 0.08, "r": 0.14, "d": 6, "reach": 23.0},
			{"id": "cross", "s": 0.06, "a": 0.08, "r": 0.16, "d": 7, "reach": 24.0},
			{"id": "upper", "s": 0.12, "a": 0.1, "r": 0.3, "d": 14, "reach": 25.0, "ko": true, "step": 16.0}],
		"jk": {"d": 14, "reach": 25.0}, "knee": 8, "thr": 26},
}

const ETYPES := {
	"punk": {"names": ["ZED", "KROK", "RAZ", "DIXIE", "FLINT"], "hp": 30.0, "spd": 42.0, "atk": {"id": "jab", "s": 0.3, "a": 0.1, "r": 0.32, "d": 6, "reach": 22.0}, "score": 500, "cd": [0.7, 1.5]},
	"rodeur": {"names": ["SILEX", "NOX", "VIRGULE", "ORTIE"], "hp": 26.0, "spd": 64.0, "atk": {"id": "dash", "s": 0.38, "a": 0.3, "r": 0.38, "d": 9, "reach": 22.0, "dash": 150.0, "ko": true, "range": 62.0}, "score": 700, "cd": [1.0, 1.9]},
	"costaud": {"names": ["BARIL", "GRANIT", "TANK"], "hp": 80.0, "spd": 28.0, "atk": {"id": "heavy", "s": 0.48, "a": 0.12, "r": 0.48, "d": 13, "reach": 27.0, "ko": true}, "score": 1500, "cd": [1.0, 2.0], "armor": true},
	"boss": {"names": ["LE CONTREMAÎTRE"], "hp": 280.0, "spd": 36.0, "atk": {"id": "heavy", "s": 0.4, "a": 0.12, "r": 0.42, "d": 14, "reach": 33.0, "ko": true}, "score": 20000, "cd": [0.7, 1.3], "armor": true, "boss": true},
}

const STAGES := [
	{"name": "BOULEVARD NÉON", "len": 1520.0, "kind": "city",
		"zones": [{"lock": 384.0, "waves": [["punk", "punk"], ["punk", "rodeur"]]},
			{"lock": 770.0, "waves": [["punk", "rodeur", "punk"], ["rodeur", "rodeur", "punk"]]},
			{"lock": 1150.0, "waves": [["punk", "punk", "punk"], ["costaud"]]},
			{"lock": 1520.0, "waves": [["costaud", "punk", "rodeur"], ["punk", "rodeur"]]}],
		"props": [[200, 170, "can", "apple"], [560, 196, "can", ""], [690, 165, "crate", "cash"], [980, 190, "can", "apple"], [1300, 168, "crate", "chicken"]]},
	{"name": "LES DOCKS", "len": 1560.0, "kind": "docks",
		"zones": [{"lock": 400.0, "waves": [["rodeur", "punk", "punk"], ["costaud", "rodeur"]]},
			{"lock": 820.0, "waves": [["punk", "punk", "rodeur", "rodeur"], ["costaud", "costaud"]]},
			{"lock": 1180.0, "waves": [["rodeur", "rodeur", "punk"], ["costaud", "punk", "punk"]]},
			{"lock": 1560.0, "boss": true, "waves": [["boss"]]}],
		"props": [[260, 190, "crate", "apple"], [640, 170, "crate", "cash"], [1000, 192, "can", "chicken"], [1320, 170, "crate", "apple"], [1420, 195, "can", "chicken"]]},
]

const VULN := ["idle", "walk", "enter", "eatk", "hurt", "held", "bwind", "brec", "charge", "stomp", "wait"]


class Ent:
	var kind := "e"
	var etype := ""
	var T := {}
	var look := {}
	var ename := ""
	var x := 0.0
	var y := 178.0
	var z := 0.0
	var vx := 0.0
	var vy := 0.0
	var vz := 0.0
	var face := 1.0
	var hp := 0.0
	var maxhp := 0.0
	var st := "idle"
	var t := 0.0
	var cd := 0.0
	var hit_set := {}
	var wph := 0.0
	var moving := false
	var ph := 0.0
	var poise := 4
	var slot := 0
	var sp_t := 5.0
	var summoned := false
	var flash := 0.0
	var dead := false
	var engaged := false
	var atk := {}
	var hit_done := false
	var ch_dir := 1.0
	var thrown_hits := {}
	var inv := 0.0
	var h := {}
	var combo := 0
	var combo_t := 9.0
	var last_hit := false
	var buffer := false
	var knees := 0
	var held = null
	var kicked := false
	var knee_hit := false
	var rig = null


class Prop:
	var x := 0.0
	var y := 0.0
	var kind := ""
	var drop := ""
	var broken := false
	var node: Node3D = null


class Item:
	var x := 0.0
	var y := 0.0
	var z := 6.0
	var vz := 60.0
	var kind := ""
	var t := 0.0
	var taken := false
	var node: Node3D = null


class Fx:
	var k := ""
	var x := 0.0
	var y := 0.0
	var z := 0.0
	var h := 0.0
	var vx := 0.0
	var vz := 0.0
	var phys := false
	var t := 0.0
	var life := 0.3
	var big := false
	var c := ""
	var spin := 0.0
	var node: MeshInstance3D = null


class Txt:
	var x := 0.0
	var y := 0.0
	var h := 0.0
	var s := ""
	var c := Color.WHITE
	var t := 0.0


var mode := "title"
var time := 0.0
var stage_i := 0
var cam_x := 0.0
var zi := 0
var zone_on := false
var wave := 0
var spawn_q: Array = []
var enemies: Array = []
var props: Array = []
var items: Array = []
var fxs: Array = []
var texts: Array = []
var score := 0
var lives := 2
var hitstop := 0.0
var shake := 0.0
var banner = null
var go_t := 0.0
var last_foe = null
var last_foe_t := 0.0
var sel := 0
var mode_t := 0.0
var P = null
var I := {}
var dummies := {}
var high_quality := true

var cam: Camera3D
var world_env: WorldEnvironment
var sun: DirectionalLight3D
var rain: GPUParticles3D
var built := {}
var cur_stage := -1
var dyn: Node3D
var hud: Hud
var sfx: Sfx
var font_b: SystemFont
var font_r: SystemFont
var glow_tex: GradientTexture2D
var ring_tex: GradientTexture2D
var quad1: QuadMesh
var deb_box: BoxMesh
var prop_mats := {}


# ------------------------------------------------------------------ DÉMARRAGE
func _ready() -> void:
	randomize()
	_setup_input()
	cam = Camera3D.new()
	cam.fov = 36.0
	cam.far = 800.0
	add_child(cam)
	cam.current = true
	world_env = WorldEnvironment.new()
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	sun.look_at_from_position(Vector3(-16, 38, 26), Vector3(0, 0, 0), Vector3.UP)
	dyn = Node3D.new()
	add_child(dyn)
	_make_rain()
	font_b = SystemFont.new()
	font_b.font_names = PackedStringArray(["Impact", "Arial Black", "Segoe UI Black", "Arial"])
	font_r = SystemFont.new()
	font_r.font_names = PackedStringArray(["Segoe UI", "Arial", "Helvetica"])
	font_r.font_weight = 700
	glow_tex = _radial([[0.0, Color(1, 1, 1, 1)], [0.3, Color(1, 1, 1, 0.5)], [1.0, Color(1, 1, 1, 0)]])
	ring_tex = _radial([[0.0, Color(1, 1, 1, 0)], [0.78, Color(1, 1, 1, 0)], [0.9, Color(1, 1, 1, 1)], [1.0, Color(1, 1, 1, 0)]])
	quad1 = QuadMesh.new()
	quad1.size = Vector2(1, 1)
	deb_box = BoxMesh.new()
	deb_box.size = Vector3(0.3, 0.3, 0.3)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfx = Sfx.new()
	add_child(sfx)
	dummies["jade"] = _dummy("jade", 1.0, 0.0)
	dummies["bruno"] = _dummy("bruno", -1.0, 1.3)
	_show_stage(0)


func _dummy(hero: String, face: float, ph: float) -> Ent:
	var e := Ent.new()
	e.look = LOOKS[HEROES[hero].look]
	e.face = face
	e.ph = ph
	return e


func _add_action(n: String, keys: Array, phys: Array, joys: Array, axis := -1, dir := 0.0) -> void:
	if not InputMap.has_action(n):
		InputMap.add_action(n, 0.35)
	for k in keys:
		var ev := InputEventKey.new()
		ev.keycode = k
		InputMap.action_add_event(n, ev)
	for k in phys:
		var ev2 := InputEventKey.new()
		ev2.physical_keycode = k
		InputMap.action_add_event(n, ev2)
	for b in joys:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(n, jb)
	if axis >= 0:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axis
		jm.axis_value = dir
		InputMap.action_add_event(n, jm)


func _setup_input() -> void:
	# ZQSD sur clavier AZERTY = touches physiques WASD
	_add_action("left", [KEY_LEFT], [KEY_A], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add_action("right", [KEY_RIGHT], [KEY_D], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add_action("up", [KEY_UP], [KEY_W], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_add_action("down", [KEY_DOWN], [KEY_S], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_add_action("punch", [], [KEY_J, KEY_X], [JOY_BUTTON_X])
	_add_action("jump", [], [KEY_K, KEY_C], [JOY_BUTTON_A])
	_add_action("special", [], [KEY_L, KEY_V], [JOY_BUTTON_Y, JOY_BUTTON_B])
	_add_action("start", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [], [JOY_BUTTON_START])
	_add_action("pause", [KEY_P, KEY_ESCAPE], [], [JOY_BUTTON_BACK])
	_add_action("mute", [KEY_M], [], [])
	_add_action("fullscreen", [KEY_F11], [], [])
	_add_action("quality", [KEY_F2], [], [])


func _read_input() -> void:
	I = {
		"l": Input.is_action_pressed("left"), "r": Input.is_action_pressed("right"),
		"u": Input.is_action_pressed("up"), "d": Input.is_action_pressed("down"),
		"pPunch": Input.is_action_just_pressed("punch"), "pJump": Input.is_action_just_pressed("jump"),
		"pSpec": Input.is_action_just_pressed("special"), "pStart": Input.is_action_just_pressed("start"),
		"pL": Input.is_action_just_pressed("left"), "pR": Input.is_action_just_pressed("right"),
		"pU": Input.is_action_just_pressed("up"), "pD": Input.is_action_just_pressed("down"),
	}


func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	_read_input()
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()
	if Input.is_action_just_pressed("mute"):
		sfx.toggle_mute()
		sfx.set_music(mode == "play" or mode == "pause")
	if Input.is_action_just_pressed("fullscreen"):
		var m := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if m == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if Input.is_action_just_pressed("quality"):
		_set_quality(not high_quality)
	_update(dt)
	_render(dt)
	hud.queue_redraw()


func _set_quality(hq: bool) -> void:
	high_quality = hq
	sun.shadow_enabled = hq
	for kk in built:
		var env: Environment = built[kk].env
		env.ssr_enabled = hq
		env.ssao_enabled = hq
	get_viewport().msaa_3d = Viewport.MSAA_4X if hq else Viewport.MSAA_DISABLED


# ------------------------------------------------------------------ OUTILS
func _rnd(a: float, b: float) -> float:
	return randf_range(a, b)


func _pick(a: Array):
	return a[randi() % a.size()]


func _sfx(n: String) -> void:
	sfx.play(n)


func _radial(stops: Array) -> GradientTexture2D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for s in stops:
		offs.append(s[0])
		cols.append(s[1])
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


# ------------------------------------------------------------------ PARTIE
func _new_player(hero: String) -> Ent:
	var h: Dictionary = HEROES[hero]
	var e := Ent.new()
	e.kind = "p"
	e.h = h
	e.look = LOOKS[h.look]
	e.x = 60.0
	e.y = 180.0
	e.hp = h.hp
	e.maxhp = h.hp
	return e


func _free_rig(e) -> void:
	if e and e.rig:
		e.rig.queue_free()
		e.rig = null


func _start_stage(i: int) -> void:
	stage_i = i
	var S: Dictionary = STAGES[i]
	for e in enemies:
		_free_rig(e)
	for c in dyn.get_children():
		c.queue_free()
	cam_x = 0.0
	zi = 0
	zone_on = false
	wave = 0
	spawn_q = []
	enemies = []
	items = []
	fxs = []
	texts = []
	go_t = 0.0
	last_foe = null
	props = []
	for p in S.props:
		var pr := Prop.new()
		pr.x = p[0]
		pr.y = p[1]
		pr.kind = p[2]
		pr.drop = p[3]
		pr.node = _make_prop(pr.kind)
		pr.node.position = Vector3(pr.x * S3, 0, (pr.y - 178.0) * S3)
		pr.node.rotation.y = randf() * 0.6
		dyn.add_child(pr.node)
		props.append(pr)
	P.x = 50.0
	P.y = 180.0
	P.z = 0.0
	P.st = "idle"
	P.t = 0.0
	P.held = null
	P.inv = 1.5
	P.face = 1.0
	banner = {"t": 0.0, "dur": 2.6, "a": "STAGE %d" % (i + 1), "b": S.name, "warn": false}
	mode = "play"
	sfx.set_music(true)
	_show_stage(i)


func _spawn_enemy(et: String, side: float) -> Ent:
	var T: Dictionary = ETYPES[et]
	var lk := et
	if et == "punk" and randf() < 0.5:
		lk = "punk2"
	var e := Ent.new()
	e.etype = et
	e.T = T
	e.look = LOOKS[lk]
	e.ename = _pick(T.names)
	e.x = cam_x - 24.0 if side < 0 else cam_x + W + 24.0
	e.y = _rnd(TOP + 4.0, BOT - 4.0)
	e.face = -side
	e.hp = T.hp
	e.maxhp = T.hp
	e.st = "enter"
	e.cd = _rnd(0.6, 1.2)
	e.wph = randf() * 6.0
	e.moving = true
	e.ph = randf() * 6.0
	e.sp_t = _rnd(4.0, 6.0)
	enemies.append(e)
	return e


# ------------------------------------------------------------------ EFFETS
func _spark(x: float, y: float, h: float, big: bool) -> void:
	var f := Fx.new()
	f.k = "spark"
	f.x = x
	f.y = y
	f.h = h
	f.big = big
	f.life = 0.22 if big else 0.15
	fxs.append(f)


func _dust(x: float, y: float) -> void:
	for i in 6:
		var f := Fx.new()
		f.k = "dust"
		f.x = x + _rnd(-8, 8)
		f.y = y + _rnd(-3, 3)
		f.z = _rnd(0, 3)
		f.vx = _rnd(-30, 30)
		f.vz = _rnd(10, 40)
		f.phys = true
		f.life = 0.5
		fxs.append(f)


func _debris(x: float, y: float, c: String) -> void:
	for i in 10:
		var f := Fx.new()
		f.k = "deb"
		f.x = x
		f.y = y + _rnd(-4, 4)
		f.z = 8.0
		f.vx = _rnd(-60, 60)
		f.vz = _rnd(40, 140)
		f.phys = true
		f.life = 0.9
		f.c = c
		f.spin = _rnd(-12, 12)
		fxs.append(f)


func _pop(x: float, y: float, h: float, s: String, c: Color) -> void:
	var t := Txt.new()
	t.x = x
	t.y = y
	t.h = h
	t.s = s
	t.c = c
	texts.append(t)


func _hitstop(t: float) -> void:
	hitstop = maxf(hitstop, t)


func _shake(a: float) -> void:
	shake = maxf(shake, a)


# ------------------------------------------------------------------ COMBAT
func _vuln(e) -> bool:
	return e.st in VULN


func _player_strike(def: Dictionary, both: bool, z_tol := 16.0) -> bool:
	var hit := false
	var reach: float = def.reach
	for e in enemies:
		if P.hit_set.has(e) or not _vuln(e):
			continue
		var boss: bool = e.T.get("boss", false)
		var rel: float = (e.x - P.x) * P.face
		var dy: float = absf(e.y - P.y)
		var ok_x: bool
		if both:
			ok_x = absf(e.x - P.x) < reach
		else:
			ok_x = rel > -4.0 and rel < reach * (1.15 if boss else 1.0)
		if ok_x and dy < 9.0 and absf(e.z - P.z) < z_tol + (10.0 if boss else 0.0):
			P.hit_set[e] = true
			var dir: float = P.face
			if both:
				dir = signf(e.x - P.x) if e.x != P.x else 1.0
			_hit_enemy(e, float(def.d), def.get("ko", false), dir)
			hit = true
	for pr in props:
		if pr.broken or P.hit_set.has(pr):
			continue
		var rel2: float = (pr.x - P.x) * P.face
		var okp: bool = absf(pr.x - P.x) < reach if both else (rel2 > -4.0 and rel2 < reach + 4.0)
		if okp and absf(pr.y - P.y) < 10.0:
			P.hit_set[pr] = true
			_break_prop(pr)
			hit = true
	if hit:
		P.last_hit = true
	return hit


func _break_prop(pr) -> void:
	pr.broken = true
	_sfx("break")
	_debris(pr.x, pr.y, "#8a93a6" if pr.kind == "can" else "#a8743a")
	score += 100
	_shake(1.5)
	if pr.drop != "":
		var it := Item.new()
		it.x = pr.x
		it.y = pr.y
		it.kind = pr.drop
		items.append(it)


func _hit_enemy(e, d: float, ko: bool, dir: float) -> void:
	e.hp -= d
	e.flash = 0.08
	score += int(d * 10)
	last_foe = e
	last_foe_t = 3.0
	_spark(e.x - dir * 4.0, e.y, e.z + 30.0 * float(e.look.s), d >= 10)
	_hitstop(0.08 if d >= 10 else 0.045)
	_sfx("heavy" if d >= 10 else "hit")
	if d >= 10:
		_shake(2.0)
	if e.st == "held":
		if e.hp <= 0 or ko:
			_release()
			_knockdown(e, dir, e.hp <= 0)
		return
	if e.hp <= 0:
		_knockdown(e, dir, true)
		return
	if e.T.get("boss", false):
		e.poise -= 1
		if e.poise <= 0 and ko:
			e.poise = 4
			_knockdown(e, dir, false)
		elif e.poise <= 0 and not (e.st in ["charge", "stomp", "bwind"]):
			e.poise = 4
			e.st = "hurt"
			e.t = 0.0
			e.vx = dir * 30.0
		return
	if e.T.get("armor", false) and e.st == "eatk" and e.t < float(e.atk.s) + float(e.atk.a) and not ko:
		return
	if ko:
		_knockdown(e, dir, false)
		return
	e.st = "hurt"
	e.t = 0.0
	e.vx = dir * 34.0


func _knockdown(e, dir: float, dead: bool) -> void:
	var boss: bool = e.T.get("boss", false)
	e.st = "fall"
	e.t = 0.0
	e.vz = 110.0 if boss else 150.0
	e.vx = dir * (50.0 if boss else 85.0)
	e.z = maxf(e.z, 1.0)
	e.dead = dead
	if dead:
		_sfx("ko")
		score += int(e.T.score)
		_pop(e.x, e.y, 55.0, "+%d" % int(e.T.score), Color("#ffd23f"))


func _release() -> void:
	if P.held:
		var e = P.held
		if e.st == "held":
			e.st = "idle"
			e.t = 0.0
			e.cd = 0.6
		P.held = null


func _hit_player(d: float, ko: bool, src) -> bool:
	if P.inv > 0 or P.st in ["fall", "lying", "getup", "dead", "spec", "throw"]:
		return false
	if P.st == "grab" or P.st == "knee":
		_release()
	P.hp -= d
	P.flash = 0.1
	_sfx("hurt")
	_shake(3.0 if d >= 12 else 2.0)
	_hitstop(0.06)
	_spark(P.x, P.y, P.z + 30.0, d >= 12)
	var dir: float = signf(P.x - src.x) if P.x != src.x else 1.0
	if P.hp <= 0:
		P.hp = 0.0
		P.st = "fall"
		P.t = 0.0
		P.vz = 150.0
		P.vx = dir * 80.0
		P.z = maxf(P.z, 1.0)
		P.dead = true
		_sfx("ko")
		return true
	if ko or d >= 12 or P.z > 0:
		P.st = "fall"
		P.t = 0.0
		P.vz = 140.0
		P.vx = dir * 80.0
		P.z = maxf(P.z, 1.0)
		P.dead = false
	else:
		P.st = "hurt"
		P.t = 0.0
		P.vx = dir * 40.0
	return true


# ------------------------------------------------------------------ JOUEUR
func _set_p(st: String) -> void:
	P.st = st
	P.t = 0.0


func _start_combo() -> void:
	var h: Dictionary = P.h
	if P.last_hit and P.combo_t < 0.45:
		P.combo = (P.combo + 1) % 3
	else:
		P.combo = 0
	P.last_hit = false
	P.buffer = false
	P.atk = h.atk[P.combo]
	P.hit_set = {}
	_set_p("atk")
	_sfx("swing")


func _upd_player(dt: float) -> void:
	var h: Dictionary = P.h
	P.t += dt
	if P.inv > 0:
		P.inv -= dt
	if P.flash > 0:
		P.flash -= dt
	P.combo_t += dt
	var ix := (1 if I.r else 0) - (1 if I.l else 0)
	var iy := (1 if I.d else 0) - (1 if I.u else 0)
	var spd: float = h.spd
	P.moving = false
	match P.st:
		"idle", "walk", "land":
			if P.st == "land" and P.t < 0.07:
				pass
			elif I.pSpec and P.hp > 8:
				_set_p("spec")
				P.hp -= 6.0
				P.hit_set = {}
				P.inv = 0.5
				_sfx("swing")
			elif I.pJump:
				_set_p("jump")
				P.vz = 215.0
				P.vx = ix * spd * 1.1
				P.vy = iy * spd * 0.45
				P.kicked = false
				_sfx("jump")
			elif I.pPunch:
				_start_combo()
			elif ix != 0 or iy != 0:
				if ix != 0:
					P.face = float(ix)
				P.moving = true
				P.st = "walk"
				P.x += ix * spd * dt
				P.y += iy * spd * 0.6 * dt
				P.wph += dt * 11.0
				if ix != 0 and float(ix) == P.face:
					for e in enemies:
						if e.T.get("boss", false) or not (e.st in ["idle", "walk", "wait"]) or e.z > 0:
							continue
						var rel: float = (e.x - P.x) * P.face
						if rel > 4.0 and rel < 15.0 and absf(e.y - P.y) < 5.0:
							_set_p("grab")
							P.held = e
							e.st = "held"
							e.t = 0.0
							e.face = -P.face
							P.knees = 0
							break
			else:
				P.st = "idle"
		"atk":
			var A: Dictionary = P.atk
			var s: float = A.s
			var a: float = A.a
			var r: float = A.r
			if I.pPunch and P.t > s:
				P.buffer = true
			if P.t >= s and P.t < s + a:
				if A.has("step"):
					P.x += P.face * float(A.step) * dt
				_player_strike(A, false)
			if P.t >= s + a + r:
				var b: bool = P.buffer
				_set_p("idle")
				P.combo_t = 0.0
				if b:
					_start_combo()
		"jump", "jkick":
			P.x += P.vx * dt
			P.y += P.vy * dt
			P.z += P.vz * dt
			P.vz -= GRAV * dt
			if P.st == "jump" and I.pPunch and not P.kicked:
				P.st = "jkick"
				P.kicked = true
				P.hit_set = {}
				_sfx("swing")
			if P.st == "jkick":
				_player_strike({"d": h.jk.d, "reach": h.jk.reach, "ko": true}, false, 22.0)
			if P.z <= 0:
				P.z = 0.0
				P.vz = 0.0
				_set_p("land")
				_sfx("land")
				_dust(P.x, P.y)
		"spec":
			if P.t > 0.04 and P.t < 0.44:
				_player_strike({"d": 10, "reach": 32.0, "ko": true}, true)
			if P.t > 0.55:
				_set_p("idle")
		"grab":
			var e = P.held
			if e == null or e.st != "held":
				P.held = null
				_set_p("idle")
			else:
				e.x = P.x + P.face * 13.0
				e.y = P.y
				e.face = -P.face
				if I.pPunch:
					if ix != 0 and float(ix) == -P.face:
						_set_p("throw")
						P.face = -P.face
						e.x = P.x - P.face * 6.0
						_sfx("swing")
					else:
						_set_p("knee")
						P.knee_hit = false
				elif I.pJump:
					_release()
					_set_p("jump")
					P.vz = 215.0
					P.vx = 0.0
					P.vy = 0.0
					P.kicked = false
				elif P.t > 1.6:
					_release()
					_set_p("idle")
		"knee":
			var e2 = P.held
			if e2 and e2.st == "held":
				e2.x = P.x + P.face * 13.0
				e2.y = P.y
			if P.t > 0.08 and not P.knee_hit:
				P.knee_hit = true
				if e2 and e2.st == "held":
					P.knees += 1
					var fin: bool = P.knees >= 3
					_hit_enemy(e2, float(h.knee), fin, P.face)
					if fin:
						_release()
			if P.t > 0.26:
				if P.held and P.held.st == "held":
					P.st = "grab"
					P.t = 0.3
				else:
					P.held = null
					_set_p("idle")
		"throw":
			var e3 = P.held
			if P.t > 0.16 and e3 and e3.st == "held":
				e3.st = "thrown"
				e3.t = 0.0
				e3.vz = 170.0
				e3.vx = P.face * 175.0
				e3.z = 12.0
				e3.hp -= float(h.thr)
				e3.flash = 0.1
				last_foe = e3
				last_foe_t = 3.0
				score += int(h.thr) * 10
				e3.thrown_hits = {}
				P.held = null
				_sfx("heavy")
				_shake(2.0)
			if P.t > 0.4:
				_set_p("idle")
		"hurt":
			P.x += P.vx * dt
			P.vx *= 0.86
			if P.t > 0.32:
				_set_p("idle")
		"fall":
			P.x += P.vx * dt
			P.z += P.vz * dt
			P.vz -= GRAV * dt
			if P.z <= 0:
				P.z = 0.0
				_set_p("dead" if P.dead else "lying")
				_shake(2.0)
				_sfx("land")
				_dust(P.x, P.y)
		"lying":
			if P.t > 0.75:
				_set_p("getup")
		"getup":
			if P.t > 0.32:
				_set_p("idle")
				P.inv = 1.1
		"dead":
			if P.t > 1.3:
				if lives <= 0:
					mode = "over"
					mode_t = 0.0
					sfx.set_music(false)
				else:
					lives -= 1
					P.hp = P.maxhp
					_set_p("fall")
					P.inv = 2.6
					P.z = 70.0
					P.vz = 0.0
					P.vx = 0.0
					P.dead = false
					for e4 in enemies:
						if _vuln(e4) and not e4.T.get("boss", false) and absf(e4.x - P.x) < 120.0:
							_knockdown(e4, signf(e4.x - P.x) if e4.x != P.x else 1.0, false)
					_pop(P.x, P.y, 70.0, "VIE -1", Color("#ff4f8b"))
	P.x = clampf(P.x, cam_x + 16.0, cam_x + W - 16.0)
	P.y = clampf(P.y, TOP, BOT)
	if P.z == 0 and P.st in ["idle", "walk"]:
		for it in items:
			if it.z <= 0 and absf(it.x - P.x) < 12.0 and absf(it.y - P.y) < 8.0 and not it.taken:
				it.taken = true
				_sfx("pick")
				if it.kind == "apple":
					P.hp = minf(P.maxhp, P.hp + 30.0)
					_pop(it.x, it.y, 25.0, "+30 PV", Color("#7cff6b"))
				elif it.kind == "chicken":
					P.hp = P.maxhp
					_pop(it.x, it.y, 25.0, "PV MAX", Color("#7cff6b"))
				else:
					score += 1000
					_pop(it.x, it.y, 25.0, "+1000", Color("#ffd23f"))
	for it in items:
		if it.taken and it.node:
			it.node.queue_free()
			it.node = null
	items = items.filter(func(i): return not i.taken)


# ------------------------------------------------------------------ ENNEMIS
func _upd_enemies(dt: float) -> void:
	var pv: bool = not (P.st in ["fall", "lying", "getup", "dead"]) and P.inv <= 0
	var active := enemies.filter(func(e): return e.st in ["idle", "walk", "eatk", "hurt", "wait"])
	active.sort_custom(func(a, b): return absf(a.x - P.x) < absf(b.x - P.x))
	var eng := 0
	var slot := 0
	for e in active:
		if e.T.get("boss", false) or eng < 2:
			e.engaged = true
			eng += 1
		else:
			e.engaged = false
			e.slot = slot
			slot += 1
	for e in enemies:
		e.t += dt
		e.cd -= dt
		if e.flash > 0:
			e.flash -= dt
		e.moving = false
		var T: Dictionary = e.T
		var TA: Dictionary = T.atk
		var spd: float = T.spd
		var boss: bool = T.get("boss", false)
		match e.st:
			"enter":
				var tx: float = cam_x + 28.0 if e.x < cam_x else cam_x + W - 28.0
				var dx: float = tx - e.x
				if dx != 0:
					e.face = signf(dx)
				e.x += signf(dx) * spd * 1.2 * dt
				e.moving = true
				e.wph += dt * 9.0
				if absf(dx) < 4.0:
					e.st = "idle"
			"idle", "walk", "wait":
				e.face = 1.0 if P.x > e.x else -1.0
				var side := -1.0 if e.x < P.x else 1.0
				var tx2: float
				var ty2: float
				if e.engaged and pv:
					tx2 = P.x + side * (float(TA.reach) - 5.0)
					ty2 = P.y
				else:
					tx2 = P.x + side * (64.0 + (e.slot % 3) * 16.0)
					ty2 = clampf(P.y + (-14.0 if e.slot % 2 == 1 else 14.0), TOP, BOT)
				tx2 = clampf(tx2, cam_x + 10.0, cam_x + W - 10.0)
				var dx2: float = tx2 - e.x
				var dy2: float = ty2 - e.y
				var sp := spd * (1.0 if e.engaged else 0.7)
				if absf(dx2) > 3.0:
					e.x += signf(dx2) * minf(absf(dx2), sp * dt)
					e.moving = true
				if absf(dy2) > 2.0:
					e.y += signf(dy2) * minf(absf(dy2), sp * 0.6 * dt)
					e.moving = true
				if e.moving:
					e.wph += dt * (7.0 if boss else 9.0)
				var adx: float = absf(P.x - e.x)
				var ady: float = absf(P.y - e.y)
				if boss:
					e.sp_t -= dt
					if not e.summoned and e.hp < e.maxhp * 0.5:
						e.summoned = true
						_spawn_enemy("punk", -1.0)
						_spawn_enemy("punk", 1.0)
						_spawn_enemy("rodeur", -1.0)
						_pop(e.x, e.y, 75.0, "RENFORTS !", Color("#ff4f8b"))
					if e.sp_t <= 0 and pv:
						e.sp_t = _rnd(4.0, 6.5)
						if e.hp < e.maxhp * 0.6 and randf() < 0.45:
							e.st = "stomp"
							e.t = 0.0
							e.hit_done = false
							_sfx("swing")
							continue
						if adx > 50.0:
							e.st = "bwind"
							e.t = 0.0
							_sfx("warn")
							continue
				var rng: float = TA.get("range", TA.reach)
				if e.engaged and pv and e.cd <= 0 and adx < rng and ady < 5.0 and P.z < 30:
					e.st = "eatk"
					e.t = 0.0
					e.atk = TA
					e.hit_done = false
			"eatk":
				var A: Dictionary = e.atk
				var s: float = A.s
				var a: float = A.a
				var r: float = A.r
				if A.has("dash") and e.t >= s and e.t < s + a:
					e.x += e.face * float(A.dash) * dt
				if e.t >= s and e.t < s + a and not e.hit_done:
					var rel: float = (P.x - e.x) * e.face
					if rel > -4.0 and rel < float(A.reach) and absf(P.y - e.y) < 8.0 and P.z < 14:
						if _hit_player(float(A.d), A.get("ko", false), e):
							e.hit_done = true
				if e.t >= s + a + r:
					e.st = "idle"
					e.t = 0.0
					e.cd = _rnd(T.cd[0], T.cd[1])
			"bwind":
				e.face = 1.0 if P.x > e.x else -1.0
				if e.t > 0.65:
					e.st = "charge"
					e.t = 0.0
					e.hit_done = false
					e.ch_dir = e.face
			"charge":
				e.face = e.ch_dir
				e.x += e.ch_dir * 190.0 * dt
				e.moving = true
				e.wph += dt * 16.0
				var rel2: float = (P.x - e.x) * e.face
				if not e.hit_done and rel2 > -6.0 and rel2 < 30.0 and absf(P.y - e.y) < 10.0 and P.z < 16:
					if _hit_player(16.0, true, e):
						e.hit_done = true
				if e.t > 1.5 or e.x < cam_x + 14.0 or e.x > cam_x + W - 14.0:
					e.x = clampf(e.x, cam_x + 14.0, cam_x + W - 14.0)
					e.st = "brec"
					e.t = 0.0
			"brec":
				if e.t > 0.75:
					e.st = "idle"
					e.t = 0.0
					e.cd = 0.4
			"stomp":
				if e.t < 0.4:
					e.z = sin(e.t / 0.4 * PI / 2.0) * 18.0
				else:
					e.z = maxf(0.0, e.z - 300.0 * dt)
				if e.t >= 0.5 and not e.hit_done:
					e.hit_done = true
					e.z = 0.0
					_sfx("stomp")
					_shake(5.0)
					var f := Fx.new()
					f.k = "ring"
					f.x = e.x
					f.y = e.y
					f.life = 0.5
					fxs.append(f)
					_dust(e.x, e.y)
					if absf(P.x - e.x) < 95.0 and absf(P.y - e.y) < 24.0 and P.z < 4:
						_hit_player(11.0, true, e)
				if e.t > 1.1:
					e.st = "idle"
					e.t = 0.0
					e.cd = 0.5
			"hurt":
				e.x += e.vx * dt
				e.vx *= 0.85
				if e.t > 0.3:
					e.st = "idle"
					e.t = 0.0
					e.cd = maxf(e.cd, 0.25)
			"fall", "thrown":
				e.x += e.vx * dt
				e.z += e.vz * dt
				e.vz -= GRAV * dt
				if e.st == "thrown":
					for o in enemies:
						if o == e or e.thrown_hits.has(o) or not _vuln(o) or o.T.get("boss", false):
							continue
						if absf(o.x - e.x) < 16.0 and absf(o.y - e.y) < 10.0:
							e.thrown_hits[o] = true
							_hit_enemy(o, 10.0, true, signf(e.vx) if e.vx != 0 else 1.0)
				if e.z <= 0:
					e.z = 0.0
					e.vx = 0.0
					_shake(4.0 if boss else 2.0)
					_sfx("land")
					_dust(e.x, e.y)
					if e.st == "thrown" and e.hp <= 0 and not e.dead:
						e.dead = true
						_sfx("ko")
						score += int(T.score)
						_pop(e.x, e.y, 55.0, "+%d" % int(T.score), Color("#ffd23f"))
					e.st = "dead" if e.dead else "lying"
					e.t = 0.0
			"lying":
				if e.t > (0.6 if boss else 0.85):
					e.st = "getup"
					e.t = 0.0
			"getup":
				if e.t > 0.4:
					e.st = "idle"
					e.t = 0.0
					e.cd = _rnd(0.3, 0.8)
		if e.st != "enter":
			e.x = clampf(e.x, cam_x - 20.0, cam_x + W + 20.0)
		e.y = clampf(e.y, TOP, BOT)
	for i in enemies.size():
		for j in range(i + 1, enemies.size()):
			var a = enemies[i]
			var b = enemies[j]
			if a.z > 0 or b.z > 0 or a.st in ["held", "dead"] or b.st in ["held", "dead"]:
				continue
			var ddx: float = b.x - a.x
			var ddy: float = b.y - a.y
			if absf(ddx) < 12.0 and absf(ddy) < 6.0:
				var p := (12.0 - absf(ddx)) * 0.5 * (signf(ddx) if ddx != 0 else 1.0)
				a.x -= p * 0.5
				b.x += p * 0.5
				b.y += (signf(ddy) if ddy != 0 else 1.0) * 0.3
	for e in enemies:
		if e.st == "dead" and e.t > 1.1:
			_free_rig(e)
	enemies = enemies.filter(func(e): return not (e.st == "dead" and e.t > 1.1))


# ------------------------------------------------------------------ ZONES
func _upd_zones(dt: float) -> void:
	var S: Dictionary = STAGES[stage_i]
	var zones: Array = S.zones
	var z = zones[zi] if zi < zones.size() else null
	var max_cam: float = (float(z.lock) if z else float(S.len)) - W
	if not zone_on:
		var want: float = P.x - W * 0.42
		if want > cam_x:
			cam_x = minf(max_cam, cam_x + minf(want - cam_x, 160.0 * dt))
		if z and cam_x >= max_cam - 0.5:
			cam_x = max_cam
			zone_on = true
			wave = 0
			_queue_wave(z, 0)
			if z.get("boss", false):
				_sfx("warn")
				banner = {"t": 0.0, "dur": 2.2, "a": "ATTENTION", "b": "LE CONTREMAÎTRE", "warn": true}
	else:
		for q in spawn_q:
			q.t -= dt
			if q.t <= 0 and not q.done:
				q.done = true
				_spawn_enemy(q.type, q.side)
		spawn_q = spawn_q.filter(func(q): return not q.done)
		var alive := enemies.filter(func(e): return not e.dead).size()
		if alive == 0 and spawn_q.is_empty():
			wave += 1
			if wave < z.waves.size():
				_queue_wave(z, wave)
			else:
				zone_on = false
				zi += 1
				if zi >= zones.size():
					_stage_clear()
				else:
					go_t = 3.0
					_sfx("go")


func _queue_wave(z: Dictionary, i: int) -> void:
	var list: Array = z.waves[i]
	for k in list.size():
		var et: String = list[k]
		spawn_q.append({"type": et, "side": 1.0 if (et == "boss" or k % 2 == 0) else -1.0, "t": 0.3 + k * 0.55, "done": false})


func _stage_clear() -> void:
	mode = "clear"
	mode_t = 0.0
	P.st = "win"
	P.t = 0.0
	sfx.set_music(false)
	_sfx("pick")
	score += int(P.hp) * 50


func _toggle_pause() -> void:
	if mode == "play":
		mode = "pause"
	elif mode == "pause":
		mode = "play"


# ------------------------------------------------------------------ MISE À JOUR
func _update(dt: float) -> void:
	time += dt
	for k in dummies:
		dummies[k].t += dt
	match mode:
		"title":
			if I.pStart or I.pPunch:
				mode = "select"
				_sfx("sel")
			return
		"select":
			if I.pL or I.pR or I.pU or I.pD:
				sel = 1 - sel
				_sfx("sel")
			if I.pStart or I.pPunch:
				_free_rig(P)
				P = _new_player("bruno" if sel == 1 else "jade")
				score = 0
				lives = 2
				_start_stage(0)
				_sfx("go")
			return
		"over", "win":
			mode_t += dt
			_upd_fx(dt)
			if mode_t > 1.2 and (I.pStart or I.pPunch):
				mode = "title"
				_free_rig(P)
				for e in enemies:
					_free_rig(e)
				enemies = []
			return
		"pause":
			return
		"clear":
			mode_t += dt
			P.t += dt
			_upd_fx(dt)
			if mode_t > 3.2:
				if stage_i + 1 < STAGES.size():
					P.st = "idle"
					_start_stage(stage_i + 1)
				else:
					mode = "win"
					mode_t = 0.0
			return
	if banner:
		banner.t += dt
		if banner.t > banner.dur:
			banner = null
	if go_t > 0:
		go_t -= dt
	if last_foe_t > 0:
		last_foe_t -= dt
	if hitstop > 0:
		hitstop -= dt
		_upd_fx(dt)
		return
	_upd_player(dt)
	_upd_enemies(dt)
	_upd_zones(dt)
	for it in items:
		it.t += dt
		if it.z > 0 or it.vz > 0:
			it.z += it.vz * dt
			it.vz -= GRAV * dt
			if it.z <= 0:
				it.z = 0.0
				it.vz = 0.0
	_upd_fx(dt)


func _upd_fx(dt: float) -> void:
	for f in fxs:
		f.t += dt
		if f.phys:
			f.x += f.vx * dt
			f.z += f.vz * dt
			f.vz -= GRAV * dt
			if f.z < 0:
				f.z = 0.0
				f.vx *= 0.5
				f.vz = 0.0
		if f.t >= f.life and f.node:
			f.node.queue_free()
			f.node = null
	fxs = fxs.filter(func(f): return f.t < f.life)
	for t in texts:
		t.t += dt
	texts = texts.filter(func(t): return t.t < 1.0)
	if shake > 0:
		shake = maxf(0.0, shake - dt * 20.0)


# ------------------------------------------------------------------ RENDU 3D
func _show_stage(i: int) -> void:
	if cur_stage == i:
		return
	if not built.has(i):
		var S: Dictionary = STAGES[i]
		var L: float = float(S.len) * S3
		built[i] = StageBuilder.city(L) if S.kind == "city" else StageBuilder.docks(L)
	if cur_stage >= 0 and built.has(cur_stage):
		remove_child(built[cur_stage].node)
	cur_stage = i
	var B: Dictionary = built[i]
	add_child(B.node)
	world_env.environment = B.env
	sun.light_color = B.sun
	sun.light_energy = B.sun_energy
	rain.emitting = B.rain
	rain.visible = B.rain
	if not high_quality:
		_set_quality(false)


func _make_rain() -> void:
	rain = GPUParticles3D.new()
	rain.amount = 2600
	rain.lifetime = 0.9
	rain.preprocess = 1.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(32, 1, 14)
	pm.direction = Vector3(-0.08, -1, 0)
	pm.spread = 2.0
	pm.initial_velocity_min = 26.0
	pm.initial_velocity_max = 32.0
	pm.gravity = Vector3(0, -9.8, 0)
	rain.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.025, 0.75)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.8, 1.0, 0.35)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	q.material = m
	rain.draw_pass_1 = q
	rain.visibility_aabb = AABB(Vector3(-40, -30, -20), Vector3(80, 60, 40))
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain)


func _sync_fighter(e, dt: float, vis := true) -> void:
	if e.rig == null:
		e.rig = Rig.new(e.look)
		add_child(e.rig)
		e.rig.apply_pose(Pose.get_pose(e, time), dt, true)
	var r: Rig = e.rig
	r.position = Vector3(e.x * S3, e.z * S3, (e.y - 178.0) * S3)
	r.rotation = Vector3(0, (e.t / 0.55) * PI * 4.0 * e.face if e.st == "spec" else 0.0, 0)
	r.scale = Vector3(e.face, 1, 1)
	r.apply_pose(Pose.get_pose(e, time), dt)
	var fm := ""
	if e.flash > 0:
		fm = "w"
	elif e.st == "bwind" and int(e.t * 16.0) % 2 == 1:
		fm = "r"
	r.set_flash(fm)
	var v := vis
	if e.st == "dead" and int(e.t * 14.0) % 2 == 1:
		v = false
	if e.inv > 0 and e.st != "fall" and int(time * 16.0) % 2 == 1:
		v = false
	r.visible = v


func _make_prop(kind: String) -> Node3D:
	if prop_mats.is_empty():
		prop_mats = {
			"metal": StageBuilder.mat("#8a93a6", 0.35, 0.8), "metal_d": StageBuilder.mat("#5a6276", 0.4, 0.8),
			"wood": StageBuilder.mat("#a8743a", 0.75), "wood_d": StageBuilder.mat("#6a4520", 0.8),
			"apple": StageBuilder.mat("#d8262e", 0.28), "stem": StageBuilder.mat("#4a3020", 0.8),
			"chick": StageBuilder.mat("#c4742c", 0.35), "bone": StageBuilder.mat("#f0ebe0", 0.5),
			"cash": StageBuilder.mat("#5a8a3a", 0.6), "band": StageBuilder.mat("#e8d24a", 0.4, 0.3),
		}
	var g := Node3D.new()
	var M := prop_mats
	if kind == "can":
		StageBuilder.add(g, StageBuilder.cyl(0.8, 0.72, 2.2, 20), M.metal, Vector3(0, 1.1, 0))
		StageBuilder.add(g, StageBuilder.cyl(0.88, 0.88, 0.22, 20), M.metal_d, Vector3(0, 2.25, 0))
		for yy in [0.5, 1.5]:
			StageBuilder.add(g, StageBuilder.cyl(0.83, 0.83, 0.08, 20), M.metal_d, Vector3(0, yy, 0))
	elif kind == "crate":
		StageBuilder.add(g, StageBuilder.box(2.1, 2.1, 2.1), M.wood, Vector3(0, 1.05, 0))
		for yy in [0.35, 1.05, 1.75]:
			StageBuilder.add(g, StageBuilder.box(2.14, 0.12, 2.14), M.wood_d, Vector3(0, yy, 0))
		var cr := StageBuilder.add(g, StageBuilder.box(0.14, 2.8, 0.05), M.wood_d, Vector3(0, 1.05, 1.07))
		cr.rotation.z = 0.78
	elif kind == "apple":
		var ap := SphereMesh.new()
		ap.radius = 0.5
		ap.height = 1.0
		StageBuilder.add(g, ap, M.apple, Vector3(0, 0.5, 0))
		StageBuilder.add(g, StageBuilder.cyl(0.04, 0.05, 0.3, 6), M.stem, Vector3(0, 1.05, 0))
	elif kind == "chicken":
		var ch := SphereMesh.new()
		ch.radius = 0.7
		ch.height = 1.4
		var b := StageBuilder.add(g, ch, M.chick, Vector3(0, 0.55, 0))
		b.scale = Vector3(1.2, 0.75, 0.9)
		for zz in [-0.35, 0.35]:
			var bn := StageBuilder.add(g, StageBuilder.cyl(0.08, 0.08, 0.7, 8), M.bone, Vector3(0.9, 0.75, zz))
			bn.rotation.z = -1.0
	else:
		StageBuilder.add(g, StageBuilder.box(1.2, 0.55, 0.75), M.cash, Vector3(0, 0.3, 0))
		StageBuilder.add(g, StageBuilder.box(0.25, 0.57, 0.77), M.band, Vector3(0, 0.3, 0))
	if kind in ["apple", "chicken", "cash"]:
		var gl := MeshInstance3D.new()
		gl.mesh = quad1
		gl.material_override = _fx_mat(Color(1.6, 1.5, 1.0, 0.45), true, glow_tex, true)
		gl.scale = Vector3(2.4, 2.4, 1)
		gl.position.y = 0.6
		gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(gl)
	return g


func _fx_mat(col: Color, additive: bool, tex: Texture2D, billboard: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _make_fx_node(f) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	match f.k:
		"spark":
			mi.mesh = quad1
			mi.material_override = _fx_mat(Color(3.0, 2.6, 1.8, 1.0), true, glow_tex, true)
		"dust":
			mi.mesh = quad1
			mi.material_override = _fx_mat(Color(0.75, 0.72, 0.85, 0.5), false, glow_tex, true)
		"deb":
			mi.mesh = deb_box
			mi.material_override = StageBuilder.mat(f.c, 0.6, 0.7 if f.c == "#8a93a6" else 0.0)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		"ring":
			mi.mesh = quad1
			mi.material_override = _fx_mat(Color(3.0, 2.2, 0.6, 1.0), true, ring_tex, false)
			mi.rotation.x = -PI / 2.0
	dyn.add_child(mi)
	return mi


func _sync_dyn() -> void:
	for pr in props:
		if pr.node:
			pr.node.visible = not pr.broken
	for it in items:
		if it.node == null:
			it.node = _make_prop(it.kind)
			dyn.add_child(it.node)
		var bob := sin(time * 3.0 + it.x) * 0.12 + 0.1 if it.z <= 0 else 0.0
		it.node.position = Vector3(it.x * S3, it.z * S3 + bob, (it.y - 178.0) * S3)
		it.node.rotation.y = time * 1.5
	for f in fxs:
		if f.node == null:
			f.node = _make_fx_node(f)
		var k: float = f.t / f.life
		var m: StandardMaterial3D = f.node.material_override
		match f.k:
			"spark":
				f.node.position = Vector3(f.x * S3, f.h * S3, (f.y - 178.0) * S3 + 0.6)
				var s := (3.2 if f.big else 2.2) * (0.5 + k * 0.9)
				f.node.scale = Vector3(s, s, s)
				var c := Color(3.0, 3.0, 3.0) if k < 0.4 else Color(3.0, 2.2, 0.6)
				m.albedo_color = Color(c.r, c.g, c.b, 1.0 - k)
			"dust":
				f.node.position = Vector3(f.x * S3, f.z * S3 + 0.3, (f.y - 178.0) * S3)
				var s2 := 0.8 + k * 1.6
				f.node.scale = Vector3(s2, s2, s2)
				m.albedo_color.a = 0.45 * (1.0 - k)
			"deb":
				f.node.position = Vector3(f.x * S3, f.z * S3 + 0.15, (f.y - 178.0) * S3)
				f.node.rotation = Vector3(f.t * f.spin, f.t * f.spin * 0.7, 0)
			"ring":
				f.node.position = Vector3(f.x * S3, 0.05, (f.y - 178.0) * S3)
				var s3 := 2.0 + k * 20.0
				f.node.scale = Vector3(s3, s3 * 0.55, 1)
				m.albedo_color.a = 1.0 - k


func _render(dt: float) -> void:
	var cx := 0.0
	var cam_y := 11.5
	var cam_z := 34.0
	var look_y := 2.4
	var look_z := -1.0
	var show_dummies := mode == "title" or mode == "select"
	if show_dummies:
		_show_stage(0)
		var jd: Ent = dummies["jade"]
		var bd: Ent = dummies["bruno"]
		var L: float = float(STAGES[0].len) * S3
		if mode == "title":
			cx = 8.0 + fmod(time * 1.4, L - 30.0)
			jd.x = (cx - 5.2) / S3
			bd.x = (cx + 5.2) / S3
			jd.y = 238.0
			bd.y = 238.0
			jd.st = "idle"
			bd.st = "idle"
			cam_y = 5.2
			cam_z = 24.0
			look_y = 4.6
			look_z = 2.0
		else:
			cx = 30.0
			jd.x = (cx - 4.1) / S3
			bd.x = (cx + 4.1) / S3
			jd.y = 178.0
			bd.y = 178.0
			jd.st = "show" if sel == 0 else "idle"
			bd.st = "show" if sel == 1 else "idle"
			cam_y = 3.6
			cam_z = 16.0
			look_y = 2.7
			look_z = 0.0
		_sync_fighter(jd, dt)
		_sync_fighter(bd, dt)
	else:
		_show_stage(stage_i)
		cx = (cam_x + W / 2.0) * S3
		var pdt := 0.0 if mode == "pause" else dt
		if mode == "win":
			cx = P.x * S3
			cam_y = 5.0
			cam_z = 18.0
			look_y = 3.0
			look_z = (P.y - 178.0) * S3
		for e in enemies:
			_sync_fighter(e, pdt)
		if P:
			_sync_fighter(P, pdt)
		_sync_dyn()
	for k in dummies:
		if dummies[k].rig:
			dummies[k].rig.visible = show_dummies
	var sk := shake * 0.06
	var ox := randf_range(-sk, sk) if sk > 0 else 0.0
	var oy := randf_range(-sk, sk) if sk > 0 else 0.0
	cam.look_at_from_position(Vector3(cx + ox, cam_y + oy, cam_z), Vector3(cx, look_y, look_z), Vector3.UP)
	rain.position = Vector3(cx, 22, 2)


# ------------------------------------------------------------------ HUD
func _txt(c: Control, s: String, x: float, y: float, col: Color, align := 0, size := 8.0, bold := false) -> void:
	var f: Font = font_b if bold else font_r
	var fs := int(size * K)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var px := x * K
	if align == 1:
		px -= w / 2.0
	elif align == 2:
		px -= w
	var pos := Vector2(px, y * K)
	c.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(K * 1.4), Color(0, 0, 0, col.a * 0.9))
	c.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _rect(c: Control, x: float, y: float, w: float, h: float, col: Color) -> void:
	c.draw_rect(Rect2(x * K, y * K, w * K, h * K), col)


func _bar(c: Control, x: float, y: float, w: float, h: float, v: float, col: Color) -> void:
	_rect(c, x - 0.6, y - 0.6, w + 1.2, h + 1.2, Color(0, 0, 0, 0.85))
	_rect(c, x, y, w, h, Color(0.16, 0.12, 0.23, 0.9))
	var gw := w * clampf(v, 0.0, 1.0)
	_rect(c, x, y, gw, h, col)
	_rect(c, x, y, gw, h * 0.3, col.lightened(0.5))
	_rect(c, x, y + h * 0.7, gw, h * 0.3, col.darkened(0.35))


func draw_hud(c: Control) -> void:
	if mode == "title":
		_rect(c, 0, 0, W, H, Color(0.03, 0.02, 0.08, 0.3))
		for i in range(4, 0, -1):
			var a := 0.12
			_txt(c, "NÉON", W / 2.0 + i * 0.4, 64, Color(1, 0.31, 0.55, a), 1, 30, true)
		_txt(c, "NÉON", W / 2.0, 64, Color("#ff4f8b"), 1, 30, true)
		_txt(c, "BOULEVARD", W / 2.0, 96, Color("#3fe0d0"), 1, 30, true)
		_txt(c, "UNE NUIT, DEUX POINGS, UNE VILLE", W / 2.0, 110, Color("#e9e4f5"), 1, 6)
		if int(time * 2.0) % 2 == 0:
			_txt(c, "APPUIE SUR ENTRÉE", W / 2.0, 130, Color("#ffd23f"), 1, 9, true)
		_txt(c, "Flèches/ZQSD : bouger   J/X : coup   K/C : saut   L/V : spécial   P : pause   M : son   F11 : plein écran", W / 2.0, 210, Color(0.8, 0.78, 0.9, 0.8), 1, 4.2)
		return
	if mode == "select":
		_rect(c, 0, 0, W, H, Color(0.03, 0.02, 0.08, 0.3))
		_txt(c, "CHOISIS TON COMBATTANT", W / 2.0, 22, Color.WHITE, 1, 11, true)
		var keys := ["jade", "bruno"]
		for i in 2:
			var h: Dictionary = HEROES[keys[i]]
			var x := W * 0.72 if i == 1 else W * 0.28
			var on := sel == i
			var bc := Color("#ff4f8b") if on else Color(1, 1, 1, 0.18)
			var lw := 1.4 if on else 0.6
			_rect(c, x - 62, 32, 124, lw, bc)
			_rect(c, x - 62, 208 - lw, 124, lw, bc)
			_rect(c, x - 62, 32, lw, 176, bc)
			_rect(c, x + 62 - lw, 32, lw, 176, bc)
			if on:
				_rect(c, x - 62, 32, 124, 176, Color(1, 0.31, 0.55, 0.07))
			_rect(c, x - 62, 166, 124, 42, Color(0.03, 0.02, 0.08, 0.75))
			_txt(c, h.name, x, 179, Color("#ffd23f") if on else Color("#e9e4f5"), 1, 11, true)
			_txt(c, h.blurb, x, 187, Color("#c9c2e0"), 1, 5)
			var labels := ["VITESSE", "FORCE", "PORTÉE"]
			for j in 3:
				_txt(c, labels[j], x - 56, 195.5 + j * 5.5, Color("#9a92b5"), 0, 4)
				for n in 5:
					_rect(c, x + 4 + n * 10, 192 + j * 5.5, 8, 3.2, Color("#3fe0d0") if n < int(h.stat[j]) else Color("#2c2645"))
		if int(time * 2.0) % 2 == 0:
			_txt(c, "← → POUR CHOISIR  ·  ENTRÉE / COUP POUR VALIDER", W / 2.0, 214, Color("#ffd23f"), 1, 5)
		return
	if P == null:
		return
	_rect(c, 0, 0, W, 30, Color(0.03, 0.02, 0.06, 0.55))
	_txt(c, P.h.name, 8, 13, Color("#3fe0d0"), 0, 9, true)
	_bar(c, 8, 16, 110, 6, P.hp / P.maxhp, Color("#ffd23f") if P.hp / P.maxhp > 0.3 else Color("#ff4f8b"))
	_txt(c, "×%d" % lives, 124, 22.5, Color.WHITE, 0, 7, true)
	_txt(c, "%07d" % score, W - 8, 13, Color.WHITE, 2, 9, true)
	_txt(c, "STAGE %d" % (stage_i + 1), W - 8, 24, Color("#9a92b5"), 2, 5)
	var f = last_foe
	if f and last_foe_t > 0 and not f.T.get("boss", false) and not (f.st == "dead" and f.t > 1.0):
		_txt(c, f.ename, 170, 13, Color("#ff8fb5"), 0, 7, true)
		_bar(c, 170, 16, 80, 5, f.hp / f.maxhp, Color("#ff4f8b"))
	for e in enemies:
		if e.T.get("boss", false) and not e.dead:
			_txt(c, e.ename, W / 2.0, H - 13, Color("#ff4f8b"), 1, 7, true)
			_bar(c, W / 2.0 - 90, H - 10, 180, 5, e.hp / e.maxhp, Color("#ff4f8b"))
			break
	for t in texts:
		var sp: Vector2 = cam.unproject_position(Vector3(t.x * S3, t.h * S3, (t.y - 178.0) * S3)) / K
		var col: Color = t.c
		col.a = 1.0 - t.t * 0.8
		_txt(c, t.s, sp.x, sp.y - t.t * 16.0, col, 1, 6, true)
	if go_t > 0 and int(time * 4.0) % 2 == 0:
		_txt(c, "GO ▶", W - 12, 100, Color("#ffd23f"), 2, 12, true)
	if banner:
		var a := minf(1.0, minf(banner.t * 4.0, (banner.dur - banner.t) * 4.0))
		_rect(c, 0, 78, W, 42, Color(0, 0, 0, 0.55 * a))
		var warn: bool = banner.warn
		_txt(c, banner.a, W / 2.0, 95, Color("#ff4f8b" if warn else "#3fe0d0", a), 1, 12 if warn else 8, true)
		_txt(c, banner.b, W / 2.0, 113, Color(1, 1, 1, a), 1, 9 if warn else 13, true)
	match mode:
		"pause":
			_rect(c, 0, 0, W, H, Color(0, 0, 0, 0.55))
			_txt(c, "PAUSE", W / 2.0, 104, Color.WHITE, 1, 18, true)
			_txt(c, "P ou Échap pour reprendre", W / 2.0, 122, Color("#9a92b5"), 1, 6)
		"clear":
			_rect(c, 0, 76, W, 46, Color(0, 0, 0, 0.45))
			_txt(c, "STAGE %d TERMINÉ" % (stage_i + 1), W / 2.0, 96, Color("#3fe0d0"), 1, 12, true)
			_txt(c, "BONUS VIE  %d" % (int(P.hp) * 50), W / 2.0, 112, Color("#ffd23f"), 1, 7, true)
		"over":
			_rect(c, 0, 0, W, H, Color(0.04, 0, 0.04, 0.72))
			_txt(c, "GAME OVER", W / 2.0, 102, Color("#ff4f8b"), 1, 22, true)
			_txt(c, "SCORE %d" % score, W / 2.0, 122, Color.WHITE, 1, 9, true)
			if mode_t > 1.2 and int(time * 2.0) % 2 == 0:
				_txt(c, "ENTRÉE POUR REJOUER", W / 2.0, 150, Color("#9a92b5"), 1, 7)
		"win":
			_rect(c, 0, 0, W, H, Color(0, 0, 0, 0.3))
			_txt(c, "LA VILLE EST SAUVÉE", W / 2.0, 40, Color("#3fe0d0"), 1, 14, true)
			_txt(c, "FÉLICITATIONS, " + str(P.h.name), W / 2.0, 58, Color.WHITE, 1, 8, true)
			_txt(c, "SCORE FINAL %d" % score, W / 2.0, 76, Color("#ffd23f"), 1, 11, true)
			if mode_t > 1.2 and int(time * 2.0) % 2 == 0:
				_txt(c, "ENTRÉE POUR REJOUER", W / 2.0, 206, Color("#9a92b5"), 1, 6)
