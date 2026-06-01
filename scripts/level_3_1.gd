extends Node2D
## 关卡3-1：时空分割线
## Tab 切换操控 A1(过去) ↔ A2(未来)，摄像机跟随两人中点
## A1 关闭毁灭装置 → 全体机器人休眠 → A2 安全通过


var active_key: String = "A1"

@onready var a1: CharacterBody2D = $A1
@onready var a2: CharacterBody2D = $A2
@onready var anchor: Node2D = $CameraAnchor


func _ready() -> void:
	# 禁用玩家自带的相机，使用关卡相机
	a1.get_node("Camera2D").enabled = false
	a2.get_node("Camera2D").enabled = false
	# A1初始朝左，A2朝右 —— 两人面对面
	a1.get_node("cha").flip_h = true
	# 初始：A1 可动，A2 冻结
	a1.set_movement_enabled(true)
	a2.set_movement_enabled(false)
	_update_camera()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("switch"):
		_swap_player()
	_update_camera()


func _swap_player() -> void:
	if active_key == "A1":
		a1.set_movement_enabled(false)
		a2.set_movement_enabled(true)
		active_key = "A2"
	else:
		a2.set_movement_enabled(false)
		a1.set_movement_enabled(true)
		active_key = "A1"


func _update_camera() -> void:
	var mx: float = (a1.global_position.x + a2.global_position.x) / 2.0
	anchor.global_position.x = mx
