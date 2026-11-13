extends Control
var ui := Droid.new()
var root: AView
var room: AView
var weed: AView
var plants: Array[Plant] = []
var layer: AView
var task_a := "none"
var task_b := "none"
var modal := 0
var door_timer: Timer
var phone_timer: Timer
var drag := ""
var drag_view: AView
var last_client := ""
var chalk_c := ""
var chalk_d := ""
func _ready() -> void:
	if not Assets.ok():
		var lu := LoaderUI.new()
		lu.loaded.connect(func(): get_tree().reload_current_scene())
		add_child(lu)
		return
	var sd := OS.get_environment("WF_SEED")
	if sd != "":
		var sj = JSON.parse_string(sd)
		if sj is Dictionary: Save.d.merge(sj, true)
	ui.handler = self
	root = ui.inflate("game")
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	layer = AView.new()
	layer.setup("FrameLayout", {"layout_width": -1, "layout_height": -1}, ui)
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	room = ui.view("room_scroll_view")
	weed = ui.view("weed_scroll_view")
	door_timer = _timer(knock)
	phone_timer = _timer(phone_tick)
	if Save.int_of("p_state_0", -3) == -3:
		Save.put("p_state_0", 1)
		Save.put("p_state_time_0", Save.now())
		Save.put("p_water_0", 0)
		Save.put("p_water_time_0", Save.now())
		Save.put("p_weed_type_0", 0)
		Save.put("p_pot_type_0", 0)
		Save.put("p_fertilizer_type_0", -1)
		Save.put("watering_0", 10)
	Save.put("sessions", Save.int_of("sessions") + 1)
	if not Save.bool_of("tutorial_slide"): ui.view("hint_slide").set_vis(0)
	for w in weed.get_child(0).get_children():
		if w is AView and w.has_meta("ids"): plants.append(Plant.new(self, w))
	ui.on_scroll[weed] = _weed_scrolled
	Sfx.music(Save.str_of("theme", "theme_instrumental") if Save.has("theme") else "theme_instrumental")
	await get_tree().process_frame
	await get_tree().process_frame
	_refresh_all()
	if not Save.bool_of("intro_showed") and OS.get_environment("WF_TEST") == "": IntroDlg.new(self, func(): Sfx.music("theme_instrumental"))
	weed.set_scroll(Vector2(Save.int_of("current_scroll"), 0))
	_weed_scrolled(weed)
	if OS.get_environment("WF_CLIENTS") != "":
		await clienttest()
		get_tree().quit()
		return
	if OS.get_environment("WF_UITEST") != "":
		await uitest()
		get_tree().quit()
		return
	if OS.get_environment("WF_TEST") != "":
		await selftest()
		get_tree().quit()
		return
	var shot := OS.get_environment("WF_SHOT")
	if shot != "":
		await get_tree().create_timer(1.0).timeout
		var act := OS.get_environment("WF_ACT")
		if act != "":
			match act.get_slice(":", 0):
				"client": open_client(act.get_slice(":", 1))
				"shop": open_shop(act.get_slice(":", 1))
				"mj": magic_joint()
				"burglary": burglary()
				"raid": raid()
				"abduction": abduction()
				"zombie": zombie_attack()
				"pause": show_pause()
				"cash": show_cash()
				"board": show_blackboard("a")
				"popup": popup_item("daily_bonus")
				"dealer": open_dealer()
				"intro": IntroDlg.new(self, Callable())
			await get_tree().create_timer(float(OS.get_environment("WF_WAIT") if OS.get_environment("WF_WAIT") != "" else "1.5")).timeout
		var pr := OS.get_environment("WF_PROBE")
		if pr != "":
			var pp := Vector2(float(pr.get_slice(",", 0)), float(pr.get_slice(",", 1)))
			_probe(root, pp)
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()
func check(name: String, ok: bool) -> void: print("TEST ", "PASS " if ok else "FAIL ", name)
func clienttest() -> void:
	Save.put("level", 16)
	Save.put("cash", 900000)
	for name in Data.CLIENTS:
		await get_tree().create_timer(4.5).timeout
		close_all()
		Save.put("weed", 500)
		var cl := ClientDlg.new(self, name)
		await get_tree().process_frame
		var acts := []
		for id in ["btn_sell", "btn_pay", "btn_trade", "btn_trick", "btn_rollajoint", "btn_smokeabong", "btn_vaporize", "btn_shoot", "btn_dice", "btn_christmas", "btn_valentine"]:
			if cl.v(id).vis == 0: acts.append(id)
		for id in cl.BTNS:
			if id.begins_with("btn_buya") and cl.v(id).vis == 0: acts.append(id)
		for id in acts:
			if cl.v(id).vis != 0: continue
			if id == "btn_christmas" or id == "btn_valentine": cl.bonus_gift(cl.v(id), "christmas_bonus")
			elif not id.begins_with("btn_roll") and not id.begins_with("btn_smoke") and id != "btn_vaporize": cl.call({"btn_sell": "sell", "btn_pay": "pay", "btn_trade": "trade", "btn_trick": "trick", "btn_shoot": "shoot", "btn_dice": "dice"}.get(id, "buy"), cl.v(id))
			else: cl.smoke({"btn_rollajoint": 1, "btn_smokeabong": 2, "btn_vaporize": 3}[id], "x", 1.0)
			await get_tree().create_timer(0.2).timeout
		print("CLIENT ", name, " actions=", acts.size())
	print("CLIENTS DONE")
