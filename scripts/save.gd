extends Control
## 存档/选关界面 — 由主菜单 BtnSave 打开
## 按钮显隐由 DialogueManager.flags 全局标记控制


func _ready() -> void:
	# 绑定悬停音效
	for btn in [$lv_0, $lv_1, $lv_1_2, $lv_2, $CloseBtn]:
		get_node("/root/MusicManager").bind_hover_sfx(btn)

	# lv_0 始终可用
	# lv_1：在 Level0-2_A2 的 Grass 中按 Tab 后解锁
	var lv1_unlocked: bool = DialogueManager.flags.get("level_1_unlocked", false)
	$lv_1.visible = lv1_unlocked
	$lv_1.disabled = not lv1_unlocked

	# lv_1_2：推动 feixu 后解锁
	var lv12_unlocked: bool = DialogueManager.flags.get("level_1_2_unlocked", false)
	$lv_1_2.visible = lv12_unlocked
	$lv_1_2.disabled = not lv12_unlocked

	# lv_2：通过 level_1 ZoneB Terrain/level 出口解锁
	var lv2_unlocked: bool = DialogueManager.flags.get("level_2_unlocked", false)
	$lv_2.visible = lv2_unlocked
	$lv_2.disabled = not lv2_unlocked


func _on_lv_0_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level_0_1.tscn")


func _on_lv_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level_1.tscn")


func _on_lv_1_2_pressed() -> void:
	pass  # 后续关卡，暂未实现


func _on_lv_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level_3_1.tscn")


func _on_close_pressed() -> void:
	queue_free()
