class_name AView
extends Container
signal clicked(view)
const MATCH := -1.0
const WRAP := -2.0
const BIG := 100000.0
const GROUPS := ["FrameLayout", "LinearLayout", "RelativeLayout", "AbsoluteLayout", "ScrollView", "HorizontalScrollView", "ListView", "WeedItem", "RoomScrollView", "WeedScrollView", "TabHost", "TabWidget"]
const FONTS := {"TextViewNormal": "gilsanub", "TextButton": "gilsanub", "TextViewChalk": "chalkduster", "TextViewScript": "spacecow", "TextViewHint": "tweed", "TextViewRoboto": "roboto"}
var kind := "View"
var a := {}
var ui: RefCounted
var vis := 0
var lw := WRAP
var lh := WRAP
var mg := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var pd := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var gravity := 0
var lgrav := 0
var weight := 0.0
var xy := Vector2.ZERO
var bg: Dictionary = {}
var src: Dictionary = {}
var text := ""
var tsize := 14.0 * Assets.DP
var tcolor := Color.WHITE
var shadow := Color(0, 0, 0, 0)
var shadow_off := Vector2.ZERO
var font_name := ""
var pressed := false
var enabled := true
var clickable := false
var scroll := Vector2.ZERO
var scroll_max := Vector2.ZERO
var comp := {}
var comp_pad := 0.0
var frame := 0
var tint := Color.WHITE
var progress := 0
var pmax := 100
var sel_override := {}
var strike := false
var _sb := {}
var _anim_t := 0.0
var _anim_run := false
func setup(k: String, attrs: Dictionary, ctx: RefCounted) -> void:
	kind = k
	a = attrs
	ui = ctx
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vis = int(a.get("visibility", 0))
	lw = _spec(a.get("layout_width", WRAP))
	lh = _spec(a.get("layout_height", WRAP))
	var mm := _dp(a.get("layout_margin", 0))
	mg = PackedFloat32Array([_dp(a.get("layout_marginLeft", mm)), _dp(a.get("layout_marginTop", mm)), _dp(a.get("layout_marginRight", mm)), _dp(a.get("layout_marginBottom", mm))])
	var pp := _dp(a.get("padding", 0))
	pd = PackedFloat32Array([_dp(a.get("paddingLeft", pp)), _dp(a.get("paddingTop", pp)), _dp(a.get("paddingRight", pp)), _dp(a.get("paddingBottom", pp))])
	bg = Assets.drawable(a.get("background"))
	var np := _nine_rec(bg)
	if not np.is_empty() and np["nine"] != null:
		var pad: Array = np["nine"]["pad"]
		var sc: float = np["scale"]
		var keys := ["paddingLeft", "paddingTop", "paddingRight", "paddingBottom"]
		var src_i := [0, 2, 1, 3]
		for i in 4:
			if not a.has(keys[i]) and not a.has("padding"): pd[i] = float(pad[src_i[i]]) * sc
	gravity = int(a.get("gravity", 0))
	lgrav = int(a.get("layout_gravity", 0))
	weight = float(a.get("layout_weight", 0))
	xy = Vector2(_dp(a.get("layout_x", 0)), _dp(a.get("layout_y", 0)))
	bg = Assets.drawable(a.get("background"))
	src = Assets.drawable(a.get("src"))
	text = str(Assets.resolve(a.get("text", "")))
	tsize = _dp(a.get("textSize", "14sp"))
	tcolor = Assets.color(str(a.get("textColor", "#ffffffff")))
	shadow = Assets.color(str(a.get("shadowColor", "#00000000")))
	shadow_off = Vector2(float(a.get("shadowDx", 0)), float(a.get("shadowDy", 0)))
	font_name = FONTS.get(k, "")
	clickable = a.has("onClick") or bool(a.get("clickable", false))
	for side in ["Top", "Left", "Right", "Bottom"]:
		if a.has("drawable" + side): comp[side] = Assets.drawable(a["drawable" + side])
	comp_pad = _dp(a.get("drawablePadding", 0))
	pmax = int(a.get("max", 100))
	clip_contents = is_group()
	if clickable or kind.ends_with("ScrollView") or kind == "ListView" or kind == "SeekBar": mouse_filter = Control.MOUSE_FILTER_PASS
	if a.has("tint"): tint = Assets.color(str(a["tint"]))
	visible = vis == 0
	if bg.get("kind") == "anim" or src.get("kind") == "anim": set_process(true)
	else: set_process(false)
