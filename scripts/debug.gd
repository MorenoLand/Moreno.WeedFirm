class_name DebugMenu
extends CanvasLayer
const ITEMS := ["player", "box", "safe", "bong", "vaporizer", "sofa", "panties", "shotgun", "painting", "phone"]
const CUSTOMS := ["customize_0", "customize_1", "customize_2", "customize_3"]
var g: Node
var info: Label
var who: OptionButton
var lvl: SpinBox
var boxes := {}
var shown := false
func _init(game: Node) -> void:
	g = game
	layer = 100
	visible = false
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -520.0
	panel.offset_right = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.97)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 14.0
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size.x = 480.0
	sc.add_child(vb)
	info = Label.new()
	vb.add_child(info)
	head(vb, "Resources")
	var gr := grid(vb)
	btn(gr, "+1k cash", func(): g.m(0, 1000, 0))
	btn(gr, "+100k cash", func(): g.m(0, 100000, 0))
	btn(gr, "+100 weed", func(): g.m(0, 0, 100))
	btn(gr, "+10k weed", func(): g.m(0, 0, 10000))
	btn(gr, "+XP (half level)", func(): g.m(maxi(int(g.ldata()[1]) / 2, 1), 0, 0))
	btn(gr, "Complete level (overlay)", complete_level)
	btn(gr, "Zero cash and weed", func():
		Save.put("cash", 0)
		Save.put("weed", 0))
	btn(gr, "Clear desk piles", func():
		Save.put("desk_cash", 0)
		Save.put("desk_weed", 0))
	btn(gr, "Desk +500 cash +40 weed", func(): g.m(0, 500, 40))
	var lr := HBoxContainer.new()
	vb.add_child(lr)
	lvl = SpinBox.new()
	lvl.min_value = 0
	lvl.max_value = 17
	lr.add_child(lvl)
	btn(lr, "Set level (xp 0)", func():
		Save.put("level", int(lvl.value))
		Save.put("xp", 0)
		for k in ["current_task1", "current_task2"]: Save.remove(k))
	head(vb, "Owned items")
	var ig := GridContainer.new()
	ig.columns = 2
	vb.add_child(ig)
	for it in ITEMS + CUSTOMS:
		var cb := CheckBox.new()
		cb.text = it
		cb.toggled.connect(func(on: bool):
			Save.put(it, on)
			if it == "customize_2" and on: Save.put("customize_3", false)
			if it == "customize_3" and on: Save.put("customize_2", false)
			g.room_refresh()
			sync())
		boxes[it] = cb
		ig.add_child(cb)
	head(vb, "Supplies")
	gr = grid(vb)
	btn(gr, "+5 watering / seeds / fertilizer", func():
		for list in [Data.WATERING, Data.SEEDS, Data.FERTS]:
			for e in list: Save.put(e[0], Save.int_of(e[0]) + 5)
		g.watering_buttons())
	btn(gr, "+5 vinyls (and box)", func():
		Save.put("box", true)
		for e in Data.VINYL: Save.put(e[0], Save.int_of(e[0]) + 5))
	btn(gr, "Buy all pots (empty slots)", func():
		for i in g.plants.size():
			var p: Plant = g.plants[i]
			if p.state < -1:
				p.set_pot(0)
				p.set_state(-1, Save.now()))
	btn(gr, "Open shop", func(): g.open_shop(""))
	head(vb, "Plants")
	gr = grid(vb)
	btn(gr, "Water all", func():
		for p in g.plants:
			if p.state >= 1 and p.state <= 7: p.set_water(10, Save.now()); p.tick())
	btn(gr, "Grow all to harvest", func():
		for p in g.plants:
			if p.state >= 1:
				p.set_state(8, Save.now())
				p.set_water(10, Save.now())
				p.tick())
	btn(gr, "Age all +1 stage", func():
		for p in g.plants:
			if p.state >= 1 and p.state < 8:
				p.set_state(p.state + 1, Save.now())
				p.tick())
	btn(gr, "Empty all plants", func():
		for p in g.plants: p.raid())
	head(vb, "Door visits")
	who = OptionButton.new()
	for c in Data.CLIENTS: who.add_item(c)
	vb.add_child(who)
	gr = grid(vb)
	btn(gr, "Spawn at door", func(): spawn(false))
	btn(gr, "Spawn at door (replace)", func(): spawn(true))
	btn(gr, "Open dialog now", func():
		close()
		g.open_client(Data.CLIENTS[who.selected]))
	btn(gr, "Clear the door", func():
		for i in 3: if g.door_client(i) != "": g.door_clear(i))
	btn(gr, "Fast-forward visit counters", func():
		Save.put("client_visits", Save.int_of("client_visits") + 50))
	btn(gr, "Flag all clients rolled/bong/vape", func():
		for c in Data.CLIENTS:
			Save.put(c, true)
			Save.put("bong" + c, true)
			Save.put("vaporizer" + c, true)
		g.tasks_refresh())
	head(vb, "Events")
	gr = grid(vb)
	btn(gr, "Burglary", func(): after_close(g.burglary))
	btn(gr, "Police raid", func(): after_close(g.raid))
	btn(gr, "Alien abduction", func(): after_close(g.abduction))
	btn(gr, "Zombie attack", func(): after_close(g.zombie_attack))
	btn(gr, "Dealer call", func(): after_close(g.open_dealer))
	btn(gr, "Daily bonus popup", func(): after_close(func(): g.popup_item("daily_bonus")))
	btn(gr, "Christmas gift popup", func(): after_close(func(): g.popup_item("christmas_bonus")))
	btn(gr, "Valentine gift popup", func(): after_close(func(): g.popup_item("valentine_bonus")))
	btn(gr, "Intro comic", func(): after_close(func(): IntroDlg.new(g, Callable())))
	btn(gr, "Pause menu", func(): after_close(g.show_pause))
	btn(gr, "Achievements list", func(): after_close(g.show_achievements))
	btn(gr, "Unlock all achievements", func():
		for a in Data.ACH: Save.put("ach_" + a[0], int(a[3])))
	btn(gr, "Phone rings now", func():
		Save.put("dealer_visits", 56)
		g.phone_tick())
	head(vb, "Tasks")
	gr = grid(vb)
	btn(gr, "Complete current tasks", func():
		for t in [g.task_a, g.task_b]: if t != "none": g.L(t))
	btn(gr, "Reset all task progress", func():
		for t in Data.TASKS: Save.remove("task_" + t[0])
		for k in ["current_task1", "current_task2"]: Save.remove(k)
		g.tasks_refresh())
	btn(gr, "Reset tutorial hints", func():
		for k in ["tutorial_slide", "tutorial_water", "tutorial_cut", "tutorial_fertilize", "tutorial_remove", "tutorial_safe", "tutorial_box"]: Save.remove(k))
	head(vb, "Save")
	gr = grid(vb)
	btn(gr, "Flush save now", func(): Save.flush())
	btn(gr, "Close", close)
