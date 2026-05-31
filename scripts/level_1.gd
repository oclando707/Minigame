extends Node2D

## =============================================================================
## 对话文本导出（ZoneA / 现在）
## =============================================================================

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


## =============================================================================
## 场景就绪
## =============================================================================

func _ready() -> void:
	# ZoneB（另一时间线）初始隐藏，Tab 键在两者之间切换
	_set_zone_active($ZoneB, false)

	# 根据 modou_interacted 进度标记控制 ZoneB 中 tree 和 picture 的显隐
	# 玩家必须先与 level_1 的魔豆对话，tree 和 picture 才会在 ZoneB 中出现
	_apply_modou_flag()


## 根据全局进度标记控制 ZoneB 中 tree 和 picture 的显隐
func _apply_modou_flag() -> void:
	var modou_done: bool = DialogueManager.flags.get("modou_interacted", false)
	$ZoneB/lv_1_background_a_2/prop/picture.visible = modou_done
	$ZoneB/lv_1_background_a_2/tree.visible = modou_done


## =============================================================================
## 场景切换（Tab 键）：在同一地点的两个时间之间切换
## =============================================================================

## 按 Tab 键切换 ZoneA ↔ ZoneB
## ZoneA 和 ZoneB 是同一地点不同时间——切换时只改变可见性和物理状态
func _input(event: InputEvent) -> void:
	if DialogueManager.is_active:
		return
	if event.is_action_pressed("switch"):
		if $ZoneA.visible:
			# 当前在 ZoneA（现在）→ 隐藏 ZoneA，显示 ZoneB（另一时间）
			_set_zone_active($ZoneA, false)
			_set_zone_active($ZoneB, true)
			# 切换后重新检查进度标记（modou 可能刚刚对话完）
			_apply_modou_flag()
		else:
			# 当前在 ZoneB（另一时间）→ 隐藏 ZoneB，显示 ZoneA（现在）
			_set_zone_active($ZoneB, false)
			_set_zone_active($ZoneA, true)


## 设置区域的激活状态（可见性 + 物理碰撞）
## active=true  → 显示节点，启用所有物理体
## active=false → 隐藏节点，禁用所有物理体（避免与显示中的另一区域碰撞重叠）
func _set_zone_active(zone: Node, active: bool) -> void:
	zone.visible = active
	_set_physics_recursive(zone, active)


## 递归遍历节点子树，按类型启用/禁用物理交互
## 隐藏区域中的 StaticBody2D 碰撞层清零，Area2D 关闭检测
func _set_physics_recursive(node: Node, enabled: bool) -> void:
	if node is Area2D:
		# Area2D：控制 monitoring（检测其他物体）和 monitorable（被其他物体检测）
		node.monitoring = enabled
		node.monitorable = enabled
	elif node is StaticBody2D:
		# StaticBody2D：通过碰撞层控制是否参与物理碰撞
		# 禁用时将全部碰撞层清零；启用时恢复默认层（层 1-4）
		for i in range(1, 5):
			node.set_collision_layer_value(i, enabled)
		node.set_collision_mask_value(1, enabled)
	for child in node.get_children():
		_set_physics_recursive(child, enabled)


## =============================================================================
## 交互回调：ZoneA（现在 / level_1 内容）
## =============================================================================

## Jack 对话：对话结束后 Jack 消失（不可重复交互）
func _on_jack_interacted() -> void:
	DialogueManager.show_dialogue(
		dialog_lines,
		$Player,
		"res://scene/textboxA.tscn",
		func(): $ZoneA/jack.visible = false
	)


## 魔豆对话：对话结束后解锁二次交互，并设置全局进度标记
## 标记由 _apply_modou_flag 读取，控制 ZoneB（另一时间）中 tree 和 picture 的显隐
func _on_modou_interacted() -> void:
	DialogueManager.show_dialogue(
		modou_lines,
		$Player,
		"res://scene/textboxB.tscn",
		func():
			$ZoneA/modou.unlock_interaction()
			DialogueManager.flags["modou_interacted"] = true
	)
