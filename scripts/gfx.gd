class_name Gfx
extends Node
## Rendu : niveaux de qualité (F2), brouillard volumétrique, néons qui grésillent,
## éclaboussures de pluie, gouttes sur l'objectif, post-effets caméra (vignette, grain,
## aberration chromatique), mode CRT rétro (F3) et flou de profondeur sur le décor lointain.
## Les réglages sont sauvegardés dans user://reglages.cfg.

const LEVELS := ["BAS", "MOYEN", "HAUT", "ULTRA"]
const CFG := "user://reglages.cfg"

var level := 2
var crt := false
var game = null
var post: ColorRect
var post_mat: ShaderMaterial
var splash: GPUParticles3D
var cam_attr: CameraAttributesPractical
var stage: Dictionary = {}
var neons: Array = []
var toast := ""
var toast_t := 0.0


func setup(g) -> void:
	game = g
	_load()
	var layer := CanvasLayer.new()
	layer.layer = 5  # au-dessus du HUD : le mode CRT s'applique à toute l'image
	add_child(layer)
	post = ColorRect.new()
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_mat = ShaderMaterial.new()
	post_mat.shader = _post_shader()
	post.material = post_mat
	layer.add_child(post)
	cam_attr = CameraAttributesPractical.new()
	game.cam.attributes = cam_attr
	splash = _make_splash()
	game.add_child(splash)
	apply()


func cycle_level() -> void:
	level = (level + 1) % LEVELS.size()
	apply()
	_save()
	_toast("QUALITÉ : " + LEVELS[level])


func toggle_crt() -> void:
	crt = not crt
	apply()
	_save()
	_toast("ÉCRAN CRT : " + ("OUI" if crt else "NON"))


func _toast(s: String) -> void:
	toast = s
	toast_t = 1.6


## Appelé à chaque changement de décor
func on_stage(B: Dictionary) -> void:
	stage = B
	neons = B.get("neons", [])
	for n in neons:
		n["t"] = randf_range(1.0, 8.0)
		n["f"] = 0.0
	apply()


func apply() -> void:
	var vp: Viewport = game.get_viewport()
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][level]
	vp.screen_space_aa = [Viewport.SCREEN_SPACE_AA_DISABLED, Viewport.SCREEN_SPACE_AA_FXAA, Viewport.SCREEN_SPACE_AA_SMAA, Viewport.SCREEN_SPACE_AA_SMAA][level]
	# en BAS, l'image 3D est calculée plus petite puis agrandie avec FSR
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if level == 0 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = 0.77 if level == 0 else 1.0
	RenderingServer.directional_soft_shadow_filter_set_quality([RenderingServer.SHADOW_QUALITY_HARD,
		RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM,
		RenderingServer.SHADOW_QUALITY_SOFT_HIGH][level])
	RenderingServer.directional_shadow_atlas_set_size([1024, 2048, 4096, 8192][level], true)
	game.sun.shadow_enabled = level >= 1
	game.sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if level == 1 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	game.rain.amount = [700, 1400, 2200, 3000][level]
	for k in game.built:
		_apply_env(game.built[k])
	cam_attr.dof_blur_far_enabled = level >= 2
	cam_attr.dof_blur_far_distance = 62.0
	cam_attr.dof_blur_far_transition = 35.0
	cam_attr.dof_blur_amount = 0.06 if level == 2 else 0.09
	var raining: bool = stage.get("rain", false)
	splash.emitting = raining and level >= 1
	splash.visible = splash.emitting
	splash.amount = [60, 140, 260, 420][level]
	post.visible = level >= 1 or crt
	post_mat.set_shader_parameter("vignette", 0.0 if level == 0 else 0.38)
	post_mat.set_shader_parameter("grain", 0.035 if level >= 2 else 0.0)
	post_mat.set_shader_parameter("aberration", 0.0011 if level >= 2 else 0.0)
	post_mat.set_shader_parameter("drops", 1.0 if raining and level >= 3 else 0.0)
	post_mat.set_shader_parameter("crt", crt)


func _apply_env(B: Dictionary) -> void:
	var env: Environment = B.env
	env.glow_enabled = level >= 1
	env.ssao_enabled = level >= 2
	env.ssr_enabled = level >= 2
	env.ssr_max_steps = 48 if level == 2 else 96
	env.ssil_enabled = level >= 3
	env.ssao_intensity = 1.6
	# étalonnage : un peu plus de contraste et de saturation pour l'ambiance néon
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = 1.14
	var vf: Dictionary = B.get("vfog", {})
	env.volumetric_fog_enabled = level >= 2 and not vf.is_empty()
	if not vf.is_empty():
		env.volumetric_fog_density = vf.get("density", 0.02)
		env.volumetric_fog_albedo = vf.get("albedo", Color(0.8, 0.8, 0.9))
		env.volumetric_fog_emission = vf.get("emission", Color(0.02, 0.01, 0.04))
		env.volumetric_fog_emission_energy = 1.0
		env.volumetric_fog_anisotropy = 0.55
		env.volumetric_fog_length = 80.0
		env.volumetric_fog_detail_spread = 1.6
		env.volumetric_fog_sky_affect = 0.25
		env.volumetric_fog_temporal_reprojection_enabled = true
		# le brouillard classique fait doublon quand le volumétrique est actif
		if not B.has("fog_base"):
			B["fog_base"] = env.fog_density
		env.fog_density = float(B.fog_base) * (0.4 if env.volumetric_fog_enabled else 1.0)