func click_at(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p
		e.global_position = p
		get_viewport().push_input(e)
		await get_tree().process_frame
func click_view(v: AView) -> void: await click_at(v.get_global_rect().get_center())
func uitest() -> void:
	await get_tree().process_frame
	await click_view(ui.view("btn_shop"))
	await get_tree().create_timer(0.3).timeout
	check("click opens shop", shop_dlg != null)
	await click_view(shop_dlg.ui.view("tab_2"))
	check("tab click selects seeds", shop_dlg.tab == "seeds")
	await click_view(shop_dlg.ui.view("btn_back"))
	await get_tree().create_timer(0.3).timeout
	check("back closes shop", shop_dlg == null and modal == 0)
	await click_view(ui.view("btn_door"))
	await get_tree().create_timer(0.8).timeout
	check("door button scrolls right", weed.scroll.x > 100)
	await click_view(ui.view("btn_desk"))
	await get_tree().create_timer(0.8).timeout
	check("desk button scrolls back", weed.scroll.x < 5)
	ui.view("hint_slide").set_vis(2)
	var s0 := Save.int_of("watering_0")
	Save.put("selected_watering", "watering_0")
	await click_view(plants[0].v("pot"))
	await get_tree().create_timer(0.3).timeout
	check("tap plant waters it", Save.int_of("watering_0") == s0 - 1 and plants[0].water == 2)
	await click_view(ui.view("btn_settings"))
	await get_tree().create_timer(0.3).timeout
	check("settings opens pause", modal == 1)
	close_all()
	Save.put("customize_0", true)
	open_client("mike")
	await get_tree().create_timer(0.3).timeout
	check("client dialog open", modal == 1)
	Save.put("weed", 10)
	var cdlg_cash := cash()
	var btn: AView = null
	for c in layer.get_children():
		if c is AView and c.get_child_count() > 0:
			btn = c.get_child(0).find_child("*", true, false)
	await get_tree().create_timer(0.1).timeout
func close_all() -> void:
	for c in layer.get_children(): c.queue_free()
	modal = 0
	shop_dlg = null
func selftest() -> void:
	var p: Plant = plants[0]
	check("slot0 growing", p.state >= 1)
	Save.put("p_state_0", 8)
	p.set_state(8, Save.now())
	var c0 := cash()
	var w0 := weed_amt()
	p.harvest(null)
	await get_tree().create_timer(0.6).timeout
	check("harvest adds weed", weed_amt() == w0 + 10)
	check("harvest adds xp", xp() > 0)
	check("plant back to empty pot", p.state == -1)
	close_all()
	check("task grow completed", Save.bool_of("task_grow"))
	m(0, 100, 0)
	check("cash added", cash() == c0 + 100)
	check("not enough cash refused", not m(0, -999999, 0))
	close_all()
	Save.put("xp", 29)
	m(5, 0, 0)
	await get_tree().create_timer(2.5).timeout
	check("level up", level() == 1 and xp() == 0)
	close_all()
	Save.put("cash", 5000)
	var it: Array = Data.shop_item("pots_0")
	var slot := free_slot()
	apply_item(it)
	check("pot placed in free slot", plants[slot].state == -1)
	apply_item(Data.shop_item("seeds_1"))
	check("seeds bought", Save.int_of("seeds_1") == 1)
	apply_item(Data.shop_item("watering_2"))
	check("watering_2 gives 6 of watering_1", Save.int_of("watering_1") == 6)
	close_all()
	plants[slot].on_empty_pot(null)
	plants[slot].pick_seed(null, 1)
	check("seed consumed", Save.int_of("seeds_1") == 0)
	await get_tree().create_timer(1.5).timeout
	check("planted", plants[slot].state == 1 and plants[slot].weed_type() == 1)
	close_all()
	Save.put("selected_watering", "watering_1")
	plants[slot].on_plant(null)
	check("watered", plants[slot].water == 5 and Save.int_of("watering_1") == 5)
	var cl := ClientDlg.new(self, "ryan")
	check("client opens", cl.name == "ryan" and cl.deal["weed"] > 0)
	Save.put("weed", 20)
	var cw := weed_amt()
	var cc := cash()
	cl.sell(cl.v("btn_sell"))
	check("sell trades weed for cash", weed_amt() == cw - cl.deal["weed"] and cash() == cc + cl.deal["cash"])
	await get_tree().create_timer(3.0).timeout
	close_all()
	Save.flush()
	var t := FileAccess.get_file_as_string(Save.PATH)
	check("save persisted", t.contains("\"cash\""))
func _probe(n: Node, p: Vector2) -> void:
	if n is AView and n.is_visible_in_tree() and n.get_global_rect().has_point(p):
		var nm := ""
		for k in ui.ids:
			if ui.ids[k] == n: nm = k
		print("PROBE ", n.get_meta("type", n.kind), " id=", nm, " rect=", n.get_global_rect(), " src=", n.src.get("kind"), " bg=", n.bg.get("kind"), " vis=", n.vis)
	for c in n.get_children(): _probe(c, p)
func _timer(cb: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.timeout.connect(cb)
	add_child(t)
	return t
func after(sec: float, cb: Callable) -> void: get_tree().create_timer(sec).timeout.connect(cb)
func _refresh_all() -> void:
	room_refresh()
	hud()
	desk()
	watering_buttons()
	tasks_refresh()
	door_restore()
	door_schedule()
	phone_schedule()
	m(0, 0, 0)
	if Save.int_of("last_bonus") <= Save.now() - 86400000:
		if Save.int_of("last_bonus") > 0: popup_item("daily_bonus")
		Save.put("last_bonus", Save.now())
func level() -> int: return mini(Save.int_of("level"), 17)
func ldata() -> Array: return Data.LEVELS[level()]
func cash() -> int: return Save.int_of("cash")
func weed_amt() -> int: return Save.int_of("weed")
func xp() -> int: return Save.int_of("xp")
func has_ferts() -> bool:
	for f in Data.FERTS:
		if Save.int_of(f[0]) > 0: return true
	return false
func free_slot() -> int:
	for i in 12:
		if Save.int_of("p_state_%d" % i, -3) < -1: return i
	return -1
func count_clients(prefix: String) -> int:
	var n := 0
	for i in Data.CLIENTS.size():
		var c: String = Data.CLIENTS[i]
		if Save.bool_of(prefix + c) and c != "santa" and c != "cupid": n += 1
	return n
func m(dxp: int, dcash: int, dweed: int) -> bool:
	if cash() + dcash < 0:
		show_cash()
		return false
	if weed_amt() + dweed < 0:
		popup_error("not_enough_weed")
		Sfx.play("fail")
		return false
	Save.put("cash", maxi(cash() + dcash, 0))
	Save.put("weed", maxi(weed_amt() + dweed, 0))
	Save.put("xp", maxi(xp() + dxp, 0))
	Save.put("desk_cash", maxi(Save.int_of("desk_cash") + dcash, 0))
	Save.put("desk_weed", maxi(Save.int_of("desk_weed") + dweed, 0))
	if xp() >= ldata()[1]:
		Save.put("xp", ldata()[1])
		after(2.0, level_check)
	hud()
	desk()
	return true
func level_check() -> void:
	if modal > 0:
		after(2.0, level_check)
		return
	if level() == 17: return
	Sfx.play("lighter")
	Sfx.play("level_complete")
	Save.put("level", level() + 1)
	Save.put("xp", 0)
	hud()
	tasks_refresh()
	magic_joint()
func hud() -> void:
	if ui.view("weed_value") == null: return
	ui.view("weed_value").set_text(str(weed_amt()))
	ui.view("cash_value").set_text(str(cash()))
	ui.view("xp_value").set_text(str(xp()))
	ui.view("xp_max").set_text("-" if level() == 17 else str(ldata()[1]))
	ui.view("xp_holder").set_w(float(xp()) / float(ldata()[1]) * 130.0 * Assets.DP)
	ui.view("level").set_text("level %d" % level())
	var hint := ui.view("hint_xp")
	hint.set_vis(0 if level() > 0 and level() < 2 else 2)
func desk() -> void:
	var ch := ui.view("desk_cash_holder")
	for c in ch.get_children(): c.queue_free()
	ch.xy = Vector2(150, 230) * Assets.DP
	var n := int((1.0 - exp(float(Save.int_of("desk_cash")) * -0.002)) * 50.0)
	for i in n:
		var im := AView.new()
		im.setup("ImageView", {"layout_width": "50dp", "layout_height": "50dp", "layout_marginLeft": "%ddp" % ((i % 5) * 10), "layout_marginTop": "%ddp" % (((i % 2) * 5) / 2 + (10 - i / 5) * 10), "src": "@drawable/desk_cash"}, ui)
		ch.add_child(im)
	var wh := ui.view("desk_weed_holder")
	wh.xy = Vector2(218, 304) * Assets.DP
	var f := 1.0 - exp(float(Save.int_of("desk_weed")) * -0.025)
	var dw := ui.view("desk_weed")
	dw.scale = Vector2(f, f)
	dw.pivot_offset = dw.img_size(dw.src) * Vector2(0.5, 0.7)
	room._sort_all()
func color_of(c: int) -> Color:
	var u := c & 0xFFFFFFFF
	return Color8((u >> 16) & 255, (u >> 8) & 255, u & 255, (u >> 24) & 255)
func room_refresh() -> void:
	var a := ui.view("room_a")
	var b := ui.view("room_b")
	var n := 0
	var col := -7632022
	if Save.bool_of("customize_3"):
		n = 3
		col = -13293542
	elif Save.bool_of("customize_2"):
		n = 2
		col = -9743051
	elif Save.bool_of("customize_0"):
		n = 1
		col = -11913947
	a.set_bg(Assets.drawable("@drawable/room_%d_a" % n))
	b.set_bg(Assets.drawable("@drawable/room_%d_b" % n))
	room.set_bg({"kind": "color", "color": color_of(col)})
	if Save.bool_of("customize_1"): ui.view("window_blinds").set_bg(Assets.drawable("@drawable/window_blinds"))
	ui.view("window_blinds").set_src(Assets.drawable("@drawable/window_blinds")) if Save.bool_of("customize_1") else ui.view("window_blinds").set_src({})
	ui.view("noads").set_vis(0 if Save.bool_of("noads") else 2)
	for it in ["player", "box", "safe", "bong", "vaporizer", "sofa", "panties", "shotgun", "painting", "phone"]:
		var v := ui.view(it)
		if v != null: v.set_vis(0 if Save.bool_of(it) else 2)
	ui.view("hint_box").set_vis(0 if Save.bool_of("box") and not Save.bool_of("tutorial_box") else 2)
	ui.view("hint_safe").set_vis(0 if Save.bool_of("safe") and not Save.bool_of("tutorial_safe") else 2)
func watering_buttons() -> void:
	for i in [0, 1, 3]:
		var id: String = "watering_%d" % i
		var b := ui.view(id)
		var n := Save.int_of(id)
		if n > 0:
			b.set_vis(0)
			b.set_text(str(n) + ("\t" if i == 3 else ""))
			b.comp = {}
			if Save.str_of("selected_watering") == id:
				b.comp = {"Left": Assets.drawable("@drawable/select_left"), "Right": Assets.drawable("@drawable/select_right")}
			b.queue_redraw()
		else: b.set_vis(2)
		if not b.has_meta("cb"): b.on(func(_v):
			Sfx.play("take")
			Save.put("selected_watering", id)
			watering_buttons())
func L(task: String) -> void:
	if task_a != task and task_b != task: return
	show_blackboard("a" if task_a == task else "b")
	if task_a == task:
		task_b_shift()
	else: Save.remove("current_task2")
	Save.put("task_" + task, true)
	var info := Data.task_info(task)
	m(info[1], 0, 0)
	tasks_refresh()
func task_b_shift() -> void:
	if task_b != "none": Save.put("current_task1", task_b)
	else: Save.remove("current_task1")
	Save.remove("current_task2")
func task_blocked(t: String) -> bool:
	if t == "player" and Save.bool_of("player"): return true
	if t == "lee" and Save.bool_of("safe"): return true
	if t == "bong" and Save.bool_of("bong"): return true
	if t == "sofa" and Save.bool_of("sofa"): return true
	if t == "shotgun" and Save.bool_of("shotgun"): return true
	if t == "painting" and Save.bool_of("painting"): return true
	if t == "customize_0" and Save.bool_of("customize_0"): return true
	if t == "customize_1" and Save.bool_of("customize_1"): return true
	if t == "customize_2" and (Save.bool_of("customize_2") or Save.bool_of("customize_3")): return true
	if t == "customize_3" and Save.bool_of("customize_3"): return true
	return false
func tasks_refresh() -> void:
	task_a = Save.str_of("current_task1", "none")
	task_b = Save.str_of("current_task2", "none")
	if Data.task_index(task_a) < 0 or task_a == "lapdance": task_a = "none"
	if Data.task_index(task_b) < 0 or task_b == "lapdance": task_b = "none"
	for t in Data.TASKS:
		var k: String = t[0]
		if k == "lapdance" or Save.bool_of("task_" + k): continue
		if level() < Data.level_idx(t[2]): continue
		if task_blocked(k): continue
		if task_a == "none" and task_b != k: task_a = k
		elif task_b == "none" and task_a != k:
			task_b = k
			break
	Save.put("current_task1", task_a)
	Save.put("current_task2", task_b)
	var n := Data.CLIENTS.size() - 6
	var cs := "  %d/%d" % [count_clients(""), n]
	var bs := "  %d/%d" % [count_clients("bong"), n]
	var vs := "  %d/%d" % [count_clients("vaporizer"), n]
	chalk_c = chalk_line(task_a, cs, bs, vs)
	chalk_d = chalk_line(task_b, cs, bs, vs)
	ui.view("task1").set_text(chalk_c)
	ui.view("task2").set_text(chalk_d)
func chalk_line(t: String, cs: String, bs: String, vs: String) -> String:
	if t == "none": return ""
	var info := Data.task_info(t)
	return Assets.str_of("task_" + t) + (cs if t == "gangsters" else "") + (bs if t == "bong_all" else "") + (vs if t == "vaporize_all" else "") + "   +%dXP" % info[1]
func _weed_scrolled(v: AView) -> void:
	var rw: float = ui.view("room_holder").size.x - weed.size.x
	var ww: float = ui.view("weed_holder").size.x - weed.size.x
	if ww > 0: room.set_scroll(Vector2(rw * weed.scroll.x / ww, 0))
	if weed.scroll.x > weed.size.x / 2.0 and ui.view("hint_slide").vis == 0:
		Save.put("tutorial_slide", true)
		ui.view("hint_slide").set_vis(2)
	Save.put("current_scroll", int(weed.scroll.x))
	door_arrows()
func onDesk(_v) -> void:
	Sfx.play("scroll")
	scroll_to(0.0)
func onDoor(_v) -> void:
	Sfx.play("scroll")
	scroll_to(ui.view("weed_holder").size.x)
func scroll_to(x: float) -> void:
	var tw := create_tween()
	tw.tween_method(func(p: float):
		weed.set_scroll(Vector2(p, 0))
		_weed_scrolled(weed), weed.scroll.x, x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
func onShop(_v) -> void: open_shop("")
func onBlackboard(_v) -> void: show_blackboard()
func onCash(_v) -> void: show_cash()
func onSettings(_v) -> void: show_pause()
func door_arrows() -> void:
	var far: bool = (ui.view("weed_holder").size.x - weed.size.x) - weed.scroll.x > 100
	for i in 3:
		var c := door_client(i)
		ui.view("door_photo_i_%d" % i).set_vis(0 if (c == "mr_malone" or c == "jesus_jhamal" or c == "alien") and far else 2)
		ui.view("door_photo_ii_%d" % i).set_vis(0 if c == "zombie" and far else 2)
func door_client(i: int) -> String:
	var b := ui.view("door_photo_%d" % i)
	return str(b.get_meta("client", ""))
func door_restore() -> void:
	for i in 3:
		var c := Save.str_of("client_%d" % i)
		if c != "": door_show(i, c, false)
func door_show(i: int, c: String, animate: bool) -> void:
	var b := ui.view("door_photo_%d" % i)
	var t := ui.view("door_text_%d" % i)
	b.set_meta("client", c)
	b.set_src(Assets.drawable("@drawable/photo_" + c))
	t.set_text(Assets.arrays.get(c, ["", ""])[1])
	b.set_vis(0)
	t.set_vis(0)
	b.on(onClient.bind(i))
	if animate:
		Anim.play(b, "door_photo_in")
		Anim.play(t, "door_text_in")
	door_arrows()
	Anim.play(ui.view("btn_door"), "scale_bounce_anim")
func door_clear(i: int) -> void:
	var b := ui.view("door_photo_%d" % i)
	var t := ui.view("door_text_%d" % i)
	b.remove_meta("client")
	b.set_vis(2)
	t.set_vis(2)
	Save.remove("client_%d" % i)
	door_arrows()
func door_interval() -> float:
	var s := 10.0
	if Save.bool_of("customize_0"): s = 7.0
	if Save.bool_of("customize_2"): s = 5.0
	if Save.bool_of("customize_3"): s = 3.0
	return s
func door_schedule() -> void: door_timer.start(door_interval())
func door_cancel() -> void: door_timer.stop()
func knock() -> void:
	if modal > 0:
		door_schedule()
		return
	door_schedule()
	var i := randi() % 3
	var visits := Save.int_of("client_visits")
	if door_client(i) != "":
		var c := door_client(i)
		if c == "alien" or c == "mr_malone" or c == "jesus_jhamal" or c == "zombie":
			pass
		last_client = c
		var b := ui.view("door_photo_%d" % i)
		Anim.play(b, "door_photo_out", func(): door_clear(i))
		Anim.play(ui.view("door_text_%d" % i), "door_text_out")
		return
	Save.put("client_visits", visits + 1)
	var c2: String = Data.CLIENTS[randi() % (Data.CLIENTS.size() - 1)]
	for k in 3:
		if door_client(k) == c2: return
	if last_client == c2: return
	var ok := true
	var now := Time.get_datetime_dict_from_system()
	match c2:
		"cupid": ok = (now["month"] == 1 and now["day"] >= 20) or (now["month"] == 2 and now["day"] <= 20)
		"santa": ok = now["month"] == 12
		"alien":
			ok = level() >= 11 and visits - Save.int_of("alien_last_visit") >= 20 and weed_amt() != 0
			if ok: Save.put("alien_last_visit", visits)
		"mr_malone":
			ok = level() >= 8 and visits - Save.int_of("police_last_visit") >= (100 if Save.bool_of("customize_1") else 40)
			if ok: Save.put("police_last_visit", visits)
		"jesus_jhamal":
			ok = level() >= 3 and visits - Save.int_of("gangsters_last_visit") >= 40 and Save.int_of("desk_cash") >= 100
			if ok: Save.put("gangsters_last_visit", visits)
	if not ok: return
	var snd := "knock_medium"
	if c2 in ["ryan", "mike", "bob"]: snd = "knock_hard_1"
	elif c2 in ["jane", "mary", "lucy", "sandy", "nancy", "goth", "ian"]: snd = "knock_soft"
	elif c2 == "mr_malone" or c2 == "jesus_jhamal": snd = "knock_hard_2"
	elif c2 == "alien": snd = "knock_alien"
	elif c2 == "santa" or c2 == "cupid": snd = "knock_hard_1"
	Sfx.play(snd)
	door_show(i, c2, true)
func phone_schedule() -> void:
	if Save.bool_of("phone"):
		Save.put("dealer_visits", Save.int_of("dealer_visits") + 1)
		phone_timer.start(3.0)
func phone_tick() -> void:
	phone_schedule()
	var ph := ui.view("phone")
	if Save.int_of("dealer_visits") % 60 <= 55:
		ph.stop_anim()
		ph.enabled = false
		Anim.stop(ph)
	else:
		if not ph.enabled: Sfx.play("phone_ring")
		ph.enabled = true
		ph.start_anim()
		if not Anim.busy(ph): Anim.play(ph, "phone_ring")
func onClient(_v, i: int) -> void:
	var c := door_client(i)
	if c == "": return
	door_clear(i)
	open_client(c)
func onPhone(_v) -> void:
	if ui.view("phone").enabled: open_dealer()
func onSelectVinyl(_v) -> void: show_vinyl_box()
func onBuyVinyl(_v) -> void: open_shop("vinyl")
func _input(e: InputEvent) -> void:
	if modal > 0 or root == null: return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			var p: Vector2 = e.position
			if ui.view("desk_cash_holder").visible and ui.view("desk_cash_holder").get_global_rect().has_point(p) and Save.int_of("desk_cash") > 0: start_drag("cash", ui.view("desk_cash_holder"))
			elif ui.view("desk_weed_holder").get_global_rect().has_point(p) and Save.int_of("desk_weed") > 0: start_drag("weed", ui.view("desk_weed_holder"))
			elif ui.view("vinyl_holder").vis == 0:
				for i in 5:
					var vb := ui.view("vinyl_%d" % i)
					if vb.vis == 0 and vb.get_global_rect().has_point(p):
						start_drag("vinyl%d" % i, vb)
						break
			if drag != "": get_viewport().set_input_as_handled()
		elif drag != "":
			end_drag(e.position)
			get_viewport().set_input_as_handled()
	elif e is InputEventMouseMotion and drag != "":
		move_drag(e.position)
		get_viewport().set_input_as_handled()
func start_drag(kind: String, v: AView) -> void:
	drag = kind
	drag_view = v
	ui.dragging = true
	if kind.begins_with("vinyl"): ui.view("vinyl_").set_vis(0)
func room_pos(p: Vector2) -> Vector2:
	return p + Vector2(room.scroll.x, 0) - ui.view("room_holder").get_global_position()
func move_drag(p: Vector2) -> void:
	var rp := room_pos(p)
	if drag == "cash":
		drag_view.xy = rp - Vector2(50, 90) * Assets.DP
		room._sort_all()
	elif drag == "weed":
		drag_view.xy = rp - Vector2(64, 50) * Assets.DP
		room._sort_all()
	else:
		var vv := ui.view("vinyl_")
		vv.xy = rp - Vector2(40, 80) * Assets.DP
		room._sort_all()
func over(id: String, p: Vector2) -> bool:
	var v := ui.view(id)
	return v.vis == 0 and v.get_global_rect().grow(20).has_point(p)
func end_drag(p: Vector2) -> void:
	var kind := drag
	drag = ""
	ui.dragging = false
	if kind == "cash" or kind == "weed":
		if over("safe", p):
			if kind == "cash":
				Save.put("desk_cash", 0)
				L("safe")
				Save.put("tutorial_safe", true)
				ui.view("hint_safe").set_vis(2)
			else: Save.put("desk_weed", 0)
			Sfx.play("safe_close")
		desk()
		room_refresh()
	else:
		var i := int(kind.substr(5))
		if over("player", p):
			var th: String = ["theme_original", "theme_raggae", "theme_punk", "theme_dubstep", "theme_trance"][i]
			Sfx.music(th)
			Save.put("theme", th)
			Save.put("vinyl_%d" % i, Save.int_of("vinyl_%d" % i) - 1)
			L("vinyl_%d" % i)
		ui.view("vinyl_").set_vis(2)
		ui.view("vinyl").set_vis(2)
		ui.view("vinyl_holder").set_vis(2)
		ui.view("no_vinyl").set_vis(2)
		ui.view("box").clickable = true
func show_vinyl_box() -> void:
	var any := false
	for i in 5:
		var vb := ui.view("vinyl_%d" % i)
		var n := Save.int_of("vinyl_%d" % i)
		vb.set_vis(0 if n > 0 else 2)
		if n > 0:
			vb.set_text(str(n))
			any = true
	if not any: ui.view("no_vinyl").set_vis(0)
	else:
		ui.view("vinyl_holder").set_vis(0)
		Sfx.play("take")
	Save.put("tutorial_box", true)
	ui.view("hint_box").set_vis(2)
var gift_taken := false
var shop_dlg: ShopDlg
func dialog(name: String, dim := true) -> Dictionary:
	var dd := Droid.new()
	dd.handler = self
	var r := dd.inflate(name)
	var w := AView.new()
	w.setup("FrameLayout", {"layout_width": -1, "layout_height": -1}, dd)
	w.mouse_filter = Control.MOUSE_FILTER_STOP
	if dim: w.set_bg({"kind": "color", "color": Color(0, 0, 0, 0.6)})
	w.add_child(r)
	r.lgrav = 0x11
	layer.add_child(w)
	modal += 1
	door_cancel()
	phone_timer.stop()
	layer._sort_all()
	return {"ui": dd, "w": w, "root": r}
func close_dialog(dd: Dictionary) -> void:
	if not is_instance_valid(dd["w"]): return
	dd["w"].queue_free()
	modal = maxi(modal - 1, 0)
	if modal == 0:
		door_schedule()
		phone_schedule()
func after_shop() -> void:
	shop_dlg = null
	for p in plants:
		p.clear_menus()
	watering_buttons()
	room_refresh()
	hud()
func open_shop(tab: String) -> void:
	if shop_dlg != null: return
	shop_dlg = ShopDlg.new(self, tab)
func open_client(c: String) -> void: ClientDlg.new(self, c)
func apply_item(it: Array) -> void:
	var id: String = it[0]
	if id.begins_with("watering"):
		if id == "watering_2":
			Save.put("watering_1", Save.int_of("watering_1") + 6)
			Save.put("selected_watering", "watering_1")
		else:
			Save.put(id, Save.int_of(id) + 1)
			Save.put("selected_watering", id)
		if id == "watering_1": L("watering_1")
		if id == "watering_2": L("watering_2")
		if id == "watering_3": L("watering_3")
		watering_buttons()
	elif id.begins_with("seeds"):
		Save.put(id, Save.int_of(id) + 1)
	elif id.begins_with("pots"):
		var s := free_slot()
		if s >= 0:
			var p: Plant = plants[s]
			p.set_pot(int(id.substr(5)))
			p.set_state(-1, Save.now())
			L("pot")
			if id == "pots_1": L("pots_1")
			if id == "pots_2": L("pots_2")
	elif id.begins_with("fertilizer"): Save.put(id, Save.int_of(id) + 1)
	elif id.begins_with("customize"):
		Save.put(id, true)
		if id == "customize_2": Save.put("customize_3", false)
		if id == "customize_3": Save.put("customize_2", false)
		L(id)
		room_refresh()
	elif id.begins_with("vinyl"):
		Save.put(id, Save.int_of(id) + 1)
		L("vinyl")
		L(id)
func popup(error := "", ok := "", item: Array = [], bonus_key := "") -> void:
	var dd := dialog("popup")
	var u: Droid = dd["ui"]
	Sfx.play("popup" if item.is_empty() else "bonus")
	u.view("error").set_vis(2)
	u.view("ok").set_vis(2)
	u.view("item").set_vis(2)
	if error != "":
		u.view("error").set_text(error)
		u.view("error").set_vis(0)
	if ok != "":
		u.view("ok").set_text(ok)
		u.view("ok").set_vis(0)
	if not item.is_empty():
		u.view("item").set_vis(0)
		u.view("pic").set_src(Assets.drawable("@drawable/" + item[0]))
		u.view("bonus").set_text(Assets.str_of(bonus_key))
		u.view("title").set_text(Assets.str_of(item[0] + "_name"))
		u.view("descr").set_text(Assets.str_of(item[0] + "_descr"))
	u.on("back", func(_v): close_dialog(dd))
func popup_error(k: String) -> void: popup(Assets.str_of(k))
func popup_text(k: String) -> void: popup("", Assets.str_of(k))
func popup_item(bonus_key: String) -> void:
	var pool := []
	for t in ["watering", "seeds", "pots", "fertilizers"]: pool.append_array(Data.shop_list(t))
	if level() > 6: pool.append_array(Data.VINYL)
	var it: Array = pool[randi() % pool.size()]
	apply_item(it)
	popup("", "", it, bonus_key)
func show_cash() -> void:
	var dd := dialog("cash")
	var u: Droid = dd["ui"]
	for id in ["btn_cash100k", "btn_cash1000k", "btn_cash1k", "btn_cash10k", "btn_video", "btn_share"]: u.view(id).set_vis(2)
	u.on("btn_back", func(_v):
		Sfx.play("tap")
		close_dialog(dd))
func show_blackboard(strike := "") -> void:
	var dd := dialog("blackboard")
	var u: Droid = dd["ui"]
	Sfx.play("chalk")
	u.view("task1").set_text(chalk_c)
	u.view("task2").set_text(chalk_d)
	if strike == "a": u.view("task1").strike = true
	if strike == "b": u.view("task2").strike = true
	u.on("back", func(_v):
		Sfx.play("tap")
		close_dialog(dd))
func show_pause() -> void:
	var dd := dialog("pause")
	var u: Droid = dd["ui"]
	u.view("leaderboards").set_vis(2)
	u.view("achievements").set_vis(2)
	u.view("feedback").set_vis(2)
	u.view("rotate").set_vis(2)
	u.view("version").set_text("v.1.7.61")
	var mute := u.view("mute")
	mute.set_src(Assets.drawable("@drawable/ic_menu_muteon" if Save.bool_of("mute") else "@drawable/ic_menu_muteoff"))
	u.on("back", func(_v):
		Sfx.play("tap")
		close_dialog(dd))
	u.on("mute", func(_v):
		Save.put("mute", not Save.bool_of("mute"))
		Sfx.refresh()
		mute.set_src(Assets.drawable("@drawable/ic_menu_muteon" if Save.bool_of("mute") else "@drawable/ic_menu_muteoff")))
	u.on("newgame", func(_v):
		Save.d.clear()
		Save.flush()
		get_tree().reload_current_scene())
	u.on("comics", func(_v):
		close_dialog(dd)
		show_comics())
func show_comics() -> void:
	var dd := dialog("pause")
	var u: Droid = dd["ui"]
	u.view("version").set_vis(2)
	for id in ["newgame", "comics", "feedback", "achievements", "leaderboards", "rotate", "mute"]: u.view(id).set_vis(2)
	u.view("back").set_text("Close")
	u.on("back", func(_v): close_dialog(dd))
func burglary() -> void:
	for p in plants: p.clear_menus()
	var lost_cash := Save.int_of("desk_cash")
	var lost_weed := Save.int_of("desk_weed")
	Save.put("cash", maxi(cash() - lost_cash, 0))
	Save.put("weed", maxi(weed_amt() - lost_weed, 0))
	Save.put("desk_cash", 0)
	Save.put("desk_weed", 0)
	hud()
	desk()
	var r0 := Assets.rec("c_burglary_0")
	var r1 := Assets.rec("c_burglary_1")
	var y1: float = r0["tex"].get_height() * float(r0["scale"]) * 0.6 + 20.0
	var y2: float = r1["tex"].get_height() * float(r1["scale"]) * 0.64 + 20.0 + y1
	Comix.new(self, "comix_burglary", "burglary", [["comix_burglary_0", "t", -1600.0, 0.0, 1000.0, 1000.0], ["comix_burglary_1", "t", 1600.0, 0.0, 1000.0, 1500.0, y1], ["comix_burglary_2", "t", -1600.0, 0.0, 500.0, 2000.0, y2]], ["-%d cash" % lost_cash, "-%d weed" % lost_weed, ""], "pay")
func raid() -> void:
	ui.view("door_photo_i_0").set_vis(2)
	if Save.bool_of("panties"):
		Save.put("panties", false)
		L("use_panties")
		room_refresh()
		return
	for p in plants: p.raid()
	Comix.new(self, "comix_police", "police", [["comix_police_0", "t", 1600.0, 0.0, 1000.0, 1000.0], ["comix_police_1", "t", 1600.0, 0.0, 1000.0, 1500.0], ["comix_police_car", "t", -1600.0, 0.0, 500.0, 2000.0], ["comix_police_2", "t", 1600.0, 0.0, 500.0, 3000.0]], [], "")
func abduction() -> void:
	if Save.bool_of("painting"):
		Save.put("painting", false)
		room_refresh()
		return
	var lost := mini(xp(), randi() % 100)
	Save.put("xp", xp() - lost)
	hud()
	Comix.new(self, "comix_abduction", "abduction", [["comix_alien_0", "a", 0.0, 1.0, 1000.0, 800.0], ["comix_alien_1", "a", 0.0, 1.0, 1000.0, 2800.0], ["comix_alien_2", "a", 0.0, 1.0, 500.0, 5800.0]], ["", "", ""] if lost == 0 else ["-%d xp" % lost, "", ""], "alien")
func zombie_attack() -> void:
	for p in plants:
		if p.state > -2:
			p.raid()
			break
	Comix.new(self, "comix_zombie", "zombie_trick", [["comix_zombie_0", "a", 0.0, 1.0, 1000.0, 800.0], ["comix_zombie_1", "a", 0.0, 1.0, 1000.0, 2800.0]], [], "")
func open_warp() -> void: pass
func open_dealer() -> void:
	Save.put("dealer_visits", 0)
	var ph := ui.view("phone")
	ph.stop_anim()
	Anim.stop(ph)
	Sfx.play("phone_take")
	DealerDlg.new(self)
func magic_joint() -> void:
	var lv: Array = ldata()
	Sfx.play("magic")
	var joint := ui.view("mj_joint")
	var smoke := ui.view("mj_smoke")
	joint.set_vis(0)
	smoke.set_vis(0)
	ui.view("mj_hint_text").set_text(Assets.str_of(lv[2]))
	var ic: String = lv[3]
	ui.view("mj_hint_img").set_src(Assets.drawable("@drawable/" + ic) if ic != "" else {})
	var tile := ui.view("mj_smoke_tile")
	var h: float = size.y
	tile.lh = h * 2.0
	tile.mg[3] = -h
	tile._relayout()
	var tw := create_tween().set_loops()
	tw.tween_property(tile, "position:y", -h, 7.0).from(0.0)
	Anim.play(joint, "mj_joint_in")
	Anim.play(ui.view("mj_charcoal"), "mj_charcoal", Callable(), -1)
	Sfx.play("charcoal")
	Anim.play(smoke, "mj_smoke_in")
	Anim.play(ui.view("mj_text"), "mj_text")
	Anim.play(ui.view("mj_smoke_bg"), "mj_smoke_bg")
	Anim.play(ui.view("mj_flash"), "mj_flash")
	var tap := ui.view("mj_tap_here")
	Anim.play(ui.view("mj_hint"), "mj_hint_in", func():
		tap.set_vis(0)
		joint.on(func(_v):
			joint.off()
			tap.set_vis(2)
			tw.kill()
			Anim.stop(ui.view("mj_charcoal"))
			Anim.play(joint, "mj_joint_out", func(): joint.set_vis(2))
			Anim.play(ui.view("mj_hint"), "mj_hint_out")
			Anim.play(smoke, "mj_smoke_out", func():
				smoke.set_vis(2)
				door_schedule())
			hud()
			tasks_refresh()))
