extends Node
## 背景音乐管理器 — AutoLoad 单例
## 使用双 AudioStreamPlayer + Tween 实现渐入渐出切换

const CROSSFADE_TIME := 1.2     # 渐变时长（秒）
const MIN_VOLUME := -40.0       # 静音 (dB)
const FULL_VOLUME := 0.0        # 满音量 (dB)

# 各场景/区域对应的背景音乐路径（已导入的格式）
const BGM_LEVEL_0_1   := "res://.godot/imported/第二关.mp3-35875a80c07bf0b6977212394ec51378.mp3str"
const BGM_LEVEL_0_2   := "res://.godot/imported/Homecoming.wav-51edfeba606893f8fdc38e8c3eee105f.sample"
const BGM_ZONE_A      := "res://.godot/imported/德米特里的植物园2.wav-7c682378035f8d37dd3a36771b04a236.sample"
const BGM_ZONE_B      := "res://.godot/imported/缧绁.wav-3597d7d2e1e1fb5c6fd55bdbe5992fe6.sample"

const UI_CLICK := "res://.godot/imported/SFX_11.mp3-db97dec1d341cfadc2dd9305336be4ef.mp3str"

var _player_a: AudioStreamPlayer = null
var _player_b: AudioStreamPlayer = null
var _active: AudioStreamPlayer = null
var _current_track: String = ""
var _tween: Tween = null


func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.bus = &"Master"
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = &"Master"
	add_child(_player_b)

	_active = _player_a


## 交叉渐变切换到指定曲目
func crossfade(p_track: String) -> void:
	if p_track.is_empty() or p_track == _current_track:
		return
	_current_track = p_track

	var incoming: AudioStreamPlayer = _player_b if _active == _player_a else _player_a

	if _tween and _tween.is_valid():
		_tween.kill()

	incoming.stream = load(p_track)
	incoming.volume_db = MIN_VOLUME
	incoming.play()
	if not incoming.finished.is_connected(_on_loop):
		incoming.finished.connect(_on_loop.bind(incoming))

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_active, "volume_db", MIN_VOLUME, CROSSFADE_TIME)
	_tween.tween_property(incoming, "volume_db", FULL_VOLUME, CROSSFADE_TIME)
	_tween.chain().tween_callback(_on_fade_done.bind(incoming))


func _on_fade_done(p_incoming: AudioStreamPlayer) -> void:
	if is_instance_valid(_active):
		_active.stop()
	_active = p_incoming


func _on_loop(p_player: AudioStreamPlayer) -> void:
	if p_player == _active:
		p_player.play()


func stop() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	for p in [_player_a, _player_b]:
		if p and p.playing:
			p.stop()
	_current_track = ""


func play(p_track: String) -> void:
	if p_track.is_empty() or p_track == _current_track:
		return
	_current_track = p_track

	if _tween and _tween.is_valid():
		_tween.kill()

	_active.stream = load(p_track)
	_active.volume_db = FULL_VOLUME
	_active.play()
	if not _active.finished.is_connected(_on_loop):
		_active.finished.connect(_on_loop.bind(_active))

	var other := _player_b if _active == _player_a else _player_a
	if other.playing:
		other.stop()


## 绑定按钮：鼠标悬停时播放 UI 音效
func bind_hover_sfx(p_button: BaseButton) -> void:
	p_button.mouse_entered.connect(_play_hover_sfx)


## 播放 UI 悬停音效（限播 0.7 秒）
func _play_hover_sfx() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load(UI_CLICK)
	sfx.bus = &"Master"
	add_child(sfx)
	sfx.play()
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(sfx):
			sfx.stop()
			sfx.queue_free()
	)