func head(p: Control, t: String) -> void:
	var l := Label.new()
	l.text = "-- " + t
	p.add_child(HSeparator.new())
	p.add_child(l)
func grid(p: Control) -> GridContainer:
	var gc := GridContainer.new()
	gc.columns = 2
	gc.add_theme_constant_override("h_separation", 4)
	p.add_child(gc)
	return gc
func btn(p: Control, t: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func():
		cb.call()
		sync())
	p.add_child(b)
func spawn(replace: bool) -> void:
	var c: String = Data.CLIENTS[who.selected]
	var slot := -1
	for i in 3:
		if g.door_client(i) == c: return
		if slot < 0 and g.door_client(i) == "": slot = i
	if slot < 0:
		if not replace: return
		slot = 0
	Save.put("client_%d" % slot, c)
	Sfx.play("knock_medium")
	g.door_show(slot, c, true)
func complete_level() -> void:
	Save.put("xp", int(g.ldata()[1]))
	close()
	g.level_check()
func after_close(cb: Callable) -> void:
	close()
	cb.call()
func sync() -> void:
	g.hud()
	g.desk()
	g.room_refresh()
	g.tasks_refresh()
	g.watering_buttons()
	info.text = "level %d  xp %d/%d  cash %d  weed %d\nvisits %d  tasks %s, %s" % [g.level(), g.xp(), g.ldata()[1], g.cash(), g.weed_amt(), Save.int_of("client_visits"), g.task_a, g.task_b]
	for it in boxes: boxes[it].set_pressed_no_signal(Save.bool_of(it))
	lvl.set_value_no_signal(g.level())
func toggle() -> void:
	if shown: close()
	else: open()
func open() -> void:
	if shown: return
	shown = true
	visible = true
	g.modal += 1
	g.door_cancel()
	g.phone_timer.stop()
	sync()
func close() -> void:
	if not shown: return
	shown = false
	visible = false
	g.modal = maxi(g.modal - 1, 0)
	if g.modal == 0:
		g.door_schedule()
		g.phone_schedule()
