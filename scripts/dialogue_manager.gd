extends Node

## 当前是否正在显示对话
var is_active: bool = false

## 每行对话显示时触发，参数为当前行索引（从0开始）
signal line_shown(index: int)

## 游戏进度标记：跨场景共享状态，用于控制节点显隐等进度相关逻辑
## 当前使用的标记：
##   modou_planted → 玩家拾取魔豆并在 earth 区域种植后为 true，控制 ZoneB 中 tree/picture 显隐
var flags: Dictionary = {}

var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_lines: Array[String] = []
var _current_index: int = 0
var _player: CharacterBody2D = null
var _on_finished: Callable = Callable()

## =============================================================================
## 分支对话（picture 用）
## =============================================================================

## 是否处于分支对话模式（对话结束后显示选项按钮，不直接关闭）
var _branching_mode: bool = false
## 选项按钮的回调
var _option1_callback: Callable = Callable()
var _option2_callback: Callable = Callable()
## 分支对话结束时最终回调（供外部使用，如 unlock_interaction）
var _branching_finished: Callable = Callable()
## "查看" 按钮点击后显示的弹窗场景路径（由调用方指定）
var _popup_scene_path: String = ""
## 弹窗实例
var _popup_instance: Control = null


## =============================================================================
## 普通对话（无选项分支）
## =============================================================================

## 显示对话
## lines: 对话文本数组
## player: 要冻结的玩家节点
## textbox_scene: 对话框场景路径（textboxA 或 textboxB）
## on_finished: 对话结束后的回调
func show_dialogue(
	lines: Array[String],
	player: CharacterBody2D,
	textbox_scene: String = "res://scene/textboxB.tscn",
	on_finished: Callable = Callable()
) -> void:
	if is_active:
		return
	if lines.is_empty():
		return

	_branching_mode = false
	is_active = true
	_player = player
	_on_finished = on_finished
	_current_lines = lines
	_current_index = 0

	player.set_movement_enabled(false)

	_canvas = CanvasLayer.new()
	player.get_parent().add_child(_canvas)

	var scene := load(textbox_scene) as PackedScene
	_dialog = scene.instantiate() as Control
	_canvas.add_child(_dialog)

	# 普通对话：隐藏选项按钮和背景
	if _dialog.has_node("VBoxContainer"):
		_dialog.get_node("VBoxContainer").visible = false
	if _dialog.has_node("background"):
		_dialog.get_node("background").visible = false

	_show_current_line()


## =============================================================================
## 分支对话：对话结束后显示两个选项按钮
## =============================================================================

## 显示带选项的分支对话
## lines:            对话文本数组
## player:           要冻结的玩家节点
## textbox_scene:    对话框场景路径
## option1_text:     第一个按钮文本（如 "查看"）
## option2_text:     第二个按钮文本（如 "不查看"）
## popup_scene_path: "查看"按钮点击后显示的弹窗场景路径（如 picturetanchaung / niupixiantanchaung）
## on_option1:       第一个按钮点击时的回调
## on_option2:       第二个按钮点击时的回调
## on_finished:      整个分支对话结束后的回调（如 unlock_interaction）
func show_branching_dialogue(
	lines: Array[String],
	player: CharacterBody2D,
	textbox_scene: String,
	option1_text: String,
	option2_text: String,
	popup_scene_path: String,
	on_option1: Callable,
	on_option2: Callable,
	on_finished: Callable = Callable()
) -> void:
	if is_active:
		return
	if lines.is_empty():
		return

	_branching_mode = true
	is_active = true
	_player = player
	_on_finished = Callable()  # 普通对话的 finished 回调不使用，由分支回调接管
	_branching_finished = on_finished
	_popup_scene_path = popup_scene_path
	_option1_callback = on_option1
	_option2_callback = on_option2
	_current_lines = lines
	_current_index = 0

	player.set_movement_enabled(false)

	_canvas = CanvasLayer.new()
	player.get_parent().add_child(_canvas)

	var scene := load(textbox_scene) as PackedScene
	_dialog = scene.instantiate() as Control
	_canvas.add_child(_dialog)

	# 分支对话：先隐藏选项按钮和背景（对话中不显示）
	if _dialog.has_node("VBoxContainer"):
		_dialog.get_node("VBoxContainer").visible = false
	if _dialog.has_node("background"):
		_dialog.get_node("background").visible = false

	# 设置按钮文本
	var vbox := _dialog.get_node("VBoxContainer")
	var btn1 := vbox.get_node("button1") as TextureButton
	var btn2 := vbox.get_node("button2") as TextureButton
	btn1.get_node("xuanxiang1").text = option1_text
	btn2.get_node("xuanxiang2").text = option2_text

	# 连接按钮 Label 颜色变化（hover/按压 → 黑色，离开 → 默认色）
	_setup_button_label_colors(btn1, btn1.get_node("xuanxiang1"))
	_setup_button_label_colors(btn2, btn2.get_node("xuanxiang2"))

	_show_current_line()