func update(dt: float, cx: float) -> void:
	if toast_t > 0.0:
		toast_t -= dt
	splash.position = Vector3(cx, 0.03, 3.5)
	post_mat.set_shader_parameter("res", game.get_viewport().get_visible_rect().size)
	# néons fatigués : de temps en temps une enseigne grésille ou s'éteint une seconde
	for n in neons:
		n.t -= dt
		if n.t <= 0.0 and n.f <= 0.0:
			n.f = randf_range(0.25, 1.1)
			n.t = randf_range(3.0, 14.0)
		var on := 1.0
		if n.f > 0.0:
			n.f -= dt
			on = 0.12 if randf() < 0.55 else 1.0
		if n.get("on", 1.0) != on:
			n["on"] = on
			for l in n.lights:
				l.light_energy = float(l.get_meta("e0")) * on
			for m in n.mats:
				m.emission_energy_multiplier = float(m.get_meta("e0")) * on
			for lb in n.labels:
				lb.modulate.a = 0.25 + 0.75 * on
				lb.outline_modulate.a = 0.85 * on


func _make_splash() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 260
	p.lifetime = 0.32
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(22, 0, 9)
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.15))
	sc.add_point(Vector2(1, 1.0))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.7))
	g.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q := PlaneMesh.new()
	q.size = Vector2(0.42, 0.42)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = game.ring_tex
	m.albedo_color = Color(0.75, 0.82, 1.0, 0.55)
	q.material = m
	p.draw_pass_1 = q
	p.visibility_aabb = AABB(Vector3(-30, -2, -14), Vector3(60, 4, 28))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


func _post_shader() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette = 0.38;
uniform float grain = 0.0;
uniform float aberration = 0.0;
uniform float drops = 0.0;
uniform bool crt = false;
uniform vec2 res = vec2(1600.0, 900.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

// gouttes de pluie sur l'objectif : elles apparaissent, glissent un peu et s'évaporent
vec2 drop_offset(vec2 uv, out float rim) {
	rim = 0.0;
	vec2 o = vec2(0.0);
	for (int layer = 0; layer < 2; layer++) {
		float sc = layer == 0 ? 9.0 : 16.0;
		vec2 g = uv * vec2(sc * res.x / res.y, sc);
		g.y += TIME * (0.05 + 0.04 * float(layer));
		vec2 id = floor(g);
		vec2 f = fract(g) - 0.5;
		float h = hash(id + float(layer) * 17.0);
		if (h > 0.1) continue;
		float life = fract(TIME * 0.12 + h * 7.0);
		vec2 c = vec2(hash(id + 1.3) - 0.5, hash(id + 2.7) - 0.5) * 0.5;
		vec2 d = (f - c) * vec2(1.0, 1.3);
		float r = length(d);
		float size = 0.2 * smoothstep(0.0, 0.1, life) * (1.0 - smoothstep(0.7, 1.0, life));
		float m = smoothstep(size, size * 0.6, r);
		o += d * m * 0.16 / sc;
		rim += smoothstep(size * 0.55, size, r) * m;
	}
	return o;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 cc0 = uv - 0.5;
	if (crt) {
		uv = 0.5 + cc0 * (1.0 + 0.09 * dot(cc0, cc0));
	}
	float rim = 0.0;
	if (drops > 0.0) {
		uv += drop_offset(SCREEN_UV, rim) * drops;
	}
	vec2 cc = uv - 0.5;
	float d2 = dot(cc, cc);
	vec3 col;
	if (aberration > 0.0) {
		vec2 a = cc * aberration * d2 * 8.0;
		col = vec3(texture(screen_tex, uv + a).r, texture(screen_tex, uv).g, texture(screen_tex, uv - a).b);
	} else {
		col = texture(screen_tex, uv).rgb;
	}
	col += vec3(0.03, 0.035, 0.05) * rim * drops;
	col *= 1.0 - vignette * smoothstep(0.08, 0.5, d2);
	if (grain > 0.0) {
		col += (hash(SCREEN_UV * res + fract(TIME * 7.3) * 91.7) - 0.5) * grain;
	}
	if (crt) {
		float s = 0.5 + 0.5 * sin(SCREEN_UV.y * res.y * 3.14159);
		col *= 0.78 + 0.22 * s;
		int px = int(SCREEN_UV.x * res.x) % 3;
		col *= px == 0 ? vec3(1.08, 0.94, 0.94) : (px == 1 ? vec3(0.94, 1.08, 0.94) : vec3(0.94, 0.94, 1.08));
		col *= 1.12;
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			col = vec3(0.0);
		}
	}
	COLOR = vec4(col, 1.0);
}
"""
	return sh


func _load() -> void:
	var c := ConfigFile.new()
	if c.load(CFG) == OK:
		level = clampi(int(c.get_value("gfx", "qualite", 2)), 0, LEVELS.size() - 1)
		crt = bool(c.get_value("gfx", "crt", false))


func _save() -> void:
	var c := ConfigFile.new()
	c.load(CFG)
	c.set_value("gfx", "qualite", level)
	c.set_value("gfx", "crt", crt)
	c.save(CFG)
