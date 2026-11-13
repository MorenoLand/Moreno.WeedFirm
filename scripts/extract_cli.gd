extends SceneTree
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		print("usage: redot --headless --script scripts/extract_cli.gd -- <game.apk> [output dir]")
		quit(1)
		return
	var l := ApkLoader.new()
	if args.size() > 1: l.out = args[1].rstrip("/") + "/"
	var ok := l.extract(args[0])
	print("Extracted %d files to %s" % [l.count, l.out] if ok else "Could not read the APK")
	quit(0 if ok else 1)
