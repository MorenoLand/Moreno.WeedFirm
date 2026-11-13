class_name ApkLoader
extends RefCounted
const UNITS := ["px", "dp", "sp", "pt", "in", "mm"]
const ATTRS := {0x1010095: "textSize", 0x1010096: "textStyle", 0x1010097: "typeface", 0x1010098: "textColor", 0x10100af: "gravity", 0x10100d4: "background", 0x10100d5: "padding", 0x10100d6: "paddingLeft", 0x10100d7: "paddingTop", 0x10100d8: "paddingRight", 0x10100d9: "paddingBottom", 0x10100f4: "layout_width", 0x10100f5: "layout_height", 0x10100f6: "layout_margin", 0x10100f7: "layout_marginLeft", 0x10100f8: "layout_marginTop", 0x10100f9: "layout_marginRight", 0x10100fa: "layout_marginBottom", 0x1010161: "shadowColor", 0x1010162: "shadowDx", 0x1010163: "shadowDy", 0x1010164: "shadowRadius", 0x1010034: "textAppearance", 0x101014f: "text", 0x1010119: "src", 0x10100e5: "clickable", 0x101013f: "minWidth", 0x1010140: "minHeight", 0x1010181: "layout_weight"}
const MEDIA := [".png", ".jpg", ".webp", ".ogg", ".mp3", ".wav"]
var out := "user://assets_extracted/"
var gp := PackedStringArray()
var ids := {}
var res := {}
var parents := {}
var zip: ZIPReader
var count := 0
var patches := {}
func u16(b: PackedByteArray, o: int) -> int: return b.decode_u16(o)
func u32(b: PackedByteArray, o: int) -> int: return b.decode_u32(o)
func s8(b: PackedByteArray, p: int) -> String:
	var n := b[p]
	p += 1
	if n & 0x80: p += 1
	var m := b[p]
	p += 1
	if m & 0x80:
		m = ((m & 0x7f) << 8) | b[p]
		p += 1
	return b.slice(p, p + m).get_string_from_utf8()
func s16(b: PackedByteArray, p: int) -> String:
	var n := u16(b, p)
	p += 2
	if n & 0x8000:
		n = ((n & 0x7fff) << 16) | u16(b, p)
		p += 2
	return b.slice(p, p + 2 * n).get_string_from_utf16()
func pool(b: PackedByteArray, o: int) -> PackedStringArray:
	var cnt := u32(b, o + 8)
	var utf8 := (u32(b, o + 16) & 0x100) != 0
	var base := o + u32(b, o + 20)
	var hs := u16(b, o + 2)
	var r := PackedStringArray()
	for i in cnt:
		var p := base + u32(b, o + hs + 4 * i)
		r.append(s8(b, p) if utf8 else s16(b, p))
	return r
func signed(d: int) -> int: return d - 0x100000000 if d >= 0x80000000 else d
func dimension(d: int, frac: bool) -> String:
	var mm := signed(d & 0xffffff00)
	var div: float = [1.0, 128.0, 32768.0, 8388608.0][(d >> 4) & 3]
	var m: float = float(mm >> 8) / div
	var unit: String = "%" if frac else (UNITS[d & 15] if (d & 15) < 6 else "")
	if m != 0.0:
		var digits := 5 - int(floor(log(absf(m)) / log(10.0)))
		m = snappedf(m, pow(10.0, -digits))
	return String.num(m) + unit
func ref(d: int) -> String:
	if ids.has(d): return "@%s/%s" % [ids[d][0], ids[d][1]]
	return "@0x%08x" % d
func val(t: int, d: int) -> Variant:
	if t == 3: return gp[d]
	if t == 1: return ref(d)
	if t == 2: return "?0x%08x" % d
	if t == 4:
		var pb := PackedByteArray()
		pb.resize(4)
		pb.encode_u32(0, d)
		return pb.decode_float(0)
	if t == 5: return dimension(d, false)
	if t == 6: return dimension(d, true)
	if t == 0x10 or t == 0x11: return signed(d) if t == 0x10 else d
	if t == 0x12: return d != 0
	if t >= 0x1c and t <= 0x1f: return "#%08x" % d
	return d
func parse_arsc(b: PackedByteArray) -> void:
	gp = pool(b, 12)
	var o := 12 + u32(b, 16)
	while o < b.size():
		if u16(b, o) == 0x0200: parse_package(b, o)
		o += u32(b, o + 4)
func parse_package(b: PackedByteArray, o: int) -> void:
	var pid := u32(b, o + 8)
	var types := pool(b, o + u32(b, o + 268))
	var keys := pool(b, o + u32(b, o + 276))
	var c := o + u16(b, o + 2)
	var end := o + u32(b, o + 4)
	while c < end:
		if u16(b, c) == 0x0201: type_chunk(b, c, pid, types, keys)
		c += u32(b, c + 4)
