extends Control
## 设置菜单 — 音量控制界面（BGM / SFX）。
## 滑块左端 = 静音 (-40 dB)，右端 = 满音量 (0 dB)。
## ApplyBtn 确认保存；CancelBtn 恢复初始值并关闭；
## ExitBtn 若未点 Apply 则恢复初始值并关闭。
##
## 注意：TextureProgressBar 的 texture_over 在 Godot 4 中是静态叠加，
## 因此用独立的 TextureRect 作为可拖拽的滑块 thumb。

signal closed

const MIN_DB: float = -40.0
const FULL_DB: float = 0.0

var _initial_bgm_db: float
var _initial_sfx_db: float
var _applied: bool = false

var _dragging_bar: TextureProgressBar = null
var _thumb_bgm: TextureRect = null
var _thumb_sfx: TextureRect = null


func _ready() -> void:
	var mgr := get_node("/root/MusicManager")

	# 记录打开时的音量
	_initial_bgm_db = mgr.get_bgm_volume_db()
	_initial_sfx_db = mgr.get_sfx_volume_db()

	# 初始化滑条值
	$BGM.value = _db_to_slider(_initial_bgm_db)
	$SFX.value = _db_to_slider(_initial_sfx_db)

	# 创建可拖动的滑块 thumb
	_thumb_bgm = _create_thumb($BGM)
	_thumb_sfx = _create_thumb($SFX)
	_update_thumb_position($BGM, _thumb_bgm)
	_update_thumb_position($SFX, _thumb_sfx)

	# 实时预览：拖动滑条立刻生效
	$BGM.value_changed.connect(_on_bgm_changed)
	$SFX.value_changed.connect(_on_sfx_changed)

	# 给滑条绑定鼠标拖拽事件
	for bar: TextureProgressBar in [$BGM, $SFX]:
		bar.mouse_filter = Control.MOUSE_FILTER_STOP
		bar.gui_input.connect(_on_bar_gui_input.bind(bar))

	# 按钮悬停音效
	for btn: TextureButton in [$ExitBtn, $CancelBtn, $ApplyBtn]:
		mgr.bind_hover_sfx(btn)

	$ApplyBtn.pressed.connect(_on_apply)
	$ExitBtn.pressed.connect(_on_exit)
	$CancelBtn.pressed.connect(_on_cancel)


## 创建滑块 thumb TextureRect（使用和滑条 texture_over 相同的贴图）
func _create_thumb(bar: TextureProgressBar) -> TextureRect:
	var thumb := TextureRect.new()
	thumb.texture = bar.texture_over
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.size = bar.texture_over.get_size()
	# 将 thumb 放到 bar 的坐标系内
	bar.add_child(thumb)
	return thumb


## 根据滑条值更新 thumb 位置（左端 0 → 右端 100）
func _update_thumb_position(bar: TextureProgressBar, thumb: TextureRect) -> void:
	var ratio: float = bar.value / maxf(bar.max_value, 1.0)
	var x: float = ratio * bar.size.x - thumb.size.x * 0.5
	var y: float = (bar.size.y - thumb.size.y) * 0.5
	thumb.position = Vector2(x, y)


func _on_bar_gui_input(event: InputEvent, bar: TextureProgressBar) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging_bar = bar
				_set_bar_from_mouse(bar, event.position.x)
			else:
				_dragging_bar = null
	elif event is InputEventMouseMotion and _dragging_bar == bar:
		_set_bar_from_mouse(bar, event.position.x)


func _set_bar_from_mouse(bar: TextureProgressBar, local_x: float) -> void:
	var ratio: float = clampf(local_x / maxf(bar.size.x, 1.0), 0.0, 1.0)
	bar.value = ratio * bar.max_value
	# 更新对应 thumb 位置
	if bar == $BGM:
		_update_thumb_position(bar, _thumb_bgm)
	else:
		_update_thumb_position(bar, _thumb_sfx)


## BGM 滑块拖动 → BGM 总线
func _on_bgm_changed(value: float) -> void:
	var mgr := get_node("/root/MusicManager")
	mgr.set_bgm_volume_db(_slider_to_db(value))
	_update_thumb_position($BGM, _thumb_bgm)


## SFX 滑块拖动 → SFX 总线
func _on_sfx_changed(value: float) -> void:
	var mgr := get_node("/root/MusicManager")
	mgr.set_sfx_volume_db(_slider_to_db(value))
	_update_thumb_position($SFX, _thumb_sfx)


## Apply：标记已保存
func _on_apply() -> void:
	_applied = true


## Exit：未保存则恢复，然后关闭
func _on_exit() -> void:
	if not _applied:
		_restore_initial()
	closed.emit()


## Cancel：未保存则恢复，然后关闭
func _on_cancel() -> void:
	if not _applied:
		_restore_initial()
	closed.emit()


## 恢复音量和滑条到打开菜单前的值
func _restore_initial() -> void:
	var mgr := get_node("/root/MusicManager")
	mgr.set_bgm_volume_db(_initial_bgm_db)
	mgr.set_sfx_volume_db(_initial_sfx_db)

	$BGM.value = _db_to_slider(_initial_bgm_db)
	$SFX.value = _db_to_slider(_initial_sfx_db)
	_update_thumb_position($BGM, _thumb_bgm)
	_update_thumb_position($SFX, _thumb_sfx)


func _db_to_slider(db: float) -> float:
	return clampf((db - MIN_DB) / (FULL_DB - MIN_DB) * 100.0, 0.0, 100.0)


func _slider_to_db(value: float) -> float:
	return (value / 100.0) * (FULL_DB - MIN_DB) + MIN_DB
