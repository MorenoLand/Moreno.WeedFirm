extends Node
const IDENT := {"t": Vector2.ZERO, "s": Vector2.ONE, "a": 1.0, "r": 0.0}
var _cache := {}
var _act: Array = []
func _flat(n: Dictionary, off: float, interp: String, fa: bool, out: Array) -> void:
	var at: Dictionary = n["attrs"]
	var ip: String = str(at.get("interpolator", interp))
	var o: float = off + float(at.get("startOffset", 0))
	var f: bool = bool(at.get("fillAfter", fa))
	if n["tag"] == "set":
		for c in n["children"]: _flat(c, o, ip, f, out)
	else: out.append({"type": n["tag"], "a": at, "off": o, "dur": float(at.get("duration", 0)), "ip": ip, "fa": f})
func load_anim(name: String) -> Array:
	if _cache.has(name): return _cache[name]
	var j = Assets.jload("anim/%s.json" % name)
	var out := []
	if j is Dictionary and j.has("tag"): _flat(j, 0.0, "", false, out)
	_cache[name] = out
	return out
func ease_of(ip: String, t: float) -> float:
	match ip.get_slice("0x010a", 1):
		"0004": return (cos((t + 1.0) * PI) / 2.0) + 0.5
		"0005": return t * t
		"0006": return 1.0 - (1.0 - t) * (1.0 - t)
		"0007": return t * t * ((2.0 * 2.0 + 1.0) * t - 2.0)
		"0008":
			var tt := t * 2.0
			if tt < 1.0: return 0.5 * tt * tt * ((3.0 * 1.5 + 1.0) * tt - 3.0 * 1.5)
			tt -= 2.0
			return 0.5 * (tt * tt * ((3.0 * 1.5 + 1.0) * tt + 3.0 * 1.5) + 2.0)
		"0009":
			var x := t * 1.1226
			if x < 0.3535: return 8.0 * x * x
			if x < 0.7408: return 8.0 * (x - 0.54719) * (x - 0.54719) + 0.7
			if x < 0.9644: return 8.0 * (x - 0.8526) * (x - 0.8526) + 0.9
			return 8.0 * (x - 1.0435) * (x - 1.0435) + 0.95
		"000a": return sin(2.0 * PI * t)
		"000c": return (t - 1.0) * (t - 1.0) * ((2.0 + 1.0) * (t - 1.0) + 2.0) + 1.0
	return t
func play(v: AView, name: String, done: Callable = Callable(), loops := 1) -> void: play_tracks(v, load_anim(name), done, loops)
func play_tracks(v: AView, tr: Array, done: Callable = Callable(), loops := 1) -> void:
	stop(v, false)
	if tr.is_empty():
		if done.is_valid(): done.call()
		return
	var total := 0.0
	for t in tr: total = max(total, float(t["off"]) + float(t["dur"]))
	_act.append({"v": v, "tr": tr, "t": 0.0, "total": total, "done": done, "loops": loops, "pos": v.position, "scale": v.scale, "alpha": v.modulate.a, "rot": v.rotation_degrees, "piv": v.pivot_offset})
	set_process(true)
func stop(v: AView, restore := true) -> void:
	for i in range(_act.size() - 1, -1, -1):
		if _act[i]["v"] == v:
			if restore: _restore(_act[i])
			_act.remove_at(i)
func busy(v: AView) -> bool:
	for a in _act:
		if a["v"] == v: return true
	return false
func _restore(a: Dictionary) -> void:
	if not is_instance_valid(a["v"]): return
	var v: AView = a["v"]
	v.position = a["pos"]
	v.scale = a["scale"]
	v.modulate.a = a["alpha"]
	v.rotation_degrees = a["rot"]
	v.pivot_offset = a["piv"]
func _pv(s: Variant, size: float) -> float:
	var t := str(s)
	return float(t.rstrip("%")) * size if t.ends_with("%") else float(t)
func _process(dt: float) -> void:
	var fin := []
	for a in _act:
		if not is_instance_valid(a["v"]):
			fin.append(a)
			continue
		var v: AView = a["v"]
		if not a.get("init", false):
			a["init"] = true
			a["pos"] = v.position
			a["scale"] = Vector2.ONE
			a["alpha"] = 1.0
			a["rot"] = 0.0
			a["piv"] = v.pivot_offset
		a["t"] += dt * 1000.0
		var el: float = a["t"]
		var cur := {"t": null, "s": null, "a": null, "r": null}
		var piv: Vector2 = v.size * 0.5
		for t in a["tr"]:
			var at: Dictionary = t["a"]
			var key := ""
			match t["type"]:
				"translate": key = "t"
				"scale": key = "s"
				"alpha": key = "a"
				"rotate": key = "r"
			if key == "": continue
			var off: float = t["off"]
			var dur: float = max(t["dur"], 1.0)
			var u: float = clamp((el - off) / dur, 0.0, 1.0)
			if el < off and cur[key] != null: continue
			if el > off + t["dur"] and not t["fa"]: continue
			var e := ease_of(t["ip"], u)
			match key:
				"t": cur[key] = Vector2(lerp(float(at.get("fromXDelta", 0)), float(at.get("toXDelta", 0)), e), lerp(float(at.get("fromYDelta", 0)), float(at.get("toYDelta", 0)), e))
				"s":
					cur[key] = Vector2(lerp(float(at.get("fromXScale", 1)), float(at.get("toXScale", 1)), e), lerp(float(at.get("fromYScale", 1)), float(at.get("toYScale", 1)), e))
					piv = Vector2(_pv(at.get("pivotX", "0.5%"), v.size.x), _pv(at.get("pivotY", "0.5%"), v.size.y))
				"a": cur[key] = lerp(float(at.get("fromAlpha", 1)), float(at.get("toAlpha", 1)), e)
				"r":
					cur[key] = lerp(float(at.get("fromDegrees", 0)), float(at.get("toDegrees", 0)), e)
					piv = Vector2(_pv(at.get("pivotX", "0.5%"), v.size.x), _pv(at.get("pivotY", "0.5%"), v.size.y))
		v.position = a["pos"] + (cur["t"] if cur["t"] != null else Vector2.ZERO)
		v.pivot_offset = piv
		v.scale = cur["s"] if cur["s"] != null else Vector2.ONE
		v.modulate.a = float(a["alpha"]) * (cur["a"] if cur["a"] != null else 1.0)
		v.rotation_degrees = cur["r"] if cur["r"] != null else 0.0
		if el >= a["total"]:
			a["loops"] -= 1
			if a["loops"] == 0: fin.append(a)
			else: a["t"] = 0.0
	for a in fin:
		_act.erase(a)
		var keep := false
		for t in a["tr"]:
			if t["fa"]: keep = true
		if not keep: _restore(a)
		if a["done"].is_valid(): a["done"].call()
	if _act.is_empty(): set_process(false)