func _nine_rec(d: Dictionary) -> Dictionary:
	match d.get("kind", ""):
		"image": return d["rec"]
		"selector":
			for it in d["items"]:
				var r := _nine_rec(it["d"])
				if not r.is_empty(): return r
	return {}
func _spec(v: Variant) -> float:
	if v is String: return _dp(v)
	var f := float(v)
	return f if f < 0.0 else f * Assets.DP
func _dp(v: Variant) -> float: return Assets.dp(v)
func is_group() -> bool: return kind in GROUPS
func is_text() -> bool: return kind.begins_with("Text") or kind == "Button" or kind == "CheckBox"
func gone() -> bool: return vis == 2
func set_vis(v: int) -> void:
	vis = v
	visible = v == 0
	_relayout()
func on(cb: Callable) -> void:
	set_meta("cb", cb)
	clickable = true
	mouse_filter = Control.MOUSE_FILTER_PASS
func off() -> void:
	if has_meta("cb"): remove_meta("cb")
	clickable = a.has("onClick")
	mouse_filter = Control.MOUSE_FILTER_PASS if clickable else Control.MOUSE_FILTER_IGNORE
func set_h(px: float) -> void:
	lh = px
	_relayout()
func set_w(px: float) -> void:
	lw = px
	_relayout()
func set_tint(c: Color) -> void:
	tint = c
	queue_redraw()
func set_text(t: String) -> void:
	text = t
	_relayout()
	queue_redraw()
func set_bg(d: Dictionary) -> void:
	bg = d
	set_process(bg.get("kind") == "anim" or src.get("kind") == "anim")
	queue_redraw()
func set_src(d: Dictionary) -> void:
	src = d
	set_process(bg.get("kind") == "anim" or src.get("kind") == "anim")
	_relayout()
	queue_redraw()
func set_enabled(e: bool) -> void:
	enabled = e
	queue_redraw()
func _relayout() -> void:
	var p: Node = self
	while p is AView and p.get_parent() is AView: p = p.get_parent()
	if p is AView: p._sort_all()
func _sort_all() -> void:
	queue_sort()
	for c in get_children():
		if c is AView: c._sort_all()
func kids() -> Array:
	var r := []
	for c in get_children():
		if c is AView and not c.gone(): r.append(c)
	return r
func _get_minimum_size() -> Vector2: return Vector2.ZERO
func font() -> Font:
	var f: Font = Assets.font(font_name) if font_name != "" else null
	return f if f != null else ThemeDB.fallback_font
func img_size(d: Dictionary) -> Vector2:
	match d.get("kind", ""):
		"image":
			var r: Dictionary = d["rec"]
			return r["tex"].get_size() * float(r["scale"])
		"selector":
			for it in d["items"]:
				var s := img_size(it["d"])
				if s != Vector2.ZERO: return s
		"anim":
			if d["frames"].size() > 0: return img_size(d["frames"][0]["d"])
		"layers":
			var m := Vector2.ZERO
			for it in d["items"]: m = m.max(img_size(it))
			return m
	return Vector2.ZERO
func text_size(lw_: float) -> Vector2:
	if text == "": return Vector2.ZERO
	var f := font()
	var one: bool = bool(a.get("singleLine", false))
	var s := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0 if one or lw_ <= 0.0 else lw_, int(tsize))
	return s
func comp_size(side: String) -> Vector2: return img_size(comp[side]) if comp.has(side) else Vector2.ZERO
func wrap_size(aw: float, ah: float) -> Vector2:
	var iw: float = max(aw - pd[0] - pd[2], 0.0)
	var ih: float = max(ah - pd[1] - pd[3], 0.0)
	var s := Vector2.ZERO
	if is_group():
		s = _group_wrap(iw, ih)
		if kind.ends_with("ScrollView") or kind == "ListView": s = s.min(Vector2(iw, ih))
	elif kind == "ImageView" or kind == "ImageButton": s = img_size(src)
	elif is_text():
		var cl := comp_size("Left").x + comp_size("Right").x
		var ct := comp_size("Top")
		var cb := comp_size("Bottom")
		var ts := text_size(iw - cl - (comp_pad if cl > 0.0 else 0.0))
		s = Vector2(max(ts.x + cl + (comp_pad if cl > 0.0 and text != "" else 0.0), max(ct.x, cb.x)), max(ts.y, comp_size("Left").y) + ct.y + cb.y + (comp_pad if ct.y > 0.0 and text != "" else 0.0))
	elif kind == "SeekBar": s = Vector2(iw, 40.0 * Assets.DP)
	s += Vector2(pd[0] + pd[2], pd[1] + pd[3])
	var bsz := img_size(bg)
	var mw: float = max(_dp(a.get("minWidth", 0)), bsz.x)
	var mh: float = max(_dp(a.get("minHeight", 0)), bsz.y)
	return Vector2(max(s.x, mw), max(s.y, mh))
