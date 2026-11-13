class_name DealerDlg
extends RefCounted
static var last := ""
var g: Node
var d: Dictionary
var ui: Droid
var name := ""
var arr: Array = []
var deal := {"text": "", "weed": 0, "cash": 0, "price": 0, "tol": 0}
func _init(game: Node) -> void:
	g = game
	var nm := "dealer_sw600dp"
	d = g.dialog(nm if Assets.layout(nm) is Dictionary and Assets.layout(nm).has("tag") else "dealer")
	d["w"].set_meta("owner", self)
	ui = d["ui"]
	Sfx.play("door_open")
	var pick := ["mr_canabini", "big_roy"]
	name = pick[randi() % 2]
	if name == last: name = pick[(pick.find(name) + 1) % 2]
	last = name
	arr = Assets.arrays.get(name, [])
	var s: String = arr[1 + randi() % 3]
	var bar := s.find("|")
	var eq := s.find("=")
	var tl := s.find("~")
	deal = {"text": s.substr(0, bar), "weed": int(s.substr(bar + 1, eq - bar - 1)), "price": int(s.substr(eq + 1, tl - eq - 1)), "tol": int(s.substr(tl + 1)), "cash": 0}
	deal["cash"] = deal["price"] * deal["weed"]
	ui.view("name").set_text(arr[0])
	ui.view("photo").set_src(Assets.drawable("@drawable/photo_%s_0" % name))
	set_tell(deal["text"])
	for id in ["photo", "btn_deal", "btn_hangup", "slider"]: ui.view(id).set_vis(0)
	for id in ["bonus_xp", "bonus_cash", "bonus_weed", "hint_back"]: ui.view(id).set_vis(2)
	var sl := ui.view("slider")
	sl.enabled = true
	sl.progress = 0
	ui.on_seek[sl] = func(v): price_changed(v.progress)
	price_changed(0)
	ui.view("deal_weed").set_text("%d weed" % deal["weed"])
	ui.on("btn_hangup", hangup)
	ui.on("btn_deal", do_deal)
	g.L("phone_answer")
func set_tell(t: String) -> void:
	ui.view("tell").set_text(t)
	Anim.play(ui.view("tell"), "client_text_in", func():
		if deal["weed"] != 0 and deal["cash"] == -1:
			ui.view("btn_deal").set_vis(0)
			deal["cash"] = deal["price"] * deal["weed"])
func price_changed(p: int) -> void:
	ui.view("deal_price").set_text("%d cash" % p)
	ui.view("deal_cash").set_text("%d cash" % (p * deal["weed"]))
func close() -> void: g.close_dialog(d)
func hangup(btn) -> void:
	Sfx.play("tap")
	Sfx.play("phone_hangup")
	btn.set_vis(2)
	Anim.play(ui.view("tell"), "client_text_out")
	Anim.play(ui.view("photo"), "piss_off", close)
func pick_text(a: int, b: int, c: int) -> String: return arr[[a, b, c][randi() % 3]]
func do_deal(btn) -> void:
	Sfx.play("tap")
	var xp: int = Sfx.theme_mult() * (4 if Save.bool_of("sofa") else 2)
	var p: int = ui.view("slider").progress
	var w: int = deal["weed"]
	var cash := p * w
	if not g.m(xp, cash, -w): return
	btn.set_vis(1)
	if p > deal["price"]:
		g.m(-xp, -cash, w)
		if p > deal["price"] + deal["tol"]:
			deal["text"] = pick_text(10, 11, 12)
			ui.view("slider").set_vis(2)
		else:
			deal["text"] = pick_text(4, 5, 6)
			deal["cash"] = -1
			g.L("phone_discount")
		Anim.play(ui.view("tell"), "client_text_out")
		g.after(1.0, func(): set_tell(deal["text"]))
	else:
		Sfx.play("phone_deal")
		deal["text"] = pick_text(7, 8, 9)
		ui.view("slider").set_vis(2)
		ui.view("slider").enabled = false
		Anim.play(ui.view("tell"), "client_text_out")
		g.after(1.0, func(): set_tell(deal["text"]))
		g.after(2.0, func():
			var bx := ui.view("bonus_xp")
			var bc := ui.view("bonus_cash")
			var bw := ui.view("bonus_weed")
			bx.set_text("+%d xp" % xp)
			bc.set_text("+%d cash" % cash)
			bw.set_text("-%d weed" % w)
			for b in [bx, bc, bw]: b.set_vis(0)
			Anim.play(ui.view("bonus_holder"), "bonus", func():
				for b in [bx, bc, bw]: b.set_vis(2))
			var l := ui.view("sell_left_hand")
			var r := ui.view("sell_right_hand")
			var c := ui.view("sell_dealer_cash")
			var hs := ui.view("sell_dealer_hash")
			for x in [l, r, c, hs]: x.set_vis(0)
			Anim.play(l, "sell_left_hand")
			Anim.play(r, "sell_right_hand")
			Anim.play(hs, "sell_hash")
			Anim.play(c, "sell_cash", func():
				for x in [l, r, c, hs]: x.set_vis(2)))
		g.L("phone_deal")
		g.after(3.5, func(): g.after(1.0, close))
	g.after(1.0, func(): g.desk())
