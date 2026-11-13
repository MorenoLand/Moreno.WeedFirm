class_name Droid
extends RefCounted
var ids := {}
var _scopes := []
var handler: Object
var dragging := false
var on_scroll := {}
var on_seek := {}
func inflate(name: String, into: AView = null) -> AView:
	var j = Assets.layout(name)
	if not (j is Dictionary) or not j.has("tag"): return null
	return _build(j, into, {})
func style_attrs(ref: String) -> Dictionary:
	var out := {}
	if not ref.begins_with("@style/"): return out
	var s: Dictionary = Assets.styles.get(ref.substr(7), {})
	if s.is_empty(): return out
	out.merge(style_attrs(str(s.get("parent", ""))))
	out.merge(s.get("attrs", {}), true)
	return out
func _build(n: Dictionary, parent: AView, over: Dictionary) -> AView:
	var tag: String = n["tag"].get_slice(".", n["tag"].get_slice_count(".") - 1)
	var at: Dictionary = n["attrs"].duplicate()
	if tag == "include":
		var inc: Variant = Assets.layout(str(at.get("layout", "")).get_slice("/", 1))
		var ov := {}
		for k in at:
			if k != "layout": ov[k] = at[k]
		return _build(inc, parent, ov)
	if tag == "merge":
		for c in n["children"]: _build(c, parent, {})
		return parent
	var merged := style_attrs(str(at.get("style", "")))
	merged.merge(at, true)
	merged.merge(over, true)
	var kind := tag
	if tag == "WeedItem": kind = "RelativeLayout"
	var v := AView.new()
	v.setup(kind, merged, self)
	v.set_meta("type", tag)
	if merged.has("tag"): v.set_meta("tag", str(merged["tag"]))
	if merged.has("id"): (_scopes.back() if not _scopes.is_empty() else ids)[str(merged["id"]).get_slice("/", 1)] = v
	if parent != null: parent.add_child(v)
	if tag == "WeedItem":
		_scopes.append({})
		_build(Assets.layout("weed_item"), v, {})
		v.set_meta("ids", _scopes.pop_back())
	else:
		for c in n["children"]: _build(c, v, {})
	return v
var _dummy: AView
func view(id: String) -> AView:
	if not ids.has(id): return null
	if is_instance_valid(ids[id]): return ids[id]
	if _dummy == null:
		_dummy = AView.new()
		_dummy.setup("View", {}, self)
	return _dummy
func on(id: String, cb: Callable) -> void:
	var v: AView = ids.get(id)
	if v == null: return
	v.set_meta("cb", cb)
	v.clickable = true
	v.mouse_filter = Control.MOUSE_FILTER_PASS
func click(v: AView) -> void:
	if v.has_meta("cb"):
		v.get_meta("cb").call(v)
		return
	var m = v.a.get("onClick")
	if m != null and handler != null and handler.has_method(m): handler.call(m, v)
func scrolled(v: AView, pos: Vector2) -> void:
	v.set_scroll(pos)
	if on_scroll.has(v): on_scroll[v].call(v)
func seek_changed(v: AView) -> void:
	if on_seek.has(v): on_seek[v].call(v)
