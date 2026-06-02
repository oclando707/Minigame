extends Node
## 背景音乐管理器 — AutoLoad 单例
## 使用双 AudioStreamPlayer + Tween 实现渐入渐出切换

const CROSSFADE_TIME := 1.2     # 渐变时长（秒）
const MIN_VOLUME := -40.0       # 静音 (dB)
const FULL_VOLUME := 0.0        # 满音量 (dB)

# ============================================================
# BGM 曲目 — 分配到 BGM 总线
# ============================================================
const BGM_LEVEL_0_1   := "res://.godot/imported/第二关.mp3-35875a80c07bf0b6977212394ec51378.mp3str"
const BGM_LEVEL_0_2   := "res://.godot/imported/Homecoming.wav-51edfeba606893f8fdc38e8c3eee105f.sample"
const BGM_ZONE_A      := "res://.godot/imported/德米特里的植物园2.wav-7c682378035f8d37dd3a36771b04a236.sample"
const BGM_ZONE_B      := "res://.godot/imported/缧绁.wav-3597d7d2e1e1fb5c6fd55bdbe5992fe6.sample"
const BGM_MAIN_MENU   := "res://.godot/imported/zhujiemian.wav-af844b560c51e9b8b910200963423011.sample"

# ============================================================
# SFX 音效 — 分配到 SFX 总线
# ============================================================
const SFX_UI_CLICK     := "res://.godot/imported/SFX_11.mp3-db97dec1d341cfadc2dd9305336be4ef.mp3str"
const SFX_VALIDATE     := "res://.godot/imported/验证通过.wav-93b4316e25cf78d3a6d195db5ec08430.sample"
const SFX_CROWD        := "res://.godot/imported/菜市场喧嚣声.wav-469c6bbc37d9a3ea15b2e24e66f90f34.sample"
const SFX_DOG_BARK     := "res://.godot/imported/狗叫.wav-96bb1e73d5419df8a8028a74b390ebbe.sample"
const SFX_STONE_FALL   := "res://.godot/imported/freesound_community-stones-falling-6375.mp3-97fb26d9585a1e9b01a3a9a1c2a04014.mp3str"
const SFX_VINE_BOOM    := "res://.godot/imported/levigoodway-vine-boom-sound-410789.mp3-6c47c2983070d24122cf9b22174e21f2.mp3str"
const SFX_GRASS_RUSTLE := "res://.godot/imported/dragon-studio-dry-grass-rustling-478361.mp3-404bde1317f2e626f455f8b425bcc3dd.mp3str"
const SFX_ROBOT        := "res://.godot/imported/audiopapkin-sound-design-elements-robot-mechanism-021-344709.mp3-0b468bc06aeeec64ce3e614026c5e0a9.mp3str"
const SFX_STAR_SILVER  := "res://.godot/imported/银色星星.wav-0a388e72f9c9350d27b2a4a6caec92a4.sample"
const SFX_STAR_GOLD    := "res://.godot/imported/金色星星.wav-1c57dc1cd08e51a3d462f42e0f3cc53a.sample"
const SFX_RADIO        := "res://.godot/imported/广场舞音乐.wav-ed3cebfe6a1e78147b4ef570ad6f1f6c.sample"
const SFX_06           := "res://.godot/imported/SFX_06.mp3-ff8dc91f5f438a2e65048ae0d83d6e02.mp3str"
const SFX_10           := "res://.godot/imported/SFX_10.mp3-8b96443f12e74277df19ff9758c4b6d9.mp3str"

var _player_a: AudioStreamPlayer = null
var _player_b: AudioStreamPlayer = null
var _active: AudioStreamPlayer = null
var _current_track: String = ""
var _tween: Tween = null


func _ready() -> void:
	# 确保 BGM 和 SFX 总线存在，都是 Master 的子总线，独立控制
	_ensure_bus("BGM")
	_ensure_bus("SFX")

	_player_a = AudioStreamPlayer.new()
	_player_a.bus = &"BGM"
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = &"BGM"
	add_child(_player_b)

	_active = _player_a


## 确保指定名称的总线存在（作为 Master 的子总线）
func _ensure_bus(p_name: String) -> void:
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == p_name:
			return
	AudioServer.add_bus(AudioServer.bus_count)
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, p_name)
	AudioServer.set_bus_send(idx, "Master")


## 交叉渐变切换到指定 BGM 曲目（用于关卡间切换）
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


## 直接播放 BGM（无淡入，用于首播）
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


## 播放一次性 SFX 音效（分配到 SFX 总线）
func play_sfx(p_path: String) -> void:
	if p_path.is_empty():
		return

	var sfx := AudioStreamPlayer.new()
	sfx.stream = load(p_path)
	sfx.bus = &"SFX"
	add_child(sfx)
	sfx.finished.connect(func():
		if is_instance_valid(sfx):
			sfx.queue_free()
	, CONNECT_ONE_SHOT)
	sfx.play()


## 播放一次性 SFX 并自动清理（完成后自动释放）
func play_sfx_oneshot(p_path: String, p_lifetime: float = 2.0) -> void:
	if p_path.is_empty():
		return

	var sfx := AudioStreamPlayer.new()
	sfx.stream = load(p_path)
	sfx.bus = &"SFX"
	add_child(sfx)
	sfx.play()

	get_tree().create_timer(p_lifetime).timeout.connect(func():
		if is_instance_valid(sfx):
			sfx.stop()
			sfx.queue_free()
	)


## 为按钮绑定鼠标悬停音效 + 按下弹跳动画
func bind_hover_sfx(p_button: BaseButton) -> void:
	if not p_button.mouse_entered.is_connected(_play_hover_sfx):
		p_button.mouse_entered.connect(_play_hover_sfx)
	if not p_button.button_down.is_connected(_play_button_press.bind(p_button)):
		p_button.button_down.connect(_play_button_press.bind(p_button))


func _play_button_press(p_btn: BaseButton) -> void:
	UIAnim.button_press(p_btn)


## 播放 UI 悬停音效（SFX 总线，限播 0.7 秒）
func _play_hover_sfx() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load(SFX_UI_CLICK)
	sfx.bus = &"SFX"
	add_child(sfx)
	sfx.play()
	get_tree().create_timer(0.7).timeout.connect(func():
		if is_instance_valid(sfx):
			sfx.stop()
			sfx.queue_free()
	)


## 设置 BGM 总线音量
func set_bgm_volume_db(p_db: float) -> void:
	var bgm_idx := AudioServer.get_bus_index("BGM")
	if bgm_idx >= 0:
		AudioServer.set_bus_volume_db(bgm_idx, p_db)


## 获取 BGM 总线当前音量
func get_bgm_volume_db() -> float:
	var bgm_idx := AudioServer.get_bus_index("BGM")
	if bgm_idx >= 0:
		return AudioServer.get_bus_volume_db(bgm_idx)
	return FULL_VOLUME


## 设置 SFX 总线音量
func set_sfx_volume_db(p_db: float) -> void:
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, p_db)


## 获取 SFX 总线当前音量
func get_sfx_volume_db() -> float:
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		return AudioServer.get_bus_volume_db(sfx_idx)
	return FULL_VOLUME
