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


func _on_yiwu_interacted() -> void:
	DialogueManager.show_dialogue(
		yiwu_lines,
		$Player,
		"res://scene/textboxB.tscn",
		func(): $prop/yiwu.unlock_interaction()
	)


func _on_picture_interacted() -> void:
	DialogueManager.show_dialogue(
		picture_lines,
		$Player,
		"res://scene/textboxB.tscn",
		func(): $prop/picture.unlock_interaction()
	)
