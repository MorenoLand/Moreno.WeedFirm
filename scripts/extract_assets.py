#!/usr/bin/env python3
"""Decode a user-supplied APK into ./assets_extracted (git-ignored). Stdlib only."""
import sys, zipfile, pathlib, struct, json
def u8(b, o): return b[o]
def u16(b, o): return struct.unpack_from("<H", b, o)[0]
def u32(b, o): return struct.unpack_from("<I", b, o)[0]
def s8(b, p):
    n = b[p]; p += 1
    if n & 0x80: p += 1
    m = b[p]; p += 1
    if m & 0x80: m = ((m & 0x7f) << 8) | b[p]; p += 1
    return b[p:p + m].decode("utf-8", "replace")
def s16(b, p):
    n = u16(b, p); p += 2
    if n & 0x8000: n = ((n & 0x7fff) << 16) | u16(b, p); p += 2
    return b[p:p + 2 * n].decode("utf-16le", "replace")
def pool(b, o):
    cnt, flags, base = u32(b, o + 8), u32(b, o + 16), o + u32(b, o + 20)
    return [(s8 if flags & 0x100 else s16)(b, base + u32(b, o + u16(b, o + 2) + 4 * i)) for i in range(cnt)]
UNITS = ["px", "dp", "sp", "pt", "in", "mm"]
ATTRS = {0x1010095: "textSize", 0x1010096: "textStyle", 0x1010097: "typeface", 0x1010098: "textColor", 0x10100af: "gravity", 0x10100d4: "background", 0x10100d5: "padding", 0x10100d6: "paddingLeft", 0x10100d7: "paddingTop", 0x10100d8: "paddingRight", 0x10100d9: "paddingBottom", 0x10100f4: "layout_width", 0x10100f5: "layout_height", 0x10100f6: "layout_margin", 0x10100f7: "layout_marginLeft", 0x10100f8: "layout_marginTop", 0x10100f9: "layout_marginRight", 0x10100fa: "layout_marginBottom", 0x1010161: "shadowColor", 0x1010162: "shadowDx", 0x1010163: "shadowDy", 0x1010164: "shadowRadius", 0x1010034: "textAppearance", 0x101014f: "text", 0x1010119: "src", 0x10100e5: "clickable", 0x101013f: "minWidth", 0x1010140: "minHeight", 0x1010181: "layout_weight"}
def dim(d, frac):
    m = (struct.unpack("<i", struct.pack("<I", d & 0xffffff00))[0] >> 8) / [1, 128, 32768, 8388608][(d >> 4) & 3]
    return "%g%s" % (m, "%" if frac else UNITS[d & 15] if (d & 15) < 6 else "")
class Arsc:
    def __init__(self, b):
        self.gp = pool(b, 12); self.ids = {}; self.res = {}; self.parents = {}
        o = 12 + u32(b, 16)
        while o < len(b):
            if u16(b, o) == 0x0200: self.package(b, o)
            o += u32(b, o + 4)
    def package(self, b, o):
        pid = u32(b, o + 8); types = pool(b, o + u32(b, o + 268)); keys = pool(b, o + u32(b, o + 276))
        c, end = o + u16(b, o + 2), o + u32(b, o + 4)
        while c < end:
            if u16(b, c) == 0x0201: self.type_chunk(b, c, pid, types, keys)
            c += u32(b, c + 4)
    def type_chunk(self, b, c, pid, types, keys):
        tid, flags, cnt, es = b[c + 8], b[c + 9], u32(b, c + 12), u32(b, c + 16)
        cfg = b[c + 20:c + 20 + u32(b, c + 20)]
        offs = c + u16(b, c + 2)
        if flags & 1: items = [(u16(b, offs + 4 * i), u16(b, offs + 4 * i + 2) * 4) for i in range(cnt)]
        elif flags & 2: items = [(i, u16(b, offs + 2 * i) * 4) for i in range(cnt) if u16(b, offs + 2 * i) != 0xffff]
        else: items = [(i, u32(b, offs + 4 * i)) for i in range(cnt) if u32(b, offs + 4 * i) != 0xffffffff]
        tn = types[tid - 1]
        for idx, off in items:
            e = c + es + off; name = keys[u32(b, e + 4)]; rid = (pid << 24) | (tid << 16) | idx
            self.ids[rid] = (tn, name)
            if u16(b, e + 2) & 1:
                vals = []; q = e + 16; self.parents[(tn, name)] = u32(b, e + 8)
                for _ in range(u32(b, e + 12)): vals.append((u8(b, q + 7), u32(b, q + 8), u32(b, q))); q += 12
            else: vals = (u8(b, e + 11), u32(b, e + 12))
            self.res.setdefault(tn, {}).setdefault(name, []).append((cfg, vals))
    def ref(self, d):
        t = self.ids.get(d)
        return "@%s/%s" % t if t else "@0x%08x" % d
    def val(self, t, d):
        if t == 3: return self.gp[d]
        if t == 1: return self.ref(d)
        if t == 2: return "?0x%08x" % d
        if t == 4: return struct.unpack("<f", struct.pack("<I", d))[0]
        if t == 5: return dim(d, False)
        if t == 6: return dim(d, True)
        if t == 0x10: return struct.unpack("<i", struct.pack("<I", d))[0]
        if t == 0x11: return d
        if t == 0x12: return d != 0
        if 0x1c <= t <= 0x1f: return "#%08x" % d
        return d
