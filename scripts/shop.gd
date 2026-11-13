class_name ShopDlg
extends RefCounted
const TAB_IDS := ["tab_1", "tab_2", "tab_3", "tab_4", "tab_5", "tab_6"]
var g: Node
var d: Dictionary
var ui: Droid
var tab := "watering"
var rows := {}
func _init(game: Node, first: String) -> void:
	g = game
	d = g.dialog("shop", false)
	d["w"].set_meta("owner", self)
	ui = d["ui"]
	Sfx.play("bell")
	ui.view("tab_7").set_vis(2)
	ui.view("btn_video").set_vis(2)
	ui.view("google_music").set_vis(2)
	ui.view("btn_rate").set_vis(2)
	ui.view("btn_cash").set_vis(2)
	ui.view("cash").set_vis(2)
	ui.on("btn_back", func(_v):
		Sfx.play("tap")
		close())
	for i in 6:
		var t: String = Data.TABS[i]
		ui.on(TAB_IDS[i], func(_v): select(t))
	for i in 6: build(Data.TABS[i], i + 1)
	ui.view("tab7content").set_vis(2)
	ui.view("cash_value").set_text(str(g.cash()))
	select(first if first != "" else "watering")
func close() -> void:
	g.close_dialog(d)
	g.after_shop()
func select(t: String) -> void:
	Sfx.play("tap") if false else null
	tab = t
	for i in 6:
		var n: String = Data.TABS[i]
		ui.view("tab%dcontent" % (i + 1)).set_vis(0 if n == t else 2)
		var tb := ui.view(TAB_IDS[i])
		tb.sel_override = {"selected": n == t}
		tb.mg[0] = 2.0 * Assets.DP
		tb.mg[2] = 2.0 * Assets.DP
		tb.mg[1] = 0.0 if n == t else (8.0 * Assets.DP if i < 4 else 0.0)
		tb.queue_redraw()
	ui.view("tabs")._sort_all()
func build(t: String, n: int) -> void:
	var lv := ui.view("tab%dlist" % n)
	for c in lv.get_children(): c.queue_free()
	var lin := AView.new()
	lin.setup("LinearLayout", {"layout_width": -1, "layout_height": -2, "orientation": 1}, ui)
	lv.add_child(lin)
	var list: Array = Data.shop_list(t)
	for i in list.size():
		var row := AView.new()
		row.setup("FrameLayout", {"layout_width": -1, "layout_height": -2, "background": "@drawable/shop_item_bg"}, ui)
		lin.add_child(row)
		var inner := Droid.new()
		inner.handler = g
		var content: AView = inner.inflate("shop_item", row)
		rows[list[i][0]] = {"ui": inner, "tab": t, "i": i}
		fill(list, i)
func fill(list: Array, i: int) -> void:
	var it: Array = list[i]
	var inner: Droid = rows[it[0]]["ui"]
	inner.view("pic").set_src(Assets.drawable("@drawable/" + it[0]))
	inner.view("title").set_text(Assets.str_of(it[0] + "_name"))
	inner.view("descr").set_text(Assets.str_of(it[0] + "_descr"))
	var btn := inner.view("button")
	var lvl: int = Data.level_idx(it[2])
	var prev_ok := true
	if i > 0:
		var pv: Array = list[i - 1]
		prev_ok = g.level() >= Data.level_idx(pv[2])
	var id: String = it[0]
	if id.begins_with("vinyl") and not Save.bool_of("box"):
		inner.view("disabled").set_vis(0)
		inner.view("installed").set_vis(2)
		inner.view("level_required").set_vis(2)
		inner.view("level_or_item_required").set_vis(0)
		inner.view("level_or_item_required").set_text(Assets.str_of("vinyl_box_required"))
		btn.set_vis(2)
		return
	if g.level() >= lvl:
		inner.view("disabled").set_vis(2)
		inner.view("level_required").set_vis(2)
		inner.view("level_or_item_required").set_vis(2)
		btn.set_text("%d\nCASH" % it[1])
		btn.on(func(_v): buy(it))
		btn.set_vis(0)
		btn.tsize = 14.0 * Assets.DP
		if id.begins_with("customize"):
			if Save.bool_of(id):
				btn.set_vis(2)
				inner.view("installed").set_vis(0)
			else: inner.view("installed").set_vis(2)
	elif prev_ok:
		inner.view("disabled").set_vis(0)
		inner.view("level_required").set_vis(0)
		inner.view("level_or_item_required").set_vis(2)
		inner.view("level_required").set_text(Assets.str_of("or_wait_level", [lvl]))
		inner.view("installed").set_vis(2)
		btn.set_vis(2)
	else:
		inner.view("disabled").set_vis(0)
		inner.view("level_required").set_vis(2)
		inner.view("level_or_item_required").set_vis(0)
		var pv2: Array = list[i - 1]
		inner.view("level_or_item_required").set_text(Assets.str_of("level_or_item_required", [lvl, Assets.str_of(pv2[0] + "_name")]))
		inner.view("installed").set_vis(2)
		btn.set_vis(2)
func refresh() -> void:
	for t in rows: pass
	for i in 6:
		var list: Array = Data.shop_list(Data.TABS[i])
		for j in list.size(): fill(list, j)
	ui.view("cash_value").set_text(str(g.cash()))
func buy(it: Array) -> void:
	var id: String = it[0]
	if id.begins_with("pots") and g.free_slot() == -1: return
	if (id == "customize_2" or id == "customize_3") and not Save.bool_of("customize_0"):
		g.popup_text("install_floor_first")
		return
	if g.m(0, -it[1], 0):
		Sfx.play("pay")
		g.apply_item(it)
		ui.view("cash_value").set_text(str(g.cash()))
		var bc := ui.view("bonus_cash")
		bc.set_text("-%d cash" % it[1])
		bc.set_vis(0)
		Anim.play(ui.view("bonus_holder"), "bonus", func():
			if is_instance_valid(bc): bc.set_vis(2))
		refresh()
