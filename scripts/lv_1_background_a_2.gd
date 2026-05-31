extends Node2D

@export var yiwu_lines: Array[String] = [
	"你好，我是yiwu的对话内容。"
]

@export var picture_lines: Array[String] = [
	"一张儿童画的残骸。",
	"不知为何你觉得这张画十分眼熟，心中升起些隔着雾一般的悲哀。",
	"真是奇怪。",
	"“……我见过这张画的全貌？……想不起来”"
]


## Yiwu 对话交互：对话结束后可重复交互
## Player 现在位于场景根（level_1）下，ZoneB/lv_1_background_a_2 是 ZoneB 的子节点
## 需要通过 "../../Player" 路径回溯获取 Player 引用
func _on_yiwu_interacted() -> void:
	DialogueManager.show_dialogue(
		yiwu_lines,
		$"../../Player",
		"res://scene/textboxB.tscn",
		func(): $prop/yiwu.unlock_interaction()
	)


## Picture 对话交互：对话结束后可重复交互
func _on_picture_interacted() -> void:
	DialogueManager.show_dialogue(
		picture_lines,
		$"../../Player",
		"res://scene/textboxB.tscn",
		func(): $prop/picture.unlock_interaction()
	)