func child_size(c: AView, aw: float, ah: float) -> Vector2:
	var mw: float = aw - c.mg[0] - c.mg[2]
	var mh: float = ah - c.mg[1] - c.mg[3]
	var w: float = c.lw
	var h: float = c.lh
	var s := Vector2(w, h)
	if w == WRAP or h == WRAP:
		var ws := c.wrap_size(mw if w < 0.0 else w, mh if h < 0.0 else h)
		if w == WRAP: s.x = ws.x
		if h == WRAP: s.y = ws.y
	if w == MATCH: s.x = mw
	if h == MATCH: s.y = mh
	return s
func _group_wrap(iw: float, ih: float) -> Vector2:
	var m := Vector2.ZERO
	match kind:
		"LinearLayout":
			var vert := int(a.get("orientation", 0)) == 1
			for c in kids():
				var cs := child_size(c, iw, ih)
				var o := cs + Vector2(c.mg[0] + c.mg[2], c.mg[1] + c.mg[3])
				if vert: m = Vector2(max(m.x, o.x), m.y + o.y)
				else: m = Vector2(m.x + o.x, max(m.y, o.y))
		"AbsoluteLayout":
			for c in kids():
				var cs := child_size(c, iw, ih)
				m = m.max(c.xy + cs)
		"RelativeLayout":
			var rr := _rel(iw, ih)
			for c in kids():
				m = m.max(rr[c].end)
		"ScrollView", "ListView":
			for c in kids():
				var cs := child_size(c, iw, BIG)
				m = m.max(cs + Vector2(c.mg[0] + c.mg[2], c.mg[1] + c.mg[3]))
		"HorizontalScrollView", "RoomScrollView", "WeedScrollView":
			for c in kids():
				var cs := child_size(c, BIG, ih)
				m = m.max(cs + Vector2(c.mg[0] + c.mg[2], c.mg[1] + c.mg[3]))
		_:
			for c in kids():
				var cs := child_size(c, iw, ih)
				m = m.max(cs + Vector2(c.mg[0] + c.mg[2], c.mg[1] + c.mg[3]))
	return m
func ref_view(v: Variant) -> AView:
	if v is String and v.begins_with("@id/"): return ui.ids.get(v.substr(4))
	return null
func _rel(iw: float, ih: float) -> Dictionary:
	var out := {}
	var todo := kids()
	for _p in range(todo.size() + 1):
		var left := []
		for c in todo:
			var deps := true
			for k in ["layout_toRightOf", "layout_toLeftOf", "layout_above", "layout_below"]:
				var r := ref_view(c.a.get(k))
				if r != null and r.get_parent() == self and not r.gone() and not out.has(r): deps = false
			if not deps:
				left.append(c)
				continue
			var s := child_size(c, iw, ih)
			var ow: float = s.x + c.mg[0] + c.mg[2]
			var oh: float = s.y + c.mg[1] + c.mg[3]
			var lo_x = null
			var hi_x = null
			var lo_y = null
			var hi_y = null
			if c.a.get("layout_alignParentLeft", false): lo_x = 0.0
			if c.a.get("layout_alignParentRight", false): hi_x = iw
			if c.a.get("layout_alignParentTop", false): lo_y = 0.0
			if c.a.get("layout_alignParentBottom", false): hi_y = ih
			var r1 := ref_view(c.a.get("layout_toRightOf"))
			if r1 != null and out.has(r1): lo_x = out[r1].end.x
			var r2 := ref_view(c.a.get("layout_toLeftOf"))
			if r2 != null and out.has(r2): hi_x = out[r2].position.x
			var r3 := ref_view(c.a.get("layout_below"))
			if r3 != null and out.has(r3): lo_y = out[r3].end.y
			var r4 := ref_view(c.a.get("layout_above"))
			if r4 != null and out.has(r4): hi_y = out[r4].position.y
			var cin: bool = c.a.get("layout_centerInParent", false)
			var chz: bool = cin or c.a.get("layout_centerHorizontal", false)
			var cvt: bool = cin or c.a.get("layout_centerVertical", false)
			if c.lw == MATCH: s.x = (hi_x if hi_x != null else iw) - (lo_x if lo_x != null else 0.0) - c.mg[0] - c.mg[2]; ow = s.x + c.mg[0] + c.mg[2]
			if c.lh == MATCH: s.y = (hi_y if hi_y != null else ih) - (lo_y if lo_y != null else 0.0) - c.mg[1] - c.mg[3]; oh = s.y + c.mg[1] + c.mg[3]
			var x := 0.0
			var y := 0.0
			if chz: x = (iw - ow) * 0.5
			elif lo_x != null: x = lo_x
			elif hi_x != null: x = hi_x - ow
			if cvt: y = (ih - oh) * 0.5
			elif lo_y != null: y = lo_y
			elif hi_y != null: y = hi_y - oh
			out[c] = Rect2(x, y, ow, oh)
		todo = left
		if todo.is_empty(): break
	for c in todo: out[c] = Rect2(0, 0, 0, 0)
	return out