func type_chunk(b: PackedByteArray, c: int, pid: int, types: PackedStringArray, keys: PackedStringArray) -> void:
	var tid := b[c + 8]
	var flags := b[c + 9]
	var cnt := u32(b, c + 12)
	var es := u32(b, c + 16)
	var cfg := b.slice(c + 20, c + 20 + u32(b, c + 20))
	var offs := c + u16(b, c + 2)
	var items := []
	if flags & 1:
		for i in cnt: items.append([u16(b, offs + 4 * i), u16(b, offs + 4 * i + 2) * 4])
	elif flags & 2:
		for i in cnt:
			if u16(b, offs + 2 * i) != 0xffff: items.append([i, u16(b, offs + 2 * i) * 4])
	else:
		for i in cnt:
			if u32(b, offs + 4 * i) != 0xffffffff: items.append([i, u32(b, offs + 4 * i)])
	var tn := types[tid - 1]
	for it in items:
		var e: int = c + es + int(it[1])
		var name := keys[u32(b, e + 4)]
		var rid: int = (pid << 24) | (tid << 16) | int(it[0])
		ids[rid] = [tn, name]
		var vals: Variant
		if u16(b, e + 2) & 1:
			var arr := []
			var q := e + 16
			parents[tn + "/" + name] = u32(b, e + 8)
			for _i in u32(b, e + 12):
				arr.append([b[q + 7], u32(b, q + 8), u32(b, q)])
				q += 12
			vals = arr
		else: vals = [b[e + 11], u32(b, e + 12)]
		if not res.has(tn): res[tn] = {}
		if not res[tn].has(name): res[tn][name] = []
		res[tn][name].append([cfg, vals])
func is_plain(cfg: PackedByteArray) -> bool:
	for i in range(4, mini(14, cfg.size())):
		if cfg[i] != 0: return false
	for i in range(16, cfg.size()):
		if cfg[i] != 0: return false
	return true
func density(cfg: PackedByteArray) -> int: return u16(cfg, 14) if cfg.size() >= 16 else 0
func axml(b: PackedByteArray) -> Variant:
	var sp := PackedStringArray()
	var root: Variant = null
	var stack := []
	var o := u16(b, 2)
	while o < b.size():
		var t := u16(b, o)
		var sz := u32(b, o + 4)
		if t == 1: sp = pool(b, o)
		elif t == 0x102:
			var ac := u16(b, o + 28)
			var q := o + 16 + u16(b, o + 24)
			var at := {}
			for i in ac:
				var a := q + 20 * i
				var raw := u32(b, a + 8)
				at[sp[u32(b, a + 4)]] = sp[raw] if raw != 0xffffffff else val(b[a + 15], u32(b, a + 16))
			var n := {"tag": sp[u32(b, o + 20)], "attrs": at, "children": []}
			if not stack.is_empty(): stack.back()["children"].append(n)
			stack.append(n)
			if root == null: root = n
		elif t == 0x103: stack.pop_back()
		o += sz
	return root
func nine(d: PackedByteArray) -> Variant:
	var o := 8
	while o + 8 <= d.size():
		var n := (d[o] << 24) | (d[o + 1] << 16) | (d[o + 2] << 8) | d[o + 3]
		if d.slice(o + 4, o + 8).get_string_from_ascii() == "npTc":
			var p := o + 8
			var nx := d[p + 1]
			var ny := d[p + 2]
			var be := func(q: int) -> int: return signed((d[q] << 24) | (d[q + 1] << 16) | (d[q + 2] << 8) | d[q + 3])
			var pad := []
			for i in 4: pad.append(be.call(p + 12 + 4 * i))
			var xs := []
			for i in nx: xs.append(be.call(p + 32 + 4 * i))
			var ys := []
			for i in ny: ys.append(be.call(p + 32 + 4 * nx + 4 * i))
			return {"x": xs, "y": ys, "pad": pad, "w": be.call(16), "h": be.call(20)}
		o += 12 + n
	return null
func put(rel: String, data: Variant) -> void:
	var p := out + rel
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f == null: return
	if data is PackedByteArray: f.store_buffer(data)
	else: f.store_string(JSON.stringify(data))
func item_text(strings: Dictionary, t: int, d: int) -> Variant:
	if t == 1:
		var r := ref(d)
		return strings.get(r.get_slice("/", 1), r)
	return val(t, d)
