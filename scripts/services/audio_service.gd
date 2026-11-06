class_name AudioService
extends Node

var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cursor: int = 0
var events_played: int = 0
var music_voices: Array[AudioStreamPlayer] = []
var music_tracks: Array[AudioStreamWAV] = []
var music_slot: int = 0
var current_chapter: int = -1
var music_ducked: bool = false
var music_weights: Array[float] = [0.0, 0.0]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name: String in ["Music", "Effects"]:
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in 8:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = "Effects"
		add_child(voice)
		voices.append(voice)
	for i in 2:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = "Music"
		add_child(voice)
		music_voices.append(voice)
	for chapter in 4:
		var path: String = "res://assets/audio/chapter_%02d.wav" % (chapter + 1)
		if ResourceLoader.exists(path):
			var stream: AudioStreamWAV = load(path).duplicate()
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
			music_tracks.append(stream)
	for event: String in [
		"jump", "wall_jump", "land", "death", "fragment", "clear", "menu", "respawn"
	]:
		var path: String = "res://assets/audio/%s.wav" % event
		if ResourceLoader.exists(path):
			sounds[event] = load(path)


func apply_settings(settings: Dictionary) -> void:
	for key: String in ["master", "music", "effects"]:
		var bus: int = AudioServer.get_bus_index(
			{"master": "Master", "music": "Music", "effects": "Effects"}[key]
		)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(0.0001, float(settings[key]))))
	AudioServer.set_bus_mute(0, settings.mute)


func play(event: String) -> void:
	if not sounds.has(event) or voices.is_empty():
		return
	var voice: AudioStreamPlayer = voices[cursor]
	voice.stop()
	voice.stream = sounds[event]
	voice.volume_db = -9.0 if event == "menu" else -4.0
	voice.play()
	cursor = (cursor + 1) % voices.size()
	events_played += 1


func set_context(chapter: int, ducked: bool = false) -> void:
	music_ducked = ducked
	if music_tracks.is_empty():
		return
	var selected: int = clampi(chapter - 1, 0, music_tracks.size() - 1)
	if selected == current_chapter:
		return
	current_chapter = selected
	music_slot = (music_slot + 1) % 2
	music_voices[music_slot].stop()
	music_voices[music_slot].stream = music_tracks[selected]
	music_voices[music_slot].volume_db = -70
	music_weights[music_slot] = 0.0
	music_voices[music_slot].play()


func _process(delta: float) -> void:
	for i in music_voices.size():
		var target: float = (0.22 if music_ducked else 1.0) if i == music_slot else 0.0
		music_weights[i] = move_toward(music_weights[i], target, delta * 1.2)
		music_voices[i].volume_db = linear_to_db(maxf(music_weights[i] * 0.7, 0.0001))
		if i != music_slot and music_weights[i] <= 0:
			music_voices[i].stop()


func stop_all(include_music: bool = false) -> void:
	for voice: AudioStreamPlayer in voices:
		voice.stop()
		voice.stream = null
	if include_music:
		for voice: AudioStreamPlayer in music_voices:
			voice.stop()
			voice.stream = null


func _exit_tree() -> void:
	stop_all(true)