func place(c: AView, cell: Rect2, s: Vector2, g: int) -> void:
	var h := g & 7
	var v := g & 0x70
	var x: float = cell.position.x + c.mg[0]
	var y: float = cell.position.y + c.mg[1]
	var aw: float = cell.size.x - c.mg[0] - c.mg[2]
	var ah: float = cell.size.y - c.mg[1] - c.mg[3]
	if h == 5: x += aw - s.x
	elif h == 1: x += (aw - s.x) * 0.5
	if v == 0x50: y += ah - s.y
	elif v == 0x10: y += (ah - s.y) * 0.5
	c.position = Vector2(x, y).round()
	c.size = s.round()
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN: do_layout()
func do_layout() -> void:
	var iw: float = size.x - pd[0] - pd[2]
	var ih: float = size.y - pd[1] - pd[3]
	var org := Vector2(pd[0], pd[1])
	var ks := kids()
	match kind:
		"AbsoluteLayout":
			for c in ks:
				var s := child_size(c, iw, ih)
				c.position = (org + c.xy + Vector2(c.mg[0], c.mg[1])).round()
				c.size = s.round()
		"RelativeLayout":
			var rr := _rel(iw, ih)
			for c in ks:
				var r: Rect2 = rr[c]
				var s := Vector2(r.size.x - c.mg[0] - c.mg[2], r.size.y - c.mg[1] - c.mg[3])
				c.position = (org + r.position + Vector2(c.mg[0], c.mg[1])).round()
				c.size = s.round()
		"LinearLayout": _linear(ks, org, iw, ih)
		"ScrollView", "ListView", "HorizontalScrollView", "RoomScrollView", "WeedScrollView":
			var horiz := kind.begins_with("Horizontal") or kind == "RoomScrollView" or kind == "WeedScrollView"
			var cm := Vector2.ZERO
			for c in ks:
				var s := child_size(c, BIG if horiz else iw, ih if horiz else BIG)
				if horiz and c.lh == MATCH: s.y = ih - c.mg[1] - c.mg[3]
				if not horiz and c.lw == MATCH: s.x = iw - c.mg[0] - c.mg[2]
				cm = cm.max(s + Vector2(c.mg[0] + c.mg[2], c.mg[1] + c.mg[3]))
				var cell := Rect2(Vector2.ZERO, Vector2(max(s.x + c.mg[0] + c.mg[2], iw), max(s.y + c.mg[1] + c.mg[3], ih)))
				place(c, cell, s, c.lgrav)
				c.position = c.position + org - scroll
			scroll_max = Vector2(max(cm.x - iw, 0.0), max(cm.y - ih, 0.0))
		_:
			for c in ks:
				var s := child_size(c, iw, ih)
				place(c, Rect2(org, Vector2(iw, ih)), s, c.lgrav)
func set_scroll(v: Vector2) -> void:
	scroll = Vector2(clamp(v.x, 0.0, scroll_max.x), clamp(v.y, 0.0, scroll_max.y))
	queue_sort()
