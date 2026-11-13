class_name ClientDlg
extends RefCounted
const BUY := {"ian": ["player", "btn_buyaplayer", 6, "buy_a_player", 4000, 2000], "ryan": ["box", "btn_buyabox", 6, "buy_a_box", 2000, 1500], "lee": ["safe", "btn_buyasafe", 5, "buy_a_safe", 10000, 6000], "bob": ["bong", "btn_buyabong", 7, "buy_a_bong", 20000, 15000], "naomi": ["vaporizer", "btn_buyavaporizer", 13, "buy_a_vaporizer", 80000, 16000], "nancy": ["sofa", "btn_buyasofa", 9, "buy_a_sofa", 40000, 30000], "sandy": ["panties", "btn_buyapanties", 15, "buy_a_panties", 5000, 4000], "mike": ["shotgun", "btn_buyashotgun", 10, "buy_a_shotgun", 70000, 49000], "mary": ["painting", "btn_buyapainting", 11, "buy_a_painting", 7000, 3500], "aaron": ["phone", "btn_buyaphone", 16, "buy_a_phone", 100000, 100000]}
const BTNS := ["btn_pay", "btn_trade", "btn_trick", "btn_buyaplayer", "btn_buyabox", "btn_buyasafe", "btn_buyabong", "btn_buyavaporizer", "btn_buyasofa", "btn_buyapanties", "btn_buyashotgun", "btn_buyapainting", "btn_buyaphone", "btn_shoot", "btn_warp", "btn_christmas", "btn_dice", "btn_valentine", "btn_gift"]
var g: Node
var d: Dictionary
var ui: Droid
var name := ""
var arr: Array = []
var deal := {"text": "", "weed": 0, "cash": 0}
var price := 0
var busy := false
func _init(game: Node, client: String) -> void:
	g = game
	name = client
	d = g.dialog("client_sw600dp" if Assets.layout("client_sw600dp") is Dictionary and Assets.layout("client_sw600dp").has("tag") else "client")
	ui = d["ui"]
	Sfx.play("door_open")
	arr = Assets.arrays.get(name, [])
	ui.on("btn_pissoff", pissoff)
	ui.on("btn_rollajoint", func(_v): smoke(1, "roll", 7.0))
	ui.on("btn_smokeabong", func(_v): smoke(2, "bong", 4.0))
	ui.on("btn_vaporize", func(_v): smoke(3, "vaporize", 4.0))
	ui.on("btn_sell", sell)
	ui.on("btn_pay", pay)
	ui.on("btn_trade", trade)
	ui.on("btn_trick", trick)
	ui.on("btn_shoot", shoot)
	ui.on("btn_warp", func(_v):
		ui.view("hint_back").set_vis(2)
		g.close_dialog(d)
		g.open_warp())
	ui.on("btn_christmas", func(v): bonus_gift(v, "christmas_bonus"))
	ui.on("btn_valentine", func(v): bonus_gift(v, "valentine_bonus"))
	ui.on("btn_dice", dice)
	ui.on("btn_gift", func(v):
		v.set_vis(2)
		g.popup_item("gift"))
	for id in BTNS:
		if id.begins_with("btn_buya"): ui.on(id, buy)
	ui.on("hint_back", func(_v): ui.view("hint_back").set_vis(2))
	setup()
func v(id: String) -> AView: return ui.view(id)
func gen_deal() -> void:
	var lvl: int = g.level()
	if name == "jesus_jhamal": deal = parse(arr[randi() % 6 + 2], 0, lvl * 300)
	elif name == "mr_malone": deal = parse(arr[randi() % 4 + 2], 0, lvl * 500)
	elif name == "alien": deal = parse(arr[randi() % 5 + 2], g.weed_amt(), g.weed_amt() / 3)
	elif name == "zombie": deal = parse(arr[randi() % 7 + 2], lvl, 0)
	else:
		var pool := []
		for i in range(2, 9): pool.append(arr[i])
		var ex := [["customize_0", 9], ["customize_1", 11], ["customize_2", 13], ["customize_3", 15]]
		for e in ex:
			if Save.bool_of(e[0]):
				pool.append(arr[e[1]])
				pool.append(arr[e[1] + 1])
		deal = split(pool[randi() % pool.size()])
func split(s: String) -> Dictionary:
	var bar := s.find("|")
	var eq := s.find("=")
	return {"text": s.substr(0, bar), "weed": int(s.substr(bar + 1, eq - bar - 1)), "cash": int(s.substr(eq + 1))}
