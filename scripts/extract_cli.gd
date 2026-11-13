extends SceneTree
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		print("usage: redot --headless --script scripts/extract_cli.gd -- <game.apk> [output dir | bundle.zip]")
		quit(1)
		return
	var l := ApkLoader.new()
	var ok := false
	if args.size() > 1 and args[1].ends_with(".zip"):
		ok = l.extract_zip(args[0], args[1])
		print("Bundled %d files into %s" % [l.count, args[1]] if ok else "Could not read the APK")
		quit(0 if ok else 1)
		return
	if args.size() > 1: l.out = args[1].rstrip("/") + "/"
	ok = l.extract(args[0])
	print("Extracted %d files to %s" % [l.count, l.out] if ok else "Could not read the APK")
	quit(0 if ok else 1)