func _linear(ks: Array, org: Vector2, iw: float, ih: float) -> void:
	var vert := int(a.get("orientation", 0)) == 1
	var sizes := {}
	var used := 0.0
	var wsum := 0.0
	for c in ks:
		var s := child_size(c, iw, ih)
		if c.weight > 0.0:
			wsum += c.weight
			if (vert and c.lh == 0.0) or (not vert and c.lw == 0.0): if vert: s.y = 0.0
			if (not vert and c.lw == 0.0): s.x = 0.0
		sizes[c] = s
		used += (s.y + c.mg[1] + c.mg[3]) if vert else (s.x + c.mg[0] + c.mg[2])
	var total: float = ih if vert else iw
	var rem: float = total - used
	var ws: float = float(a.get("weightSum", wsum))
	if ws <= 0.0: ws = wsum
	if wsum > 0.0:
		for c in ks:
			if c.weight > 0.0:
				if vert: sizes[c].y = max(sizes[c].y + rem * c.weight / ws, 0.0)
				else: sizes[c].x = max(sizes[c].x + rem * c.weight / ws, 0.0)
		used = total
	var pos := 0.0
	var g := gravity
	if vert:
		if (g & 0x70) == 0x50: pos = total - used
		elif (g & 0x70) == 0x10: pos = (total - used) * 0.5
	else:
		if (g & 7) == 5: pos = total - used
		elif (g & 7) == 1: pos = (total - used) * 0.5
	for c in ks:
		var s: Vector2 = sizes[c]
		if vert:
			if c.lw == MATCH: s.x = iw - c.mg[0] - c.mg[2]
			var cg: int = c.lgrav if c.lgrav != 0 else (g & 7)
			var cell := Rect2(org + Vector2(0, pos), Vector2(iw, s.y + c.mg[1] + c.mg[3]))
			place(c, cell, s, cg & 7)
			pos += s.y + c.mg[1] + c.mg[3]
		else:
			if c.lh == MATCH: s.y = ih - c.mg[1] - c.mg[3]
			var cg2: int = c.lgrav if c.lgrav != 0 else (g & 0x70)
			var cell2 := Rect2(org + Vector2(pos, 0), Vector2(s.x + c.mg[0] + c.mg[2], ih))
			place(c, cell2, s, cg2 & 0x70)
			pos += s.x + c.mg[0] + c.mg[2]
func _state_match(st: Dictionary) -> bool:
	for k in st:
		if k == "drawable": continue
		var want: bool = bool(st[k])
		var have := false
		match k:
			"state_pressed": have = pressed
			"state_enabled": have = enabled
			"state_selected": have = sel_override.get("selected", false)
			"state_checked": have = sel_override.get("checked", false)
			"state_focused": have = false
			_: have = false
		if have != want: return false
	return true
func draw_d(d: Dictionary, r: Rect2, fit := 1) -> void:
	match d.get("kind", ""):
		"color": draw_rect(r, d["color"])
		"shape":
			var rad: Array = d["radii"]
			if d["grad"]:
				var a_: float = d["angle"]
				var top: Color = d["end"] if int(a_) == 90 else d["color"]
				var bot: Color = d["color"] if int(a_) == 90 else d["end"]
				if int(a_) == 0 or int(a_) == 180:
					var lft: Color = d["color"] if int(a_) == 0 else d["end"]
					var rgt: Color = d["end"] if int(a_) == 0 else d["color"]
					draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([lft, rgt, rgt, lft]))
				else:
					draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([top, top, bot, bot]))
			else:
				var sb := StyleBoxFlat.new()
				sb.bg_color = d["color"]
				sb.corner_radius_top_left = int(rad[0])
				sb.corner_radius_top_right = int(rad[1])
				sb.corner_radius_bottom_right = int(rad[2])
				sb.corner_radius_bottom_left = int(rad[3])
				draw_style_box(sb, r)
		"selector":
			for it in d["items"]:
				if _state_match(it["state"]):
					draw_d(it["d"], r, fit)
					return
		"layers":
			for it in d["items"]: draw_d(it, r, fit)
		"anim":
			if d["frames"].size() > 0: draw_d(d["frames"][frame % d["frames"].size()]["d"], r, fit)
		"image":
			var rec: Dictionary = d["rec"]
			var t: Texture2D = rec["tex"]
			var mod: Color = tint * (Color.WHITE if enabled else Color(0.6, 0.6, 0.6, 1))
			if rec["nine"] != null and fit == 1:
				var n: Dictionary = rec["nine"]
				var xs: Array = n["x"]
				var ys: Array = n["y"]
				if xs.size() >= 2 and ys.size() >= 2:
					var sc: float = rec["scale"]
					var sb2 := StyleBoxTexture.new()
					sb2.texture = t
					sb2.texture_margin_left = xs[0]
					sb2.texture_margin_right = n["w"] - xs[xs.size() - 1] - 0.0
					sb2.texture_margin_top = ys[0]
					sb2.texture_margin_bottom = n["h"] - ys[ys.size() - 1]
					sb2.modulate_color = mod
					draw_set_transform(r.position, 0.0, Vector2(sc, sc))
					draw_style_box(sb2, Rect2(Vector2.ZERO, r.size / sc))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
					return
			var ts: Vector2 = t.get_size() * float(rec["scale"])
			match fit:
				1: draw_texture_rect(t, r, false, mod)
				3:
					var k: float = min(r.size.x / ts.x, r.size.y / ts.y)
					var sz: Vector2 = ts * k
					draw_texture_rect(t, Rect2(r.position + (r.size - sz) * 0.5, sz), false, mod)
				6:
					var k2: float = max(r.size.x / ts.x, r.size.y / ts.y)
					var sz2: Vector2 = ts * k2
					draw_texture_rect(t, Rect2(r.position + (r.size - sz2) * 0.5, sz2), false, mod)
				_: draw_texture_rect(t, Rect2(r.position + (r.size - ts) * 0.5, ts), false, mod)
