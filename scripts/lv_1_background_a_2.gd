extends Node2D

@export var yiwu_lines: Array[String] = [
	"你好，我是yiwu的对话内容。"
]

## picture 分支对话文本
## 对话结束后弹出 "查看" / "不查看" 两个选项
@export var picture_lines: Array[String] = [
	"一张儿童画的残骸。",
	"不知为何你觉得这张画十分眼熟，心中升起些隔着雾一般的悲哀。",
	"真是奇怪。",
	"“……我见过这张画的全貌？……想不起来”"
]


## Yiwu 对话交互：对话结束后可重复交互
## Player 位于场景根（level_1）下，通过 "../../Player" 路径获取
func _on_yiwu_interacted() -> void:
	DialogueManager.show_dialogue(
		yiwu_lines,
		$"../../Player",
		"res://scene/textboxB.tscn",
		func(): $prop/yiwu.unlock_interaction()
	)


## Picture 分支对话交互：对话结束后弹出 "查看" / "不查看" 选项
## - "查看" → 显示 picturetanchaung 弹窗，点击叉号关闭
## - "不查看" → 直接结束对话
## 对话结束后按 F 仍可再次与 picture 交互
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
		func(): $prop/picture.unlock_interaction()  # 最终回调：解锁交互，允许再次按 F
	)
