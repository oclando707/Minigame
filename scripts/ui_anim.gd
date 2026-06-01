extends Node
## UI 动画工具库 — AutoLoad 单例
## 提供常用的 UI 面板弹入/弹出、滑入、按钮反馈、错开展示等方法。
## 所有方法默认绑定到节点生命周期，节点被释放时动画自动取消。

const POP_IN_DURATION := 0.3
const POP_OUT_DURATION := 0.2
const SLIDE_DURATION := 0.35
const BUTTON_PRESS_DURATION := 0.12
const STAGGER_DURATION := 0.2
const STAGGER_INTERVAL := 0.05


func _ready() -> void:
	# 确保 UI 动画在游戏暂停时也能运行
	process_mode = Node.PROCESS_MODE_ALWAYS


## 面板弹入：从指定缩放/fade 动画到正常大小和位置
## control: 目标 Control 节点
## p_duration: 动画时长（秒）
func pop_in(control: Control, p_duration: float = POP_IN_DURATION) -> void:
	var tween := create_tween().bind_node(control)
	tween.set_parallel(true)

	# 初始状态
	control.modulate.a = 0.0
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.8, 0.8)

	# 弹入动画
	tween.tween_property(control, "modulate:a", 1.0, p_duration)
	tween.tween_property(control, "scale", Vector2.ONE, p_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


## 面板弹出：缩小 + 淡出，完成后执行回调（通常用于 queue_free）
## control: 目标 Control 节点
## on_finished: 弹出完成后的回调
## p_duration: 动画时长（秒）
func pop_out(control: Control, on_finished: Callable = Callable(), p_duration: float = POP_OUT_DURATION) -> void:
	var tween := create_tween().bind_node(control)
	tween.set_parallel(true)

	control.pivot_offset = control.size * 0.5

	tween.tween_property(control, "modulate:a", 0.0, p_duration).set_ease(Tween.EASE_IN)
	tween.tween_property(control, "scale", Vector2(0.9, 0.9), p_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)

	if on_finished.is_valid():
		tween.chain().tween_callback(on_finished)


## 从下方滑入：向上移动 + 淡入
## control: 目标 Control 节点
## p_offset_y: 滑入前向下偏移量（像素）
## p_duration: 动画时长（秒）
func slide_up(control: Control, p_offset_y: float = 80.0, p_duration: float = SLIDE_DURATION) -> void:
	var tween := create_tween().bind_node(control)
	tween.set_parallel(true)

	# 记录最终位置并设置初始状态
	var final_pos: Vector2 = control.position
	control.position.y += p_offset_y
	control.modulate.a = 0.0

	tween.tween_property(control, "position", final_pos, p_duration) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, p_duration) \
		.set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)


## 按钮按下弹跳：缩小→恢复
## btn: 目标按钮
## p_duration: 动画时长（秒）
func button_press(btn: Control, p_duration: float = BUTTON_PRESS_DURATION) -> void:
	var tween := create_tween().bind_node(btn)

	var original_scale: Vector2 = btn.scale

	tween.tween_property(btn, "scale", original_scale * 0.92, p_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", original_scale, p_duration * 1.5) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


## 按钮错开展示：一组按钮依次从 0 缩放弹入
## buttons: 按钮数组
## p_duration: 单个按钮动画时长（秒）
## p_interval: 按钮之间的延迟（秒）
func stagger_reveal(buttons: Array, p_duration: float = STAGGER_DURATION, p_interval: float = STAGGER_INTERVAL) -> void:
	var tween := create_tween()

	for i in buttons.size():
		var btn: Control = buttons[i]
		btn.scale = Vector2.ZERO
		btn.pivot_offset = btn.size * 0.5

		tween.tween_property(btn, "scale", Vector2.ONE, p_duration) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)

		if i < buttons.size() - 1:
			tween.tween_interval(p_interval)


## 淡入：纯透明度 0→1
func fade_in(control: Control, p_duration: float = 0.3) -> void:
	var tween := create_tween().bind_node(control)
	control.modulate.a = 0.0
	tween.tween_property(control, "modulate:a", 1.0, p_duration)


## 淡出：纯透明度 1→0，完成后回调
func fade_out(control: Control, on_finished: Callable = Callable(), p_duration: float = 0.2) -> void:
	var tween := create_tween().bind_node(control)
	tween.tween_property(control, "modulate:a", 0.0, p_duration).set_ease(Tween.EASE_IN)
	if on_finished.is_valid():
		tween.tween_callback(on_finished)