def nine(d):
    o = 8
    while o + 8 <= len(d):
        n = struct.unpack_from(">I", d, o)[0]
        if d[o + 4:o + 8] == b"npTc":
            p = o + 8; nx, ny = d[p + 1], d[p + 2]
            pad = list(struct.unpack_from(">4i", d, p + 12)); xs = list(struct.unpack_from(">%di" % nx, d, p + 32)); ys = list(struct.unpack_from(">%di" % ny, d, p + 32 + 4 * nx))
            w, h = struct.unpack_from(">II", d, 16)
            return {"x": xs, "y": ys, "pad": pad, "w": w, "h": h}
        o += 12 + n
    return None
def plain(cfg): return not any(cfg[4:14]) and not any(cfg[16:])
def density(cfg): return struct.unpack_from("<H", cfg, 14)[0] if len(cfg) >= 16 else 0
def axml(b, ar):
    sp = []; root = None; stack = []; o = u16(b, 2)
    while o < len(b):
        t, sz = u16(b, o), u32(b, o + 4)
        if t == 1: sp = pool(b, o)
        elif t == 0x102:
            ac, q = u16(b, o + 28), o + 16 + u16(b, o + 24)
            at = {}
            for i in range(ac):
                a = q + 20 * i; raw = u32(b, a + 8)
                at[sp[u32(b, a + 4)]] = sp[raw] if raw != 0xffffffff else ar.val(b[a + 15], u32(b, a + 16))
            n = {"tag": sp[u32(b, o + 20)], "attrs": at, "children": []}
            if stack: stack[-1]["children"].append(n)
            stack.append(n); root = root or n
        elif t == 0x103: stack.pop()
        o += sz
    return root
def main():
    if len(sys.argv) != 2: sys.exit("usage: extract_assets.py <game.apk>")
    out = pathlib.Path(__file__).resolve().parent.parent / "assets_extracted"
    z = zipfile.ZipFile(sys.argv[1]); ar = Arsc(z.read("resources.arsc"))
    def put(rel, data):
        p = out / rel; p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data if isinstance(data, bytes) else json.dumps(data, ensure_ascii=False).encode())
    n = 0; patches = {}; put(".gdignore", b"")
    for tn in ("drawable", "mipmap", "layout", "anim", "raw", "xml", "menu", "interpolator", "color"):
        for name, ents in ar.res.get(tn, {}).items():
            fs = [(c, v) for c, v in ents if not isinstance(v, list) and v[0] == 3 and ar.gp[v[1]].startswith("res/")]
            if not fs: continue
            if any(ar.gp[v[1]].endswith((".png", ".jpg", ".webp", ".ogg", ".mp3", ".wav")) for c, v in fs):
                for c, v in fs:
                    path = ar.gp[v[1]]; ext = path[path.rindex("."):]
                    rel = "%s/%s%s%s" % (tn, name, "" if len(fs) == 1 else ".%d" % density(c), ext); data = z.read(path); put(rel, data); n += 1
                    if ext == ".png" and nine(data): patches[rel] = nine(data)
                continue
            c, v = next(((c, v) for c, v in fs if plain(c)), fs[0])
            put("%s/%s.json" % (tn, name), axml(z.read(ar.gp[v[1]]), ar)); n += 1
    strings = {nm: ar.gp[v[1]] for nm, es in ar.res.get("string", {}).items() for c, v in es if plain(c) and not isinstance(v, list) and v[0] == 3}
    def item(t, d): return strings.get(ar.ref(d).split("/")[-1], ar.ref(d)) if t == 1 else ar.val(t, d)
    arrays = {nm: [item(t, d) for t, d, _ in v] for nm, es in ar.res.get("array", {}).items() for c, v in es if plain(c) and isinstance(v, list)}
    styles = {nm: {"parent": ar.ref(ar.parents[("style", nm)]), "attrs": {ATTRS.get(a, "0x%x" % a): ar.val(t, d) for t, d, a in v}} for nm, es in ar.res.get("style", {}).items() for c, v in es if plain(c) and isinstance(v, list)}
    put("strings.json", strings); put("arrays.json", arrays); put("styles.json", styles); put("ninepatch.json", patches)
    put("ids.json", {"0x%08x" % k: "%s/%s" % v for k, v in ar.ids.items()})
    for info in z.infolist():
        if info.filename.startswith("assets/fonts/") and not info.is_dir(): put("fonts/" + info.filename.split("/")[-1], z.read(info)); n += 1
    print("Extracted %d files, %d strings, %d arrays to %s" % (n, len(strings), len(arrays), out))
if __name__ == "__main__": main()