func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if not bg.is_empty(): draw_d(bg, r)
	if kind == "ImageView" or kind == "ImageButton":
		var st := int(a.get("scaleType", 3 if kind == "ImageView" else 5))
		var inner := Rect2(Vector2(pd[0], pd[1]), size - Vector2(pd[0] + pd[2], pd[1] + pd[3]))
		var fit := 1 if st == 1 else (6 if st == 6 else (3 if st == 3 or st == 7 else 0))
		draw_d(src, inner, fit)
	elif is_text(): _draw_text()
	elif kind == "SeekBar": _draw_seek()
func _draw_text() -> void:
	var inner := Rect2(Vector2(pd[0], pd[1]), size - Vector2(pd[0] + pd[2], pd[1] + pd[3]))
	var x0 := inner.position.x
	var y0 := inner.position.y
	var cs_t := comp_size("Top")
	if comp.has("Top"):
		var tp := Rect2(Vector2(x0 + (inner.size.x - cs_t.x) * 0.5, y0), cs_t)
		draw_d(comp["Top"], tp, 0)
		y0 += cs_t.y + comp_pad
	var cs_l := comp_size("Left")
	if comp.has("Left"):
		draw_d(comp["Left"], Rect2(Vector2(x0, y0 + (inner.end.y - y0 - cs_l.y) * 0.5), cs_l), 0)
		x0 += cs_l.x + comp_pad
	var cs_r := comp_size("Right")
	var w := inner.end.x - x0 - (cs_r.x + comp_pad if comp.has("Right") else 0.0)
	if comp.has("Right"): draw_d(comp["Right"], Rect2(Vector2(inner.end.x - cs_r.x, y0 + (inner.end.y - y0 - cs_r.y) * 0.5), cs_r), 0)
	if text == "": return
	var f := font()
	var fs := int(tsize)
	var ha := HORIZONTAL_ALIGNMENT_LEFT
	var gh := gravity & 7
	if gh == 1 or gravity == 0x11: ha = HORIZONTAL_ALIGNMENT_CENTER
	elif gh == 5: ha = HORIZONTAL_ALIGNMENT_RIGHT
	if kind == "TextButton" or kind == "Button": ha = HORIZONTAL_ALIGNMENT_CENTER if not a.has("gravity") else ha
	var ts := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, fs)
	var gv := gravity & 0x70
	var ty := y0
	var hh := inner.end.y - y0
	if gv == 0x10 or gravity == 0x11 or ((kind == "TextButton" or kind == "Button") and not a.has("gravity")): ty += (hh - ts.y) * 0.5
	elif gv == 0x50: ty += hh - ts.y
	var asc := f.get_ascent(fs)
	var c := tcolor if enabled else tcolor.darkened(0.4)
	if shadow.a > 0.0: draw_multiline_string(f, Vector2(x0, ty + asc) + shadow_off, text, ha, w, fs, -1, shadow)
	draw_multiline_string(f, Vector2(x0, ty + asc), text, ha, w, fs, -1, c)
	if strike:
		var tp := TextParagraph.new()
		tp.add_string(text, f, fs)
		tp.width = w
		var yy := ty
		for i in tp.get_line_count():
			var ls := tp.get_line_size(i)
			draw_line(Vector2(x0, yy + ls.y * 0.55), Vector2(x0 + ls.x, yy + ls.y * 0.55), c, 3.0)
			yy += ls.y
