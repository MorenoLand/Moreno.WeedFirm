class_name Comix
extends RefCounted
var g: Node
var d: Dictionary
var ui: Droid
func _init(game: Node, layout: String, sound: String, steps: Array, bonus: Array, bonus_sound: String, intro_done := Callable()) -> void:
	g = game
	var nm := layout + "_sw600dp"
	d = g.dialog(nm if Assets.layout(nm) is Dictionary and Assets.layout(nm).has("tag") else layout, false)
	d["w"].set_meta("owner", self)
	ui = d["ui"]
	Sfx.play(sound)
	var back := ui.view("back")
	if back != null:
		back.set_vis(2)
		ui.on("back", func(_v):
			Sfx.play("tap")
			g.close_dialog(d)
			if intro_done.is_valid(): intro_done.call())
	var last := 0.0
	var last_view: AView = null
	for s in steps:
		var v := ui.view(s[0])
		if v == null: continue
		var tr := {"type": "translate" if s[1] == "t" else "alpha", "a": {}, "off": s[5], "dur": s[4], "ip": "0x010a0009", "fa": true}
		if s[1] == "t":
			var yy: float = s[6] if s.size() > 6 else 0.0
			tr["a"] = {"fromXDelta": s[2], "toXDelta": s[3], "fromYDelta": yy, "toYDelta": yy}
		else:
			tr["a"] = {"fromAlpha": s[2], "toAlpha": s[3]}
		var end: float = s[4] + s[5]
		var is_last := end >= last
		if is_last:
			last = end
			last_view = v
		Anim.play_tracks(v, [tr], Callable() if not is_last else Callable(self, "finish"))
	if last_view == null: finish()
	for id in ["bonus_xp", "bonus_cash", "bonus_weed"]:
		var b := ui.view(id)
		if b != null: b.set_vis(2)
	bonus_vals = bonus
	bonus_snd = bonus_sound
var bonus_vals: Array = []
var bonus_snd := ""
func finish() -> void:
	var back := ui.view("back")
	if back != null: back.set_vis(0)
	var bh := ui.view("bonus_holder")
	if bh != null and not bonus_vals.is_empty():
		var ids := ["bonus_cash", "bonus_weed", "bonus_xp"]
		if bonus_vals.size() == 3 and str(bonus_vals[0]).ends_with("xp"): ids = ["bonus_xp", "bonus_cash", "bonus_weed"]
		for i in bonus_vals.size():
			var b := ui.view(ids[i])
			if b != null and str(bonus_vals[i]) != "":
				b.set_text(str(bonus_vals[i]))
				b.set_vis(0)
		if bonus_snd != "": Sfx.play(bonus_snd)
		bh.set_vis(0)
		Anim.play(bh, "bonus", func(): bh.set_vis(2))
