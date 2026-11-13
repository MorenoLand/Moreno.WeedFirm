extends Node
var path := "user://save.json"
var d := {}
var _t: Timer
func _ready() -> void:
	for k in ["WF_SEED", "WF_TEST", "WF_UITEST", "WF_CLIENTS", "WF_BOT", "WF_ACT", "WF_SHOT"]:
		if OS.get_environment(k) != "": path = "user://test_save.json"
	var t := FileAccess.get_file_as_string(path)
	if t != "":
		var j = JSON.parse_string(t)
		if j is Dictionary: d = j
	_t = Timer.new()
	_t.one_shot = true
	_t.wait_time = 0.4
	_t.timeout.connect(flush)
	add_child(_t)
func int_of(k: String, def := 0) -> int: return int(d.get(k, def))
func bool_of(k: String, def := false) -> bool: return bool(d.get(k, def))
func str_of(k: String, def := "") -> String:
	var v = d.get(k)
	return def if v == null else str(v)
func has(k: String) -> bool: return d.has(k) and d[k] != null
func put(k: String, v: Variant) -> void:
	d[k] = v
	if _t != null and _t.is_inside_tree(): _t.start()
func remove(k: String) -> void:
	d.erase(k)
	if _t != null and _t.is_inside_tree(): _t.start()
func now() -> int: return int(Time.get_unix_time_from_system() * 1000.0)
func flush() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(d))
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT: flush()
