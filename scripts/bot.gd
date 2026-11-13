class_name Bot
extends RefCounted
var g: Node
var stats := {"harvest": 0, "water": 0, "plant": 0, "sell": 0, "door": 0, "shop": 0, "dialogs": 0}
var last_xp := -1
var stall := 0
func _init(game: Node) -> void: g = game
func top() -> AView:
	for i in range(g.layer.get_child_count() - 1, -1, -1):
		var c: Node = g.layer.get_child(i)
		if c is AView and not c.is_queued_for_deletion(): return c
	return null
func vis(u: Droid, id: String) -> AView:
	var v := u.view(id)
	return v if v != null and v.is_visible_in_tree() and v.vis == 0 else null
func tap(v: AView) -> void: await g.click_view(v)
func dialog_step(w: AView) -> void:
	var u: Droid = w.ui
	stats["dialogs"] += 1
	if vis(u, "start") != null: await tap(vis(u, "start")); return
	if vis(u, "next_1") != null: await tap(vis(u, "next_1")); return
	if vis(u, "play") != null: await tap(vis(u, "play")); return
	var owned: ClientDlg = w.get_meta("owner", null)
	if vis(u, "btn_sell") != null and owned != null and g.weed_amt() >= owned.deal["weed"]:
		stats["sell"] += 1
		await tap(vis(u, "btn_sell"))
		return
	for id in ["btn_pay", "btn_trade", "btn_trick"]:
		if vis(u, id) != null:
			await tap(vis(u, id))
			if vis(u, "btn_pissoff") != null: await tap(vis(u, "btn_pissoff"))
			return
	if vis(u, "btn_pissoff") != null: await tap(vis(u, "btn_pissoff")); return
	if vis(u, "btn_deal") != null:
		u.view("slider").progress = 3
		await tap(vis(u, "btn_deal"))
		await g.get_tree().create_timer(3.0).timeout
		if is_instance_valid(w) and vis(u, "btn_hangup") != null: await tap(vis(u, "btn_hangup"))
		return
	if vis(u, "btn_hangup") != null: await tap(vis(u, "btn_hangup")); return
	for id in ["back", "btn_back"]:
		if vis(u, id) != null: await tap(vis(u, id)); return
func shop_step() -> void:
	await tap(g.ui.view("btn_shop"))
	await g.get_tree().create_timer(0.3).timeout
	if g.shop_dlg == null: return
	var sd: ShopDlg = g.shop_dlg
	for tab in ["seeds", "watering", "fertilizers", "pots"]:
		await tap(sd.ui.view("tab_%d" % (Data.TABS.find(tab) + 1)))
		var list: Array = Data.shop_list(tab)
		for i in list.size():
			var inner: Droid = sd.rows[list[i][0]]["ui"]
			var b: AView = inner.view("button")
			if b != null and b.is_visible_in_tree() and b.vis == 0 and g.cash() >= int(list[i][1]) + 100 and (tab != "pots" or g.free_slot() >= 0):
				await tap(b)
				stats["shop"] += 1
				break
		if is_instance_valid(sd.d["w"]) and g.modal > 1:
			var t := top()
			if t != null and t.ui != sd.ui: await dialog_step(t)
	if g.shop_dlg != null: await tap(sd.ui.view("btn_back"))
func plant_step() -> void:
	for p in g.plants:
		if g.modal > 0: return
		var pot: AView = p.v("pot")
		if p.state == 8 and pot.is_visible_in_tree():
			await tap(pot)
			stats["harvest"] += 1
			await g.get_tree().create_timer(0.6).timeout
			return
		if p.state == -1:
			var seeds := -1
			for i in range(4, -1, -1):
				if Save.int_of("seeds_%d" % i) > 0:
					seeds = i
					break
			if seeds >= 0:
				await tap(pot)
				var b: AView = p.v("seeds_%d" % seeds)
				if b.is_visible_in_tree() and b.vis == 0:
					await tap(b)
					stats["plant"] += 1
					await g.get_tree().create_timer(1.4).timeout
				return
		if p.state >= 1 and p.state <= 7 and p.water <= 2 and pot.is_visible_in_tree():
			var any := false
			for w in Data.WATERING:
				if Save.int_of(w[0]) > 0:
					Save.put("selected_watering", w[0])
					any = true
					break
			if any:
				await tap(pot)
				stats["water"] += 1
				return
func door_step() -> bool:
	for i in 3:
		var b: AView = g.ui.view("door_photo_%d" % i)
		if b.vis == 0 and b.get_meta("client", "") != "" and b.is_visible_in_tree():
			var c: String = b.get_meta("client")
			if c in ["mr_malone", "jesus_jhamal", "alien", "zombie"] and g.weed_amt() == 0 and g.cash() < 1000: continue
			g.scroll_to(g.ui.view("weed_holder").size.x)
			await g.get_tree().create_timer(0.7).timeout
			await tap(b)
			stats["door"] += 1
			await g.get_tree().create_timer(0.3).timeout
			return true
	return false
func run(seconds: float) -> void:
	var t0 := Time.get_ticks_msec()
	var tick := 0
	while (Time.get_ticks_msec() - t0) / 1000.0 < seconds:
		await g.get_tree().create_timer(0.4).timeout
		tick += 1
		var tp := top()
		if tp != null:
			if tick % 15 == 0:
				var vs := []
				for k in tp.ui.ids:
					var vv: AView = tp.ui.ids[k]
					if is_instance_valid(vv) and vv.vis == 0 and vv.is_visible_in_tree() and (vv.clickable or k.begins_with("btn") or k == "back"): vs.append(k)
				print("BOT in dialog: ", vs.slice(0, 14), " modal=", g.modal)
			await dialog_step(tp)
			continue
		var tap_here: AView = g.ui.view("mj_tap_here")
		if tap_here != null and tap_here.is_visible_in_tree() and tap_here.vis == 0: await tap(g.ui.view("mj_joint")); continue
		if tick % 6 == 0 and g.cash() > 150:
			await shop_step()
			continue
		if tick % 3 == 0 and await door_step(): continue
		g.scroll_to(0.0)
		await g.get_tree().create_timer(0.6).timeout
		await plant_step()
		if tick % 40 == 0:
			print("BOT t=%d lvl=%d xp=%d cash=%d weed=%d stats=%s" % [(Time.get_ticks_msec() - t0) / 1000, g.level(), g.xp(), g.cash(), g.weed_amt(), stats])
		var sig: int = g.xp() + g.cash() + g.weed_amt()
		if sig == last_xp: stall += 1
		else:
			stall = 0
			last_xp = sig
		if stall == 150: print("BOT STALL no change for 60s at tick ", tick)
	print("BOT DONE lvl=%d xp=%d cash=%d weed=%d stats=%s" % [g.level(), g.xp(), g.cash(), g.weed_amt(), stats])
