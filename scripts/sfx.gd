class_name Sfx
extends Node
## Bruitages et musique synthétisés au lancement (aucun fichier audio nécessaire).

const RATE := 22050
var players: Array = []
var bank := {}
var idx := 0
var muted := false
var music: AudioStreamPlayer


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		players.append(p)
	bank = {
		"hit": _wav(_mix([_noise(0.09, 0.55, 0.35), _tone(180, 60, 0.08, 0.25, "square")])),
		"heavy": _wav(_mix([_noise(0.16, 0.7, 0.18), _tone(120, 40, 0.15, 0.35, "square")])),
		"swing": _wav(_noise(0.07, 0.18, 0.75)),
		"jump": _wav(_tone(220, 520, 0.12, 0.12, "square")),
		"land": _wav(_noise(0.06, 0.3, 0.08)),
		"pick": _wav(_mix([_tone(660, 660, 0.07, 0.12, "square"), _tone(880, 880, 0.07, 0.12, "square", 0.06), _tone(1320, 1320, 0.09, 0.12, "square", 0.12)])),
		"break": _wav(_mix([_noise(0.22, 0.5, 0.3), _tone(300, 90, 0.15, 0.18, "tri")])),
		"ko": _wav(_tone(400, 60, 0.45, 0.2, "saw")),
		"hurt": _wav(_mix([_tone(300, 120, 0.15, 0.2, "saw"), _noise(0.08, 0.35, 0.35)])),
		"sel": _wav(_tone(880, 880, 0.05, 0.1, "square")),
		"go": _wav(_mix([_tone(523, 523, 0.08, 0.12, "square"), _tone(784, 784, 0.12, 0.12, "square", 0.09)])),
		"warn": _wav(_mix([_tone(110, 110, 0.25, 0.2, "saw"), _tone(110, 110, 0.25, 0.2, "saw", 0.35)])),
		"stomp": _wav(_mix([_noise(0.35, 0.8, 0.05), _tone(80, 30, 0.35, 0.6, "sine")])),
	}
	music = AudioStreamPlayer.new()
	music.volume_db = -9.0
	add_child(music)
	music.stream = _music()


func play(n: String) -> void:
	if muted or not bank.has(n):
		return
	var p: AudioStreamPlayer = players[idx]
	idx = (idx + 1) % players.size()
	p.stream = bank[n]
	p.play()


func set_music(on: bool) -> void:
	if on and not muted:
		if not music.playing:
			music.play()
	else:
		music.stop()


func toggle_mute() -> void:
	muted = not muted
	if muted:
		music.stop()


func _tone(f1: float, f2: float, dur: float, vol: float, kind := "square", delay := 0.0) -> PackedFloat32Array:
	var n := int((dur + delay) * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE - delay
		if t < 0.0:
			a[i] = 0.0
			continue
		var f := f1 * pow(f2 / f1, t / dur)
		ph += f / RATE
		var fr := fmod(ph, 1.0)
		var s := 0.0
		match kind:
			"square":
				s = 1.0 if fr < 0.5 else -1.0
			"saw":
				s = fr * 2.0 - 1.0
			"tri":
				s = absf(fr * 4.0 - 2.0) - 1.0
			_:
				s = sin(ph * TAU)
		a[i] = s * vol * exp(-t / dur * 4.0)
	return a


func _noise(dur: float, vol: float, smooth: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		y += (randf() * 2.0 - 1.0 - y) * smooth
		a[i] = y * vol * exp(-t / dur * 4.0) * 1.5
	return a


func _mix(list: Array) -> PackedFloat32Array:
	var n := 0
	for a in list:
		n = maxi(n, a.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for a in list:
		for i in a.size():
			out[i] += a[i]
	return out


func _wav(a: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(a.size() * 2)
	for i in a.size():
		bytes.encode_s16(i * 2, int(clampf(a[i], -1.0, 1.0) * 32000.0))
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = a.size()
	return w


func _music() -> AudioStreamWAV:
	var bass := [45, 45, 57, 45, 48, 48, 43, 43, 45, 45, 57, 45, 52, 50, 48, 47]
	var spb := 60.0 / 128.0 / 2.0
	var steps := 32
	var n := int(spb * steps * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var step_len := int(spb * RATE)
	for s in steps:
		var note: int = bass[s % 16]
		var f := 440.0 * pow(2.0, (note - 69) / 12.0)
		var o := s * step_len
		var ph := 0.0
		var lp := 0.0
		var hp := 0.0
		for i in step_len:
			var t := float(i) / RATE
			ph += f / RATE
			var saw := fmod(ph, 1.0) * 2.0 - 1.0
			var cut := 0.02 + 0.25 * exp(-t * 9.0)
			lp += (saw - lp) * cut
			var v := lp * 0.32 * exp(-t * 2.2)
			if s % 4 == 0:
				v += sin(TAU * (40.0 + 80.0 * exp(-t * 30.0)) * t) * 0.55 * exp(-t * 14.0)
			if s % 2 == 1 and t < 0.05:
				var r := randf() * 2.0 - 1.0
				hp += (r - hp) * 0.5
				v += (r - hp) * 0.12 * exp(-t * 60.0)
			if s % 8 == 4 and t < 0.18:
				v += (randf() * 2.0 - 1.0) * 0.22 * exp(-t * 18.0)
			out[o + i] = v
	return _wav(out, true)
