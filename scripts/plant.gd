class_name Plant
extends RefCounted
var g: Node
var view: AView
var ids: Dictionary
var idx := 0
var state := -3
var state_t := 0
var water := 0
var water_t := 0
var pot := 0
var _timer: Timer
func _init(game: Node, v: AView) -> void:
	g = game
	view = v
	ids = v.get_meta("ids")
	idx = int(v.get_meta("tag"))
	state = Save.int_of("p_state_%d" % idx, -3)
	state_t = Save.int_of("p_state_time_%d" % idx, Save.now())
	water = Save.int_of("p_water_%d" % idx, 0)
	water_t = Save.int_of("p_water_time_%d" % idx, Save.now())
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(tick)
	g.add_child(_timer)
	ids["buy_water_button"].on(func(_v): g.open_shop("watering"))
	ids["buy_seeds_button"].on(func(_v): g.open_shop("seeds"))
	ids["buy_fertilizers_button"].on(func(_v): g.open_shop("fertilizers"))
	ids["sure_button"].on(func(_v): remove_pot())
	ids["not_sure_button"].on(func(_v):
		Save.put("tutorial_remove", true)
		show("no_pot", 2))
	for i in 5: ids["seeds_%d" % i].on(pick_seed.bind(i))
	for i in 4: ids["fertilizer_%d" % i].on(pick_fert.bind(i))
	set_pot(Save.int_of("p_pot_type_%d" % idx, 0))
	tick()
func v(id: String) -> AView: return ids[id]
func show(id: String, vis := 0) -> void: ids[id].set_vis(vis)
func key(p: String) -> String: return "%s_%d" % [p, idx]
func weed_type() -> int: return Save.int_of(key("p_weed_type"), 0)
func fert_type() -> int: return Save.int_of(key("p_fertilizer_type"), -1)
func set_pot(t: int) -> void:
	pot = t
	Save.put(key("p_pot_type"), t)
	v("pot").set_src(Assets.drawable("@drawable/pot_%d" % t))
func hide_menus() -> void:
	for id in ["no_seeds", "seeds_holder", "no_fertilizers", "fertilizers_holder", "no_water", "no_pot", "hint_water", "hint_cut", "hint_remove", "hint_ferts"]: show(id, 2)
func clear_menus() -> void:
	for id in ["no_seeds", "seeds_holder", "no_fertilizers", "fertilizers_holder", "no_pot"]: show(id, 2)
func ground_tint() -> void:
	var c := [Color("#4949d318"), Color("#66f8e8e2"), Color("#662899ad"), Color("#66e0511b")]
	var t := fert_type()
	if t < 0 or t > 3: v("ground").set_tint(Color.WHITE)
	else:
		var col := Color(["#49d318", "#f8e8e2", "#2899ad", "#e0511b"][t])
		v("ground").set_tint(Color.WHITE.lerp(col, 0.4))
func set_state(s: int, t: int) -> void:
	state = mini(s, 8)
	state_t = t
	Save.put(key("p_state"), state)
	Save.put(key("p_state_time"), state_t)
	show("hint_remove", 2)
	for id in ["stool", "pot", "ground", "weed"]: show(id, 0)
	show("water_holder", 2 if pot == 2 else 0)
	show("water_value", 2 if pot == 2 else 0)
	show("info", 0)
	v("pot").on(on_plant)
	v("weed").on(on_plant)
	v("stool").on(func(_v):
		show("no_pot", 0)
		show("no_seeds", 2)
		show("seeds_holder", 2)
		show("hint_remove", 2))
	var wt := weed_type()
	match state:
		-2:
			v("stool").on(func(_v): g.open_shop("pots"))
			for id in ["pot", "ground", "weed"]: show(id, 1)
			show("info", 2)
		-1:
			if g.free_slot() == -1 and not Save.bool_of("tutorial_remove"): show("hint_remove", 0)
			v("pot").on(on_empty_pot)
			show("ground", 1)
			show("weed", 1)
			show("info", 2)
		1, 2, 3, 4, 5, 6, 7, 8:
			v("weed").set_src(Assets.drawable("@drawable/weed_%d_%d" % [wt, state]))
			if state == 8:
				v("pot").on(harvest)
				v("weed").on(harvest)
				if not Save.bool_of("tutorial_cut"): show("hint_cut", 0)
				show("info", 2)
		_:
			for id in ["stool", "pot", "ground", "weed"]: show(id, 1)
			show("info", 2)
	ground_tint()
