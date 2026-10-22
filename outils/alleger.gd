extends SceneTree
## Allège un modèle 3D riggé (GLB/FBX) : textures réduites (MAX px, WebP), animations retirées,
## matériaux « tout métal » sans texture de métal corrigés. Le squelette et la géométrie sont gardés.
##
## Usage (dans le projet, depuis un terminal) :
##   godot --headless --script res://outils/alleger.gd -- res://chemin/perso.glb res://models/perso_leger.glb [1024]

var cache := {}
var max_px := 1024


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 2:
		print("usage : -- source.glb sortie.glb [taille max des textures]")
		quit()
		return
	if a.size() > 2:
		max_px = int(a[2])
	var root: Node3D = (load(a[0]) as PackedScene).instantiate()
	for ap in root.find_children("*", "AnimationPlayer", true, false):
		ap.get_parent().remove_child(ap)
		ap.free()
	var n_tex := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		for si in mesh.get_surface_count():
			var m = mi.get_active_material(si)
			if not (m is StandardMaterial3D):
				continue
			var d: StandardMaterial3D = m.duplicate()
			for prop in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "ao_texture", "emission_texture"]:
				var t = d.get(prop)
				if t is Texture2D:
					d.set(prop, _small(t))
					n_tex += 1
			if d.metallic > 0.9 and d.metallic_texture == null:
				d.metallic = 0.0
			mesh.surface_set_material(si, d)
			mi.set_surface_override_material(si, null)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(a[1].get_base_dir()))
	var doc := GLTFDocument.new()
	doc.image_format = "Lossy WebP"
	doc.lossy_quality = 0.85
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, a[1])
	print("%d textures réduites, export %s : %s" % [n_tex, a[1], "OK" if err == OK else str(err)])
	quit()


func _small(t: Texture2D) -> Texture2D:
	if cache.has(t):
		return cache[t]
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	var s := minf(1.0, float(max_px) / maxf(img.get_width(), img.get_height()))
	if s < 1.0:
		img.resize(maxi(1, int(img.get_width() * s)), maxi(1, int(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	var nt := ImageTexture.create_from_image(img)
	nt.resource_name = t.resource_name
	cache[t] = nt
	return nt
