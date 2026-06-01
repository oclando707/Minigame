extends Node2D

@export var yiwu_lines: Array[String] = [
	"一节断骨。",
	"像是约莫七八岁大的小孩的小腿骨。",
	"为什么会出现在这里？",
	"\"七到八岁的小孩……这个位置……是杰克？他死了？\"",
	"\"不，不，不会的。那孩子一向聪明，他不会死的。一定不会。\"",
	"\"一截小腿骨而已……不会的……\""
]

## picture 分支对话文本
## 对话结束后弹出 "查看" / "不查看" 两个选项
@export var picture_lines: Array[String] = [
	"一张儿童画的残骸。",
	"不知为何你觉得这张画十分眼熟，心中升起些隔着雾一般的悲哀。",
	"真是奇怪。",
	"\"……我见过这张画的全貌？……想不起来\""
]


## 跟随状态
var yiwu_following: bool = false
var picture_following: bool = false


## =============================================================================
## 每帧更新：跟随玩家身后
## =============================================================================

func _process(_delta: float) -> void:
	if not yiwu_following and not picture_following:
		return

	var player := $"../../Player" as CharacterBody2D
	if not player:
		return

	var facing_right: bool = not player.get_node("cha").flip_h

	if yiwu_following:
		# yiwu 跟在玩家身后（偏移 50px），缩小至 0.15
		var offset_x: float = -50.0 if facing_right else 50.0
		var target_pos := player.global_position + Vector2(offset_x, 15.0)
		$prop/yiwu.global_position = target_pos
		$prop/yiwu.scale = Vector2(0.5, 0.5)

	if picture_following:
		# picture 跟在 yiwu 后面（偏移 85px），缩小至 0.10
		var offset_x: float = -85.0 if facing_right else 85.0
		var target_pos := player.global_position + Vector2(offset_x, 5.0)
		$prop/picture.global_position = target_pos
		$prop/picture.scale = Vector2(0.10, 0.10)


## =============================================================================
## Yiwu 对话交互：对话结束后 yiwu 跟随玩家
## =============================================================================

func _on_yiwu_interacted() -> void:
	DialogueManager.show_dialogue(
		yiwu_lines,
		$"../../Player",
		"res://scene/textboxB.tscn",
		func(): _start_following_yiwu()
	)


## =============================================================================
## Picture 分支对话交互：对话结束后 picture 跟随玩家
## =============================================================================

func _on_picture_interacted() -> void:
	DialogueManager.show_branching_dialogue(
		picture_lines,                         # 对话文本
		$"../../Player",                       # 玩家节点
		"res://scene/textboxB.tscn",           # 对话框场景
		"查看",                                # 选项按钮1 文本
		"不查看",                              # 选项按钮2 文本
		"res://scene/picturetanchaung.tscn",   # "查看"后显示的弹窗
		Callable(),                            # 选项1 回调（查看 → 弹窗由 DialogueManager 内部处理）
		Callable(),                            # 选项2 回调（不查看 → 直接关闭）
		func(): _start_following_picture()     # 最终回调：开始跟随玩家
	)


## =============================================================================
## 跟随启动：禁用 Area2D 交互 + 隐藏 F 提示 + 启用跟随
## =============================================================================

func _start_following_yiwu() -> void:
	yiwu_following = true
	var yiwu := $prop/yiwu
	yiwu.monitoring = false
	yiwu.monitorable = false
	# 隐藏 F 按键提示
	var hint := yiwu.get_node_or_null("TextureRect") as TextureRect
	if hint:
		hint.visible = false


func _start_following_picture() -> void:
	picture_following = true
	var picture := $prop/picture
	picture.monitoring = false
	picture.monitorable = false
	# 隐藏 F 按键提示
	var hint := picture.get_node_or_null("TextureRect") as TextureRect
	if hint:
		hint.visible = false
