extends Node
const DP := 2.0
var base := "res://assets_extracted/"
var strings := {}
var arrays := {}
var styles := {}
var nine := {}
var _tex := {}
var _drw := {}
var _lay := {}
var _snd := {}
var _fonts := {}
func _ready() -> void: reload()
const APK_CFG := "user://apk_path.txt"
var src: ApkLoader = null
func reload() -> void:
	src = null
	base = "res://assets_extracted/"
	if FileAccess.file_exists("user://assets_extracted/strings.json"): base = "user://assets_extracted/"
	elif FileAccess.file_exists(APK_CFG):
		var l := ApkLoader.new()
		if l.open_index(FileAccess.get_file_as_string(APK_CFG).strip_edges()): src = l
	_tex.clear()
	_drw.clear()
	_lay.clear()
	_snd.clear()
	_fonts.clear()
	strings = jload("strings.json")
	arrays = jload("arrays.json")
	styles = jload("styles.json")
	nine = jload("ninepatch.json")
func ok() -> bool: return not strings.is_empty()
func has(rel: String) -> bool: return src.has(rel) if src != null else FileAccess.file_exists(base + rel)
func bytes_of(rel: String) -> PackedByteArray: return src.read_bytes(rel) if src != null else FileAccess.get_file_as_bytes(base + rel)
func use_apk(path: String) -> bool:
	var l := ApkLoader.new()
	if not l.open_index(path): return false
	var f := FileAccess.open(APK_CFG, FileAccess.WRITE)
	if f == null: return false
	f.store_string(path)
	f.close()
	reload()
	return ok()
func jload(rel: String) -> Variant:
	if src != null: return src.json(rel)
	var t := FileAccess.get_file_as_string(base + rel)
	return JSON.parse_string(t) if t != "" else {}
func layout(name: String) -> Variant:
	if not _lay.has(name): _lay[name] = jload("layout/%s.json" % name)
	return _lay[name]
func str_of(name: String, args: Array = []) -> String:
	var s: String = strings.get(name, name)
	var re := RegEx.create_from_string("%(\\d+\\$)?[sd]")
	var i := 0
	var out := ""
	var pos := 0
	for m in re.search_all(s):
		out += s.substr(pos, m.get_start() - pos)
		var idx := i
		if m.get_string(1) != "": idx = int(m.get_string(1)) - 1
		out += str(args[idx]) if idx < args.size() else ""
		pos = m.get_end()
		i += 1
	return out + s.substr(pos)
func resolve(v: Variant) -> Variant:
	if v is String and v.begins_with("@string/"): return strings.get(v.substr(8), v)
	return v
func rec(name: String) -> Dictionary:
	if _tex.has(name): return _tex[name]
	var r := {}
	for d in ["drawable", "mipmap"]:
		for suf in [".320", "", ".160", ".240", ".480"]:
			for ext in ["png", "jpg", "webp"]:
				var rel := "%s/%s%s.%s" % [d, name, suf, ext]
				if has(rel):
					var bytes := bytes_of(rel)
					var img := Image.new()
					var err := img.load_png_from_buffer(bytes) if ext == "png" else (img.load_jpg_from_buffer(bytes) if ext == "jpg" else img.load_webp_from_buffer(bytes))
					if err != OK: continue
					var dens := 320.0
					if suf == ".160": dens = 160.0
					elif suf == ".240": dens = 240.0
					elif suf == ".480": dens = 480.0
					r = {"tex": ImageTexture.create_from_image(img), "scale": 320.0 / dens * (DP / 2.0), "nine": (src.nine(bytes) if src != null and ext == "png" else nine.get(rel))}
					break
			if not r.is_empty(): break
		if not r.is_empty(): break
	_tex[name] = r
	return r