func parse(s: String, w: int, c: int) -> Dictionary: return {"text": s, "weed": w, "cash": c}
func set_price() -> void:
	if BUY.has(name): price = BUY[name][4]
	elif name == "ultimator": price = 10000
func setup() -> void:
	gen_deal()
	set_price()
	v("name").set_text(arr[0])
	v("photo").set_src(Assets.drawable("@drawable/photo_%s_0" % name))
	show_deal()
	for id in ["shoot_gun", "shoot_fire", "smoke", "bonus_xp", "bonus_cash", "bonus_weed", "btn_pay", "btn_trade", "btn_trick", "btn_buyaplayer", "btn_buyabox", "btn_buyasafe", "btn_buyabong", "btn_buyavaporizer", "btn_buyasofa", "btn_buyapanties", "btn_buyashotgun", "btn_buyapainting", "btn_buyaphone", "btn_shoot", "btn_warp", "btn_christmas", "btn_dice", "btn_valentine", "btn_gift"]: v(id).set_vis(2)
	v("photo").set_vis(0)
	v("btn_pissoff").set_vis(0)
	v("btn_rollajoint").set_vis(0)
	v("btn_sell").set_vis(0)
	for id in ["btn_christmas", "btn_dice", "btn_valentine", "btn_gift"]: v(id).set_enabled(true)
	v("btn_smokeabong").set_vis(0 if Save.bool_of("bong") else 2)
	v("btn_vaporize").set_vis(0 if Save.bool_of("vaporizer") else 2)
	if name != "maid": g.gift_taken = false
	actions()
func show_deal() -> void:
	v("tell").set_text(deal["text"])
	Anim.play(v("tell"), "client_text_in")
	v("deal_weed").set_text("%d weed" % deal["weed"])
	v("deal_cash").set_text("%d cash" % deal["cash"])
	if name == "alien":
		v("deal_xp").set_vis(0)
		v("deal_cash").set_vis(2)
		v("deal_xp").set_text("%d xp" % deal["cash"])
	else:
		v("deal_xp").set_vis(2)
		v("deal_cash").set_vis(0)
	v("deal").set_vis(1 if deal["weed"] == 0 or name == "zombie" else 0)
	v("btn_holder").set_vis(1 if deal["cash"] == 0 and name != "zombie" else 0)
func actions() -> void:
	if name == "santa": v("btn_christmas").set_vis(0)
	if name == "cupid": v("btn_valentine").set_vis(0)
	if name == "ex": v("btn_dice").set_vis(0)
	if name == "jesus_jhamal" or name == "mr_malone":
		price = deal["cash"]
		for id in ["btn_rollajoint", "btn_smokeabong", "btn_vaporize", "btn_sell"]: v(id).set_vis(2)
		v("btn_pay").set_vis(0)
		v("btn_pay").set_text(Assets.str_of("pay", [price]))
	if name == "jesus_jhamal" and Save.bool_of("shotgun"): v("btn_shoot").set_vis(0)
	if name == "alien":
		for id in ["btn_rollajoint", "btn_smokeabong", "btn_vaporize", "btn_sell"]: v(id).set_vis(2)
		v("btn_trade").set_vis(0)
		v("btn_warp").set_vis(2 if g.level() == 17 else 0)
	if name == "zombie":
		price = deal["weed"]
		for id in ["btn_rollajoint", "btn_smokeabong", "btn_vaporize", "btn_sell"]: v(id).set_vis(2)
		v("btn_trick").set_vis(0)
		v("btn_trick").set_text(Assets.str_of("trick", [price]))
	if BUY.has(name):
		var b: Array = BUY[name]
		if not Save.bool_of(b[0]):
			var btn := v("btn_buya" + b[0])
			btn.set_vis(0)
			if g.level() < b[2]:
				btn.set_text(Assets.str_of("level_required", [b[2]]))
				btn.set_enabled(false)
			else:
				btn.set_text(Assets.str_of(b[3], [price]))
				btn.set_enabled(true)
func hide_back() -> void: v("hint_back").set_vis(2)
func bonus(xp := "", cash_ := "", weed_ := "") -> void:
	v("bonus_xp").set_text(xp)
	v("bonus_xp").set_vis(0 if xp != "" else 2)
	v("bonus_cash").set_text(cash_)
	v("bonus_cash").set_vis(0 if cash_ != "" else 2)
	v("bonus_weed").set_text(weed_)
	v("bonus_weed").set_vis(0 if weed_ != "" else 2)
	Anim.play(v("bonus_holder"), "bonus", func():
		for id in ["bonus_xp", "bonus_cash", "bonus_weed"]: v(id).set_vis(2))