func _draw_seek() -> void:
	var th := size.y * 0.5
	var x0: float = pd[0]
	var w: float = max(size.x - pd[0] - pd[2], 1.0)
	draw_rect(Rect2(Vector2(x0, th - 4), Vector2(w, 8)), Color(0, 0, 0, 0.4))
	var fr := float(progress) / float(max(pmax, 1))
	draw_rect(Rect2(Vector2(x0, th - 4), Vector2(w * fr, 8)), Color("#6bd13a"))
	var thumb := Assets.drawable(a.get("thumb"))
	var ts := img_size(thumb)
	if ts != Vector2.ZERO: draw_d(thumb, Rect2(Vector2(x0 + w * fr - ts.x * 0.5, th - ts.y * 0.5), ts), 0)
	else: draw_circle(Vector2(x0 + w * fr, th), 14.0, Color.WHITE)
func _process(dt: float) -> void:
	var d: Dictionary = bg if bg.get("kind") == "anim" else src
	if d.get("kind") != "anim" or not _anim_run: return
	_anim_t += dt * 1000.0
	var fr: Array = d["frames"]
	var acc := 0.0
	var idx := 0
	var total := 0.0
	for f in fr: total += float(f["ms"])
	if total <= 0.0: return
	if d.get("oneshot", false) and _anim_t >= total:
		frame = fr.size() - 1
		_anim_run = false
		queue_redraw()
		return
	var t := fmod(_anim_t, total)
	for i in fr.size():
		acc += float(fr[i]["ms"])
		if t < acc:
			idx = i
			break
	if idx != frame:
		frame = idx
		queue_redraw()
func start_anim() -> void:
	_anim_t = 0.0
	_anim_run = true
	frame = 0
	set_process(true)
func stop_anim(reset := true) -> void:
	_anim_run = false
	if reset: frame = 0
	queue_redraw()
func _gui_input(e: InputEvent) -> void:
	if kind == "SeekBar" and enabled:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed or e is InputEventMouseMotion and e.button_mask & 1:
			progress = int(round(clamp((e.position.x - pd[0]) / max(size.x - pd[0] - pd[2], 1.0), 0.0, 1.0) * pmax))
			queue_redraw()
			ui.seek_changed(self)
			accept_event()
		return
	if kind.ends_with("ScrollView") or kind == "ListView":
		_scroll_input(e)
		return
	if not clickable or not enabled: return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			pressed = true
			ui.dragging = false
			queue_redraw()
		else:
			var was := pressed
			pressed = false
			queue_redraw()
			if was and Rect2(Vector2.ZERO, size).has_point(e.position) and not ui.dragging:
				ui.click(self)
				accept_event()
var _dstart := Vector2.ZERO
var _sstart := Vector2.ZERO
var _down := false
func _scroll_input(e: InputEvent) -> void:
	var horiz := kind.begins_with("Horizontal") or kind == "RoomScrollView" or kind == "WeedScrollView"
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var step := (-160.0 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 160.0)
		ui.scrolled(self, scroll + (Vector2(step, 0) if horiz else Vector2(0, step)))
		accept_event()
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_down = e.pressed
		if not e.pressed and kind == "WeedScrollView" and not ui.dragging and ui.handler != null and ui.handler.has_method("forward_click"):
			ui.handler.forward_click(get_global_transform() * e.position)
		if e.pressed:
			_dstart = get_global_mouse_position()
			_sstart = scroll
			ui.dragging = false
	elif e is InputEventMouseMotion and _down:
		if not (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_down = false
			return
		var d := get_global_mouse_position() - _dstart
		if not ui.dragging and d.length() > 12.0: ui.dragging = true
		if ui.dragging: ui.scrolled(self, _sstart - (Vector2(d.x, 0) if horiz else Vector2(0, d.y)))
