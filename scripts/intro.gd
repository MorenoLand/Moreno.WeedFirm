class_name IntroDlg
extends RefCounted
const W := 1600.0
var g: Node
var d: Dictionary
var ui: Droid
var done: Callable
func _init(game: Node, finished: Callable) -> void:
	g = game
	done = finished
	d = g.dialog("comix_intro_sw600dp", false)
	ui = d["ui"]
	g.modal += 0
	for id in ["comix_intro_0_mouth", "comix_intro_0_text", "comix_intro_0_expeled", "next_1", "play"]: ui.view(id).set_vis(2)
	ui.on("start", start)
	ui.on("next_1", next1)
	ui.on("play", play)
func trk(kind: String, a: Dictionary, off: float, dur: float, ip := "", fa := true) -> Dictionary: return {"type": kind, "a": a, "off": off, "dur": dur, "ip": ip, "fa": fa}
func tx(from: float, off: float, dur: float, ip := "") -> Dictionary: return trk("translate", {"fromXDelta": from, "toXDelta": 0.0, "fromYDelta": 0.0, "toYDelta": 0.0}, off, dur, ip)
func alpha(from: float, to: float, off: float, dur: float) -> Dictionary: return trk("alpha", {"fromAlpha": from, "toAlpha": to}, off, dur)
func v(id: String) -> AView: return ui.view(id)
func start(btn) -> void:
	Sfx.play("tap")
	btn.set_vis(2)
	v("comix_intro_0_logo").set_vis(2)
	g.after(1.0, speech)
func speech() -> void:
	var m := v("comix_intro_0_mouth")
	m.set_vis(0)
	Anim.play_tracks(m, [alpha(0.0, 1.0, 0.0, 1500.0)])
	var t := v("comix_intro_0_text")
	t.set_vis(0)
	var tracks: Array = []
	for x in Anim.load_anim("client_text_in"):
		var c: Dictionary = x.duplicate()
		c["off"] = float(c["off"]) + 2000.0
		tracks.append(c)
	Anim.play_tracks(t, tracks)
	var e := v("comix_intro_0_expeled")
	e.set_vis(0)
	Anim.play_tracks(e, [trk("scale", {"fromXScale": 50.0, "toXScale": 1.0, "fromYScale": 50.0, "toYScale": 1.0, "pivotX": "0%", "pivotY": "0%"}, 4000.0, 1000.0), trk("translate", {"fromXDelta": 0.0, "toXDelta": 0.0, "fromYDelta": 960.0, "toYDelta": 0.0}, 4000.0, 1000.0)])
	g.after(6.0, func(): v("next_1").set_vis(0))
func next1(btn) -> void:
	Sfx.play("tap")
	btn.set_vis(2)
	Anim.play_tracks(v("comix_intro_0"), [alpha(1.0, 0.0, 1000.0, 2000.0)])
	g.after(4.0, panel1)
	g.after(14.0, panel2)
	g.after(22.0, panel3)
func panel1() -> void:
	Sfx.play("tap")
	v("comix_intro_1").set_vis(0)
	Anim.play_tracks(v("comix_intro_1_top"), [tx(W + 80.0, 0.0, 2000.0)])
	Anim.play_tracks(v("comix_intro_1_dark"), [alpha(0.0, 1.0, 3000.0, 1000.0)])
	Anim.play_tracks(v("comix_intro_1_bottom"), [tx(W, 5000.0, 1000.0, "0x010a0006")])
	Anim.play_tracks(v("comix_intro_1_man"), [tx(W, 6000.0, 1000.0, "0x010a0006")])
	Anim.play_tracks(v("comix_intro_1_chat"), [tx(-W, 7000.0, 1000.0, "0x010a0006")])
func panel2() -> void:
	Sfx.play("tap")
	v("comix_intro_2").set_vis(0)
	Anim.play_tracks(v("comix_intro_2_top"), [tx(W + 80.0, 0.0, 2000.0)])
	Anim.play_tracks(v("comix_intro_2_ted"), [tx(-W, 3000.0, 1000.0, "0x010a0006")])
	Anim.play_tracks(v("comix_intro_2_bot"), [tx(W, 5000.0, 1000.0, "0x010a0006")])
func panel3() -> void:
	Sfx.play("tap")
	v("comix_intro_3").set_vis(0)
	Anim.play_tracks(v("comix_intro_3_bg"), [tx(W + 80.0, 0.0, 2000.0)])
	Anim.play_tracks(v("comix_intro_3_left"), [tx(-W, 3000.0, 1000.0, "0x010a0006")])
	Anim.play_tracks(v("comix_intro_3_right"), [tx(W, 5000.0, 1000.0, "0x010a0006")])
	g.after(6.0, func(): v("play").set_vis(0))
func play(btn) -> void:
	btn.set_vis(2)
	Save.put("intro_showed", true)
	g.close_dialog(d)
	if done.is_valid(): done.call()