func tell_out() -> void: Anim.play(v("tell"), "client_text_out")
func close() -> void:
	g.close_dialog(d)
	g.door_schedule()
func pissoff(_btn) -> void:
	hide_back()
	v("btn_pissoff").set_vis(2)
	tell_out()
	if name == "jesus_jhamal":
		close()
		g.burglary()
	elif name == "mr_malone":
		close()
		g.raid()
	elif name == "alien":
		close()
		g.abduction()
	elif name == "zombie":
		close()
		g.zombie_attack()
	else:
		Sfx.play("door_close")
		Anim.play(v("photo"), "piss_off", close)
	g.gift_taken = false
func sell(btn) -> void:
	hide_back()
	var xp: int = Sfx.theme_mult() * (2 if Save.bool_of("sofa") else 1)
	if not g.m(xp, deal["cash"], -deal["weed"]): return
	Sfx.play("earn")
	btn.set_vis(1)
	g.L("sell")
	for pair in [[1000, "usd_1000"], [5000, "usd_5000"], [10000, "usd_10000"], [50000, "usd_50000"], [100000, "usd_100000"], [500000, "usd_500000"], [1000000, "usd_1000000"]]:
		if g.cash() >= pair[0]: g.L(pair[1])
	bonus("+%d xp" % xp, "+%d cash" % deal["cash"], "-%d weed" % deal["weed"])
	tell_out()
	var l := v("sell_left_hand")
	var r := v("sell_right_hand")
	var c := v("sell_cash")
	var hs := v("sell_hash")
	for x in [l, r, c, hs]: x.set_vis(0)
	Anim.play(l, "sell_left_hand")
	Anim.play(r, "sell_right_hand")
	Anim.play(hs, "sell_hash")
	Anim.play(c, "sell_cash", func():
		for x in [l, r, c, hs]: x.set_vis(2)
		close())
	g.gift_taken = false
func pay(btn) -> void:
	hide_back()
	if not g.m(0, -price, 0): return
	Sfx.play("pay")
	btn.set_vis(1)
	if name == "jesus_jhamal": g.L("gangsters")
	if name == "mr_malone": g.L("malone")
	bonus("", "-%d cash" % price, "")
	tell_out()
	var l := v("sell_left_hand")
	var r := v("sell_right_hand")
	var hs := v("sell_hash")
	for x in [l, r, hs]: x.set_vis(0)
	Anim.play(l, "sell_left_hand")
	Anim.play(r, "sell_right_hand")
	Anim.play(hs, "sell_hash", func():
		for x in [l, r, hs]: x.set_vis(2)
		close())
	g.desk()
func trade(btn) -> void:
	hide_back()
	if not g.m(deal["cash"], 0, -deal["weed"]): return
	Sfx.play("alien")
	btn.set_vis(1)
	g.L("alien")
	bonus("+%d xp" % deal["cash"], "", "-%d weed" % deal["weed"])
	tell_out()
	var l := v("sell_left_hand")
	var r := v("sell_right_claw")
	var x_ := v("sell_xp")
	var hs := v("sell_hash")
	for x in [l, r, x_, hs]: x.set_vis(0)
	Anim.play(l, "sell_left_hand")
	Anim.play(r, "sell_right_hand")
	Anim.play(hs, "sell_hash")
	Anim.play(x_, "sell_cash", func():
		for x in [l, r, x_, hs]: x.set_vis(2)
		close())
func trick(btn) -> void:
	hide_back()
	if not g.m(0, 0, -deal["weed"]): return
	Sfx.play("zombie_trick")
	btn.set_vis(1)
	bonus("", "", "-%d weed" % deal["weed"])
	tell_out()
	var l := v("sell_left_hand")
	var r := v("sell_right_stub")
	var hs := v("sell_hash")
	for x in [l, r, hs]: x.set_vis(0)
	Anim.play(l, "sell_left_hand")
	Anim.play(r, "sell_right_hand")
	Anim.play(hs, "sell_hash", func():
		for x in [l, r, hs]: x.set_vis(2)
		close())