var files := {}
var meta := {}
func open_index(apk_path: String) -> bool:
	zip = ZIPReader.new()
	if zip.open(apk_path) != OK: return false
	if not zip.file_exists("resources.arsc"): return false
	parse_arsc(zip.read_file("resources.arsc"))
	var kinds := ["drawable", "mipmap", "layout", "anim", "raw", "xml", "menu", "interpolator", "color"]
	for tn in kinds:
		var names: Dictionary = res.get(tn, {})
		for name in names:
			var fs := []
			for e in names[name]:
				var v: Array = e[1]
				if v.size() == 2 and v[0] == 3 and gp[v[1]].begins_with("res/"): fs.append(e)
			if fs.is_empty(): continue
			var media := false
			for e in fs:
				var pth: String = gp[e[1][1]]
				for m in MEDIA:
					if pth.ends_with(m): media = true
			if media:
				for e in fs:
					var pth2: String = gp[e[1][1]]
					var ext := pth2.substr(pth2.rfind("."))
					files["%s/%s%s%s" % [tn, name, "" if fs.size() == 1 else ".%d" % density(e[0]), ext]] = {"src": pth2, "axml": false}
				continue
			var pick: Array = fs[0]
			for e in fs:
				if is_plain(e[0]):
					pick = e
					break
			files["%s/%s.json" % [tn, name]] = {"src": gp[pick[1][1]], "axml": true}
	var strings := {}
	for nm in res.get("string", {}):
		for e in res["string"][nm]:
			var v: Array = e[1]
			if is_plain(e[0]) and v.size() == 2 and v[0] == 3: strings[nm] = gp[v[1]]
	var arrays := {}
	for nm in res.get("array", {}):
		for e in res["array"][nm]:
			var v: Array = e[1]
			if is_plain(e[0]) and (v.size() == 0 or v[0] is Array):
				var items := []
				for it in v: items.append(item_text(strings, it[0], it[1]))
				arrays[nm] = items
	var styles := {}
	for nm in res.get("style", {}):
		for e in res["style"][nm]:
			var v: Array = e[1]
			if is_plain(e[0]) and (v.size() == 0 or v[0] is Array):
				var attrs := {}
				for it in v: attrs[ATTRS.get(int(it[2]), "0x%x" % int(it[2]))] = val(it[0], it[1])
				styles[nm] = {"parent": ref(int(parents.get("style/" + nm, 0))), "attrs": attrs}
	var idmap := {}
	for k in ids: idmap["0x%08x" % k] = "%s/%s" % [ids[k][0], ids[k][1]]
	meta["strings.json"] = strings
	meta["arrays.json"] = arrays
	meta["styles.json"] = styles
	meta["ids.json"] = idmap
	meta["ninepatch.json"] = {}
	for f in zip.get_files():
		if f.begins_with("assets/fonts/") and not f.ends_with("/"): files["fonts/" + f.get_file()] = {"src": f, "axml": false}
	return true
func has(rel: String) -> bool: return files.has(rel) or meta.has(rel)
func read_bytes(rel: String) -> PackedByteArray:
	if meta.has(rel): return JSON.stringify(meta[rel]).to_utf8_buffer()
	if not files.has(rel): return PackedByteArray()
	var f: Dictionary = files[rel]
	var b := zip.read_file(f["src"])
	return JSON.stringify(axml(b)).to_utf8_buffer() if f["axml"] else b
func json(rel: String) -> Variant:
	if meta.has(rel): return meta[rel]
	if files.has(rel) and files[rel]["axml"]: return axml(zip.read_file(files[rel]["src"]))
	return {}
func extract(apk_path: String, progress: Callable = Callable()) -> bool:
	if not open_index(apk_path): return false
	put(".gdignore", PackedByteArray())
	var n := 0
	for rel in files:
		var data := read_bytes(rel)
		put(rel, data)
		count += 1
		n += 1
		if rel.ends_with(".png"):
			var np: Variant = nine(data)
			if np != null: patches[rel] = np
		if progress.is_valid() and n % 40 == 0: progress.call(count)
	meta["ninepatch.json"] = patches
	for k in meta: put(k, meta[k])
	zip.close()
	return true
func extract_zip(apk_path: String, zip_path: String) -> bool:
	if not open_index(apk_path): return false
	var pk := ZIPPacker.new()
	if pk.open(zip_path) != OK: return false
	for rel in files:
		var data := read_bytes(rel)
		pk.start_file(rel)
		pk.write_file(data)
		pk.close_file()
		count += 1
		if rel.ends_with(".png"):
			var np: Variant = nine(data)
			if np != null: patches[rel] = np
	meta["ninepatch.json"] = patches
	for k in meta:
		pk.start_file(k)
		pk.write_file(JSON.stringify(meta[k]).to_utf8_buffer())
		pk.close_file()
	pk.close()
	zip.close()
	return true
