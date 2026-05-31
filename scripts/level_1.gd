extends Node2D

@export var dialog_lines: Array[String] = [
	"“帕克！还记得我们的时间胶囊埋在哪里吗！”",
	"犬吠，像是在回应",
	"“好帕克好帕克！我就知道你也记得！”",
	"“不过我本来是打算和魔豆埋在一起的来着……”",
	"小男孩的声音渐渐小下去，像是自言自语。",
	"“哇啊！”",
	"他扭头看见了你，被吓了一跳，带着小狗跑开了"
]

@export var modou_lines: Array[String] = [
	"一颗魔豆。"
]


func _on_jack_interacted() -> void:
	DialogueManager.show_dialogue(
		dialog_lines,
		$Player,
		"res://scene/textboxA.tscn",
		func(): $jack.visible = false
	)


func _on_modou_interacted() -> void:
	DialogueManager.show_dialogue(
		modou_lines,
		$Player
	)
