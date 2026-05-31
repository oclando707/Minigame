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

## 魔豆首次对话：描述魔豆，对话结束后魔豆拾取并跟随玩家
@export var modou_lines: Array[String] = [
	"一颗魔豆。"
]

## 玩家带魔豆与 earth 区域交互后的对话
## 魔豆被种入土中，在未来（ZoneB）将会长成大树
@export var earth_lines: Array[String] = [
	"把魔豆埋进土里。也许未来会长出什么……"
]


## =============================================================================
## 状态变量
## =============================================================================

## 魔豆是否已被拾取并跟随玩家
var modou_picked_up: bool = false
## 跟随玩家的魔豆精灵（在 level1 根节点下，跟随玩家移动）
var modou_follower: Sprite2D = null
## 玩家是否在 earth 交互区域内
var player_near_earth: bool = false


## =============================================================================
## 场景就绪
## =============================================================================

func _ready() -> void:
	# ZoneB（另一时间线）初始隐藏，Tab 键在两者之间切换
	_set_zone_active($ZoneB, false)

	# 创建魔豆跟随精灵（初始隐藏，拾取后显示）
	_create_modou_follower()

	# 连接 earth 区域的进入/离开信号
	_connect_earth_signals()

	# 根据全局进度标记控制 ZoneB 中 tree 和 picture 的显隐
	_apply_modou_flag()


## =============================================================================
## 魔豆跟随精灵
## =============================================================================

## 创建隐藏的魔豆跟随精灵，拾取后会显示并跟随玩家身后
func _create_modou_follower() -> void:
	modou_follower = Sprite2D.new()
	modou_follower.texture = preload("res://level1asset/魔豆.png")
	modou_follower.scale = Vector2(0.1, 0.1)
	modou_follower.visible = false
	add_child(modou_follower)


## 每帧更新魔豆跟随精灵的位置（位于玩家身后）
## 根据玩家朝向（cha.flip_h）决定跟在左侧还是右侧
func _update_modou_follower() -> void:
	if not modou_follower or not modou_picked_up:
		return
	var facing_right: bool = not $Player/cha.flip_h
	# 魔豆跟在玩家身后，偏移约 60px
	var offset_x: float = -60.0 if facing_right else 60.0
	modou_follower.global_position = $Player.global_position + Vector2(offset_x, 30.0)


## =============================================================================
## 每帧处理
## =============================================================================

func _process(_delta: float) -> void:
	# 更新魔豆跟随位置
	if modou_picked_up:
		_update_modou_follower()

	# 检测 earth 区域的 F 键交互：仅在玩家在 earth 区域内 AND 魔豆已拾取时触发
	if player_near_earth and modou_picked_up and Input.is_action_just_pressed("interact"):
		_on_earth_interacted()


## =============================================================================
## earth 区域信号连接
## =============================================================================

## 连接 earth_area 的 body_entered / body_exited 信号
## earth 区域的 TextureRect 提示仅在玩家身后有魔豆时才显示
func _connect_earth_signals() -> void:
	var earth_area := $ZoneA/earth_area
	earth_area.body_entered.connect(_on_earth_entered)
	earth_area.body_exited.connect(_on_earth_exited)


## 玩家进入 earth 区域：如果魔豆已拾取，显示交互提示
func _on_earth_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_near_earth = true
		if modou_picked_up:
			_set_earth_prompt(true)


## 玩家离开 earth 区域：隐藏交互提示
func _on_earth_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_near_earth = false
		_set_earth_prompt(false)


## 设置 earth 区域 TextureRect 的可见性
## 仅在玩家携带魔豆进入该区域时显示 F 键提示
func _set_earth_prompt(visible_prompt: bool) -> void:
	var texture_rect := $ZoneA/earth_area/TextureRect as TextureRect
	if texture_rect:
		texture_rect.visible = visible_prompt


## =============================================================================
## earth 交互：玩家携带魔豆按 F 键种下魔豆
## =============================================================================

## 对话结束后执行种植逻辑：
## - 隐藏跟随的魔豆
## - 设置全局标记 modou_planted，供 ZoneB 中 tree/picture 显隐判断
func _on_earth_interacted() -> void:
	# 隐藏 earth 区域的 F 键提示
	_set_earth_prompt(false)

	DialogueManager.show_dialogue(
		earth_lines,
		$Player,
		"res://scene/textboxB.tscn",
		func():
			# 对话结束：魔豆已种入土中，不再跟随玩家
			modou_picked_up = false
			if modou_follower:
				modou_follower.visible = false
			# 设置全局进度标记：魔豆已种植
			# _apply_modou_flag 读取此标记控制 ZoneB 中 tree 和 picture 的显隐
			DialogueManager.flags["modou_planted"] = true
	)


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
			# 切换后重新检查进度标记，决定 tree 和 picture 是否可见
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
## 跳过 tree 节点：tree 的碰撞由 _apply_modou_flag 独立管理
func _set_physics_recursive(node: Node, enabled: bool) -> void:
	# tree 节点不在此处理，由 _apply_modou_flag 控制其物理状态
	if node.name == "tree":
		for child in node.get_children():
			_set_physics_recursive(child, enabled)
		return

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
## ZoneB 进度标记控制
## =============================================================================

## 根据全局进度标记控制 ZoneB 中 tree 和 picture 的显隐和碰撞
## 条件：玩家必须 (1) 拾取魔豆后 (2) 在 earth 区域交互种植
## 两个条件都满足（modou_planted=true）时，tree 和 picture 才可见且具备碰撞
## 未种下魔豆时 tree 完全不可见、不可碰撞，玩家可自由通过
func _apply_modou_flag() -> void:
	var modou_done: bool = DialogueManager.flags.get("modou_planted", false)
	var tree := $ZoneB/lv_1_background_a_2/tree

	# picture：进度控制显隐
	$ZoneB/lv_1_background_a_2/prop/picture.visible = modou_done

	# tree：进度控制显隐 + 碰撞
	# tree 是 StaticBody2D，需要同时关闭 visible 和碰撞层
	tree.visible = modou_done
	if modou_done:
		# 魔豆已种下：启用 tree 的碰撞层
		for i in range(1, 5):
			tree.set_collision_layer_value(i, true)
		tree.set_collision_mask_value(1, true)
	else:
		# 魔豆未种下：tree 完全不可见、不可碰撞
		for i in range(1, 32):
			tree.set_collision_layer_value(i, false)
		tree.set_collision_mask_value(1, false)


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


## 魔豆对话：对话结束后魔豆被拾取，跟随玩家身后
## 原始位置的魔豆消失，跟随精灵出现
## 同时检查玩家是否已在 earth 区域内：若在则显示 earth 交互提示
func _on_modou_interacted() -> void:
	DialogueManager.show_dialogue(
		modou_lines,
		$Player,
		"res://scene/textboxB.tscn",
		func():
			# 对话结束：拾取魔豆
			# 隐藏原本位置上的魔豆
			$ZoneA/modou.visible = false
			# 显示跟随精灵，开始跟随玩家身后
			modou_picked_up = true
			if modou_follower:
				modou_follower.visible = true
				_update_modou_follower()
			# 如果玩家已经站在 earth 区域内，立即显示交互提示
			if player_near_earth:
				_set_earth_prompt(true)
	)