func set_water(w: int, t: int) -> void:
	water = maxi(w, 0)
	water_t = t
	Save.put(key("p_water"), water)
	Save.put(key("p_water_time"), water_t)
	v("water_level").set_h(water * 2.4 * Assets.DP)
func interval() -> float:
	var f := 1.0
	match fert_type():
		0: f = 2.0
		1: f = 3.0
		2: f = 4.0
		3: f = 6.0
	var base: float = Data.GROW_MS[clampi(weed_type(), 0, 4)]
	if g.level() == 0: base = 5000.0
	return base / f
func tick() -> void:
	var i14 := int(interval())
	var i16 := i14 if pot == 1 else i14 / 2
	var now := Save.now()
	if state < 0 or state > 7 or (water <= 0 and pot != 2):
		set_state(state, state_t)
		set_water(water, water_t)
	else:
		var n := int((now - state_t) / i14)
		set_state(state + n, state_t + n * i14)
		var m := int((now - water_t) / i16)
		set_water(water - m, water_t + m * i16)
		var wait := mini(state_t + i14 - Save.now(), water_t + i16 - Save.now())
		_timer.start(maxf(float(wait) / 1000.0, 0.05))
	v("water_value").set_text("%d%%" % (water * 10))
	var left := (8 - state) * i14
	var s := ""
	if left > 3600000: s = "%d hour" % (left / 3600000)
	elif left > 60000: s = "%d min" % (left / 60000)
	else: s = "%d sec" % (left / 1000)
	v("clock_value").set_text(s)
	if state < 0 or state > 7 or water != 0 or pot == 2:
		show("no_water", 2)
		show("clock_image", 0)
		show("clock_value", 0)
	else:
		if Save.bool_of("tutorial_water"): show("no_water", 0)
		else: show("hint_water", 0)
		show("clock_image", 2)
		show("clock_value", 2)
	if state > 0 and state < 8 and fert_type() == -1 and not Save.bool_of("tutorial_fertilize") and g.has_ferts() and ids["no_fertilizers"].vis == 2 and ids["fertilizers_holder"].vis == 2: show("hint_ferts", 0)
	else: show("hint_ferts", 2)
func on_empty_pot(_v) -> void:
	show("no_pot", 2)
	var any := false
	for i in 5:
		var n := Save.int_of("seeds_%d" % i)
		var b := v("seeds_%d" % i)
		if n > 0:
			b.set_vis(0)
			b.set_text(str(n))
			any = true
		else: b.set_vis(2)
	show("no_seeds", 2 if any else 0)
	show("seeds_holder", 0 if any else 2)
func pick_seed(_v, i: int) -> void:
	Save.put("seeds_%d" % i, Save.int_of("seeds_%d" % i) - 1)
	Save.put(key("p_weed_type"), i)
	if i > 0: g.L("seeds_%d" % i)
	Save.put(key("p_fertilizer_type"), -1)
	show("seeds_holder", 2)
	v("pot").off()
	var pack := v("pack")
	pack.set_src(v("seeds_%d" % i).bg)
	pack.set_vis(0)
	var sd := v("seed")
	sd.set_vis(0)
	sd.start_anim()
	Sfx.play("seeds")
	g.L("seed")
	g.after(1.2, func():
		sd.stop_anim()
		sd.set_vis(2)
		pack.set_vis(2)
		set_state(1, Save.now())
		set_water(water, Save.now())
		tick())
