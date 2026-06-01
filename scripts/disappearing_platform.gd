extends AnimatableBody2D
## 定时消失平台 — 可见/消失 循环
## 挂到 AnimatableBody2D 上，需有 Sprite2D、CollisionShape2D、Timer 子节点


@export var visible_time: float = 3.0   ## 可见持续时间（秒）
@export var hidden_time: float = 2.0    ## 消失持续时间（秒）
@export var start_visible: bool = true  ## 初始是否可见
@export var start_delay: float = 0.0    ## 首次切换前的延迟（秒），用于实现依次消失


func _ready() -> void:
	sync_to_physics = false
	if start_delay > 0.0:
		# 延迟阶段：保持初始状态，等待 start_delay 秒后再开始循环
		_apply_state(start_visible)
		$Timer.wait_time = start_delay
		$Timer.timeout.connect(_on_delay_end)
	else:
		$Timer.wait_time = visible_time if start_visible else hidden_time
		$Timer.timeout.connect(_toggle)
	$Timer.start()


func _on_delay_end() -> void:
	# 延迟结束，首次切换并进入正常循环
	$Timer.timeout.disconnect(_on_delay_end)
	$Timer.timeout.connect(_toggle)
	_toggle()


func _toggle() -> void:
	_apply_state(not visible)


func _apply_state(v: bool) -> void:
	visible = v
	$CollisionShape2D.set_deferred("disabled", not v)
	$Sprite2D.visible = v
	$Timer.wait_time = visible_time if v else hidden_time
