extends Node
var theme := ""
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
func muted() -> bool: return Save.bool_of("mute")
func music_off() -> bool: return muted() or Save.bool_of("mute_music")
func play(name: String) -> void:
	if muted(): return
	var s := Assets.sound(name)
	if s == null: return
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.play()
			return
	_pool[0].stream = s
	_pool[0].play()
func music(name: String) -> void:
	theme = name
	var s := Assets.sound(name)
	if s == null: return
	if s is AudioStreamOggVorbis: s.loop = true
	_music.stream = s
	_music.volume_db = 0.0
	if not music_off(): _music.play()
	else: _music.stop()
func stop_music() -> void: _music.stop()
func refresh() -> void:
	if music_off(): _music.stop()
	elif _music.stream != null and not _music.playing: _music.play()
func theme_mult() -> int:
	match theme:
		"theme_dubstep": return 5
		"theme_original": return 2
		"theme_punk": return 4
		"theme_raggae": return 3
		"theme_trance": return 6
	return 1