func on_plant(_v) -> void:
	if water < 10 and pot != 2:
		var sel := Save.str_of("selected_watering", "watering_0")
		var cnt := Save.int_of(sel)
		if cnt > 0:
			show("buy_water_button", 2)
			show("no_water", 2)
			if water == 0: state_t = Save.now() - water_t + state_t
			if sel == "watering_0": water += 2
			elif sel == "watering_3": water = 10
			else: water += 5
			water = mini(water, 10)
			water_t = Save.now()
			Save.put(key("p_state_time"), state_t)
			tick()
			set_water(water, water_t)
			var an := "water_1"
			if sel == "watering_0": an = "water_0"
			elif sel == "watering_3": an = "water_3"
			for id in ["water_0", "water_1", "water_3"]: show(id, 2)
			var wv := v(an)
			wv.set_vis(0)
			wv.start_anim()
			g.after(0.6, func():
				wv.stop_anim()
				wv.set_vis(2))
			Sfx.play("watering")
			Save.put(sel, cnt - 1)
			if cnt - 1 == 0:
				for w in Data.WATERING:
					if Save.int_of(w[0]) > 0:
						Save.put("selected_watering", w[0])
						break
			g.watering_buttons()
			Save.put("tutorial_water", true)
			show("hint_water", 2)
		else:
			show("buy_water_button", 0)
			show("no_water", 0)
	elif fert_type() == -1:
		show("hint_ferts", 2)
		var any := false
		for i in 4:
			var n := Save.int_of("fertilizer_%d" % i)
			var b := v("fertilizer_%d" % i)
			if n > 0:
				b.set_vis(0)
				b.set_text(str(n))
				any = true
			else: b.set_vis(2)
		show("no_fertilizers", 2 if any else 0)
		show("fertilizers_holder", 0 if any else 2)
func pick_fert(_v, i: int) -> void:
	Save.put("tutorial_fertilize", true)
	Save.put(key("p_fertilizer_type"), i)
	g.L("fertilizer_%d" % i)
	ground_tint()
	show("fertilizers_holder", 2)
	v("pot").off()
	var bag := v("bag")
	bag.set_src(v("fertilizer_%d" % i).bg)
	bag.set_vis(0)
	var fz := v("fertilize")
	fz.set_vis(0)
	fz.start_anim()
	Sfx.play("fertilize")
	Save.put("fertilizer_%d" % i, Save.int_of("fertilizer_%d" % i) - 1)
	g.after(1.2, func():
		fz.stop_anim()
		fz.set_vis(2)
		bag.set_vis(2)
		set_state(state, state_t)
		tick())
func remove_pot() -> void:
	Save.put("tutorial_remove", true)
	show("no_pot", 2)
	set_state(-2, Save.now())
func harvest(_v) -> void:
	var cut := v("cut")
	cut.set_vis(0)
	cut.start_anim()
	Sfx.play("cut")
	Save.put("tutorial_cut", true)
	show("hint_cut", 2)
	v("pot").off()
	v("weed").off()
	g.after(0.4, func():
		cut.stop_anim()
		cut.set_vis(2)
		set_state(-1, 0)
		set_water(0, 0)
		var amt: int = Data.YIELD[clampi(weed_type(), 0, 4)]
		var xp: int = Sfx.theme_mult() * (3 if Save.bool_of("sofa") else 1)
		g.m(xp, 0, amt)
		g.desk()
		var bw := v("bonus_weed")
		var bx := v("bonus_xp")
		bw.set_text("+%d weed" % amt)
		bw.set_vis(0)
		bx.set_text("+%d xp" % xp)
		bx.set_vis(0)
		Anim.play(v("bonus_holder"), "bonus", func():
			bw.set_vis(2)
			bx.set_vis(2))
		g.L("grow")
		for pair in [[100, "weed_100"], [200, "weed_200"], [500, "weed_500"], [1000, "weed_1000"], [2500, "weed_2500"], [5000, "weed_5000"], [10000, "weed_10000"]]:
			if g.weed_amt() >= pair[0]: g.L(pair[1]))
func raid() -> void:
	if state > -2: set_state(-2, Save.now())
	clear_menus()