func buy(btn) -> void:
	hide_back()
	if not g.m(0, -price, 0): return
	Sfx.play("pay")
	btn.set_vis(1)
	var b: Array = BUY.get(name, ["", "", 0, "", 0, 0])
	var key: String = b[0]
	Save.put(key, true)
	g.L({"safe": "lee", "panties": "get_panties", "phone": "phone_buy"}.get(key, key))
	bonus("", "-%d cash" % price, "")
	tell_out()
	var l := v("sell_left_hand")
	var r := v("sell_right_hand")
	var hs := v("sell_hash")
	for x in [l, r, hs]: x.set_vis(0)
	Anim.play(l, "sell_left_hand")
	Anim.play(r, "sell_right_hand")
	Anim.play(hs, "sell_hash", func():
		for x in [l, r, hs]: x.set_vis(2)
		close())
	g.desk()
	g.room_refresh()
func shoot(btn) -> void:
	hide_back()
	btn.set_vis(1)
	Sfx.play("shotgun")
	var gun := v("shoot_gun")
	var fire := v("shoot_fire")
	gun.set_vis(0)
	fire.set_vis(0)
	Anim.play(gun, "shoot_gun")
	Anim.play(fire, "shoot_fire", func(): fire.set_vis(2))
	var roll := randi() % 100
	Anim.play(v("photo"), "shoot_photo", func():
		g.m(0, roll, 0)
		Sfx.play("earn")
		bonus("", "+%d cash" % roll, "")
		v("photo").set_vis(2))
	g.after(4.0, close)
func bonus_gift(btn, str_key: String) -> void:
	hide_back()
	btn.set_vis(1)
	btn.set_enabled(false)
	g.popup_item(str_key)
func dice(btn) -> void:
	hide_back()
	btn.set_vis(1)
	btn.set_enabled(false)
	var n := randi() % 200 - 50
	g.m(n, 0, 0)
	Sfx.play("bonus")
	bonus("%s%d xp" % ["+" if n > 0 else "", n], "", "")
func smoke(kind: int, mode: String, secs: float) -> void:
	hide_back()
	var mult := kind
	var xp: int = Sfx.theme_mult() * mult
	if not g.m(xp, 0, -kind): return
	var btn := ui.view("btn_rollajoint" if kind == 1 else ("btn_smokeabong" if kind == 2 else "btn_vaporize"))
	btn.set_vis(2)
	if kind == 1 and (g.task_a == "joints" or g.task_b == "joints"):
		Save.put(name, true)
		g.tasks_refresh()
		if g.count_clients("") >= Data.CLIENTS.size() - 6: g.L("joints")
	if kind == 2 and (g.task_a == "bong_all" or g.task_b == "bong_all"):
		Save.put("bong" + name, true)
		g.tasks_refresh()
		if g.count_clients("bong") >= Data.CLIENTS.size() - 6: g.L("bong_all")
	if kind == 3 and (g.task_a == "vaporize_all" or g.task_b == "vaporize_all"):
		Save.put("vaporizer" + name, true)
		g.tasks_refresh()
		if g.count_clients("vaporizer") >= Data.CLIENTS.size() - 6: g.L("vaporize_all")
	bonus("+%d xp" % xp, "", "-%d weed" % kind)
	Sfx.play("lighter" if kind != 3 else "vaporize")
	if kind == 1: Sfx.play("smoke")
	if kind == 2: Sfx.play("bong")
	var sm := v("smoke")
	var tile := v("smoke_tile")
	var h: float = v("background").size.y
	tile.lh = h * 2.0
	tile.mg[3] = -h
	sm.set_vis(0)
	tile._relayout()
	var tw: Tween = d["w"].create_tween().set_loops()
	tw.tween_property(tile, "position:y", -h, secs).from(0.0)
	Anim.play(sm, "roll_a_joint_in", func():
		tw.kill()
		after_smoke(kind))
func after_smoke(kind: int) -> void:
	var sm := v("smoke")
	sm.set_vis(2)
	if BUY.has(name): price = BUY[name][5]
	if name == "ultimator": price = 7000
	var pool := []
	var rng := range(17, 24) if kind == 1 else (range(24, 29) if kind == 2 else range(29, 34))
	for i in rng: pool.append(arr[i])
	deal = split(pool[randi() % pool.size()])
	actions()
	if v("btn_rollajoint").vis == 0 and kind == 1: v("btn_rollajoint").set_vis(2)
	v("photo").set_src(Assets.drawable("@drawable/photo_%s_1" % name))
	show_deal()