## 为 TextureButton 内的 Label 设置 hover/按压字体颜色变化
## 鼠标悬停或按压时字体变黑，离开恢复默认蓝色
## 使用 theme_override_color 而非 label_settings，因为 xuanxiang Label 只有 theme_override_fonts
func _setup_button_label_colors(btn: TextureButton, label: Label) -> void:
	# 默认颜色：白色
	var default_color := Color.WHITE
	# 初始设置默认颜色
	label.add_theme_color_override("font_color", default_color)

	btn.mouse_entered.connect(func():
		label.add_theme_color_override("font_color", Color.BLACK)
	)
	btn.mouse_exited.connect(func():
		label.add_theme_color_override("font_color", default_color)
	)
	btn.button_down.connect(func():
		label.add_theme_color_override("font_color", Color.BLACK)
	)
	btn.button_up.connect(func():
		if btn.is_hovered():
			label.add_theme_color_override("font_color", Color.BLACK)
		else:
			label.add_theme_color_override("font_color", default_color)
	)


## 覆盖 _show_current_line：分支模式下行末显示选项而非关闭对话
func _show_current_line() -> void:
	if _current_index < _current_lines.size():
		_dialog.get_node("text").set("text", _current_lines[_current_index])
		line_shown.emit(_current_index)
	else:
		if _branching_mode:
			# 分支模式：对话文本结束后显示选项按钮
			_show_options()
		else:
			# 普通模式：直接关闭对话
			_close_dialogue()


## 显示选项按钮并连接点击信号
func _show_options() -> void:
	var vbox := _dialog.get_node("VBoxContainer")
	vbox.visible = true

	var btn1 := vbox.get_node("button1") as TextureButton
	var btn2 := vbox.get_node("button2") as TextureButton

	# 断开旧连接后重连，防止重复绑定
	if btn1.pressed.is_connected(_on_view_pressed):
		btn1.pressed.disconnect(_on_view_pressed)
	btn1.pressed.connect(_on_view_pressed)

	if btn2.pressed.is_connected(_on_dont_view_pressed):
		btn2.pressed.disconnect(_on_dont_view_pressed)
	btn2.pressed.connect(_on_dont_view_pressed)


## "查看" 按钮：隐藏对话框，显示由 _popup_scene_path 指定的弹窗
## 弹窗场景由 show_branching_dialogue() 的调用方指定
func _on_view_pressed() -> void:
	# 隐藏对话框内容
	if _dialog:
		_dialog.visible = false

	# 实例化指定弹窗到同一 CanvasLayer
	if _popup_scene_path.is_empty():
		return
	var popup_scene := load(_popup_scene_path) as PackedScene
	_popup_instance = popup_scene.instantiate() as Control
	_canvas.add_child(_popup_instance)

	# 连接叉号按钮：关闭弹窗并结束对话
	var chahao := _popup_instance.get_node("chahao") as TextureButton
	chahao.pressed.connect(_on_chahao_pressed)


## "不查看" 按钮：直接结束分支对话
func _on_dont_view_pressed() -> void:
	_close_branching()


## 叉号按钮：关闭弹窗，结束整个分支对话
func _on_chahao_pressed() -> void:
	_close_branching()


## 关闭分支对话：清理所有 UI，恢复玩家，触发最终回调
func _close_branching() -> void:
	if _popup_instance:
		_popup_instance.queue_free()
		_popup_instance = null

	# 清理对话框 CanvasLayer
	if _canvas:
		_canvas.queue_free()
		_canvas = null
	_dialog = null
	_current_lines.clear()

	if _player:
		_player.set_movement_enabled(true)
		_player = null

	is_active = false
	_branching_mode = false

	# 触发分支对话的最终回调（如 picture.unlock_interaction）
	if _branching_finished.is_valid():
		_branching_finished.call()
	_branching_finished = Callable()
	_option1_callback = Callable()
	_option2_callback = Callable()


## =============================================================================
## 普通对话的 _input / _close_dialogue
## =============================================================================

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	# 分支模式显示选项时不响应键盘输入（由按钮接管）
	if _branching_mode and _current_index >= _current_lines.size():
		return
	if event is InputEventKey and event.pressed:
		_current_index += 1
		_show_current_line()
		get_viewport().set_input_as_handled()


func _close_dialogue() -> void:
	if _canvas:
		_canvas.queue_free()
		_canvas = null
	_dialog = null
	_current_lines.clear()

	if _player:
		_player.set_movement_enabled(true)
		_player = null

	is_active = false

	if _on_finished.is_valid():
		_on_finished.call()
	_on_finished = Callable()
