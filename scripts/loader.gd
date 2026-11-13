class_name LoaderUI
extends Control
signal loaded
var info: Label
var box: VBoxContainer
var btn: Button
var dlg: FileDialog
var cb: JavaScriptObject
var busy := false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#1d1a14")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.custom_minimum_size = Vector2(900, 0)
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)
	info = Label.new()
	info.text = "This client contains no game content. Select your copy of the game APK. It stays on this device."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 28)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	btn = Button.new()
	btn.text = "Select APK"
	btn.add_theme_font_size_override("font_size", 32)
	btn.custom_minimum_size = Vector2(320, 90)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#eee259")
	sb.set_corner_radius_all(8)
	for st in ["normal", "hover", "pressed", "focus"]: btn.add_theme_stylebox_override(st, sb)
	btn.add_theme_color_override("font_color", Color("#c92c2c"))
	btn.add_theme_color_override("font_hover_color", Color("#c92c2c"))
	btn.add_theme_color_override("font_pressed_color", Color("#c92c2c"))
	btn.pressed.connect(pick)
	box.add_child(btn)
	if OS.has_feature("web"):
		cb = JavaScriptBridge.create_callback(web_loaded)
		JavaScriptBridge.get_interface("window").wfCallback = cb
		fetch_bundle()
	else:
		var hint := Label.new()
		hint.text = "You can also drop the file onto this window."
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 22)
		box.add_child(hint)
		get_window().files_dropped.connect(func(f: PackedStringArray): if f.size() > 0: choose(f[0]))
		dlg = FileDialog.new()
		dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dlg.access = FileDialog.ACCESS_FILESYSTEM
		dlg.use_native_dialog = true
		dlg.filters = PackedStringArray(["*.apk,*.zip ; Android package"])
		dlg.file_selected.connect(choose)
		add_child(dlg)
func _enter_tree() -> void:
	var shot := OS.get_environment("WF_SHOT")
	if shot != "":
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()
var req: HTTPRequest
func fetch_bundle() -> void:
	var prompt := info.text
	info.text = "Loading game data..."
	btn.visible = false
	req = HTTPRequest.new()
	req.download_file = Assets.BUNDLE
	add_child(req)
	var url := str(JavaScriptBridge.eval("new URL('assets.zip', document.baseURI).href"))
	if req.request(url) != OK:
		info.text = prompt
		btn.visible = true
		return
	var res: Array = await req.request_completed
	var f := FileAccess.open(Assets.BUNDLE, FileAccess.READ)
	var size := f.get_length() if f != null else 0
	if f != null: f.close()
	if res[1] == 200 and size > 1000000:
		JavaScriptBridge.force_fs_sync()
		Assets.reload()
		if Assets.ok():
			loaded.emit()
			return
	if FileAccess.file_exists(Assets.BUNDLE): DirAccess.remove_absolute(Assets.BUNDLE)
	info.text = prompt
	btn.visible = true
func _process(_dt: float) -> void:
	if req != null and is_instance_valid(req) and req.get_http_client_status() == HTTPClient.STATUS_BODY:
		var tot := req.get_body_size()
		if tot > 0: info.text = "Loading game data... %d%%" % int(100.0 * req.get_downloaded_bytes() / tot)
func pick() -> void:
	if busy: return
	if OS.has_feature("web"): pick_web()
	else: dlg.popup_centered_ratio(0.7)
func pick_web() -> void:
	JavaScriptBridge.eval("var i=document.createElement('input');i.type='file';i.accept='.apk,.zip';i.onchange=function(e){var f=e.target.files[0];if(!f)return;var r=new FileReader();r.onload=function(){window.wfCallback(new Uint8Array(r.result));};r.readAsArrayBuffer(f);};i.click();")
func web_loaded(args: Array) -> void:
	if args.is_empty(): return
	var bytes := JavaScriptBridge.js_buffer_to_packed_byte_array(args[0])
	var f := FileAccess.open("user://game.apk", FileAccess.WRITE)
	if f == null:
		info.text = "Could not store the file."
		return
	f.store_buffer(bytes)
	f.close()
	choose("user://game.apk")
var pick_row: HBoxContainer
func choose(path: String) -> void:
	if busy: return
	if pick_row != null: pick_row.queue_free()
	pick_row = HBoxContainer.new()
	pick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pick_row.add_theme_constant_override("separation", 24)
	box.add_child(pick_row)
	info.text = "Play straight from the APK, or unpack it to disk for faster loading."
	var a := Button.new()
	a.text = "Play from APK"
	var b := Button.new()
	b.text = "Unpack to disk"
	for x in [a, b]:
		x.add_theme_font_size_override("font_size", 28)
		x.custom_minimum_size = Vector2(300, 80)
		x.add_theme_stylebox_override("normal", btn.get_theme_stylebox("normal"))
		x.add_theme_color_override("font_color", Color("#c92c2c"))
		pick_row.add_child(x)
	a.pressed.connect(func(): direct(path))
	b.pressed.connect(func(): run(path))
func direct(path: String) -> void:
	if busy: return
	if Assets.use_apk(path):
		if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()
		loaded.emit()
	else: info.text = "That file is not a readable APK. Try another."
func run(path: String) -> void:
	if busy: return
	busy = true
	btn.disabled = true
	info.text = "Unpacking..."
	await get_tree().process_frame
	await get_tree().process_frame
	var l := ApkLoader.new()
	var ok := l.extract(path, func(n: int): info.text = "Unpacking... %d files" % n)
	if not ok:
		info.text = "That file is not a readable APK. Try another."
		busy = false
		btn.disabled = false
		return
	if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()
	Assets.reload()
	loaded.emit()