func drawable(ref: Variant) -> Dictionary:
	if not (ref is String): return {}
	if ref.begins_with("#"): return {"kind": "color", "color": color(ref)}
	if not ref.begins_with("@drawable/") and not ref.begins_with("@mipmap/") and not ref.begins_with("@color/"): return {}
	var name: String = ref.get_slice("/", 1)
	if _drw.has(name): return _drw[name]
	var r := {}
	var im := rec(name)
	if not im.is_empty(): r = {"kind": "image", "rec": im}
	else:
		var j = jload("drawable/%s.json" % name)
		if j is Dictionary and j.has("tag"): r = _parse_drawable(j)
	_drw[name] = r
	return r
func _parse_drawable(j: Dictionary) -> Dictionary:
	var at: Dictionary = j.get("attrs", {})
	match j["tag"]:
		"selector":
			var items := []
			for c in j["children"]: items.append({"state": c["attrs"], "d": _child_drawable(c)})
			return {"kind": "selector", "items": items}
		"animation-list":
			var fr := []
			for c in j["children"]: fr.append({"ms": int(c["attrs"].get("duration", 100)), "d": drawable(c["attrs"].get("drawable"))})
			return {"kind": "anim", "frames": fr, "oneshot": at.get("oneshot", false)}
		"shape":
			var r := {"kind": "shape", "color": Color(0, 0, 0, 0), "end": Color(0, 0, 0, 0), "grad": false, "angle": 0.0, "radii": [0.0, 0.0, 0.0, 0.0]}
			for c in j["children"]:
				var ca: Dictionary = c["attrs"]
				if c["tag"] == "solid":
					r["color"] = color(ca.get("color", "#00000000"))
					r["end"] = r["color"]
				elif c["tag"] == "gradient":
					r["color"] = color(ca.get("startColor", "#00000000"))
					r["end"] = color(ca.get("endColor", "#00000000"))
					r["grad"] = true
					r["angle"] = float(ca.get("angle", 0))
				elif c["tag"] == "corners":
					var rr := dp(ca.get("radius", "0dp"))
					r["radii"] = [dp(ca.get("topLeftRadius", rr)), dp(ca.get("topRightRadius", rr)), dp(ca.get("bottomRightRadius", rr)), dp(ca.get("bottomLeftRadius", rr))]
			return r
		"layer-list":
			var ls := []
			for c in j["children"]: ls.append(_child_drawable(c))
			return {"kind": "layers", "items": ls}
		"bitmap", "nine-patch": return drawable(at.get("src", ""))
		"inset", "scale", "rotate", "clip": return drawable(at.get("drawable", ""))
		"color": return {"kind": "color", "color": color(at.get("color", "#00000000"))}
	return {}
func _child_drawable(c: Dictionary) -> Dictionary:
	var d = c["attrs"].get("drawable")
	if d != null: return drawable(d)
	for cc in c["children"]:
		var p := _parse_drawable(cc)
		if not p.is_empty(): return p
	return {}
func color(s: String) -> Color:
	if s.begins_with("#"):
		var h := s.substr(1)
		if h.length() == 8: return Color(h.substr(2) + h.substr(0, 2))
		return Color("#" + h)
	return Color.WHITE
func dp(v: Variant) -> float:
	if v is String:
		var s: String = v
		for u in ["dp", "dip", "sp", "px"]:
			if s.ends_with(u): return float(s.trim_suffix(u)) * (1.0 if u == "px" else DP)
		return float(s) * DP
	return float(v) * DP
func font(name: String) -> Font:
	if _fonts.has(name): return _fonts[name]
	var f: Font = null
	if has("fonts/" + name + ".ttf"):
		var ff := FontFile.new()
		ff.data = bytes_of("fonts/" + name + ".ttf")
		f = ff
	_fonts[name] = f
	return f
func sound(name: String) -> AudioStream:
	if _snd.has(name): return _snd[name]
	var s: AudioStream = null
	if has("raw/" + name + ".ogg"): s = AudioStreamOggVorbis.load_from_buffer(bytes_of("raw/" + name + ".ogg"))
	_snd[name] = s
	return s
