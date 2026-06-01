extends Node2D

const BGM_ZONE_A := "res://.godot/imported/德米特里的植物园2.wav-7c682378035f8d37dd3a36771b04a236.sample"
const BGM_ZONE_B := "res://.godot/imported/缧绁.wav-3597d7d2e1e1fb5c6fd55bdbe5992fe6.sample"

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
	"地上有什么东西？","
	像豆子一样……也许这就是那个小男孩说的魔豆。",
	"在童话中，魔豆会长成参天的藤蔓，为人提供攀升的路途……",
	"“要找个地方种下去试试吗？”"
]

## 玩家带魔豆与 earth 区域交互后的对话
## 魔豆被种入土中，在未来（ZoneB）将会长成大树
@export var earth_lines: Array[String] = [
	"把魔豆埋进土里。也许未来会长出什么……"
]

## niupixian 分支对话文本（ZoneA 场景中）
## 对话结束后弹出 "查看" / "不查看" 两个选项
@export var niupixian_lines: Array[String] = [
	"墙上贴着一张牛皮癣广告。"
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

## 玩家是否在 feixu 的检测范围内（ZoneB）
var player_near_feixu: bool = false
## 是否正在推动 feixu（长按 F 键过程中）
var is_pushing: bool = false
## F 键按住累计时长（秒）
var push_hold_time: float = 0.0
## feixu 是否已被推落（防止重复触发）
var feixu_pushed: bool = false
## 标记 kong 碰撞体是否已禁用
var kong_disabled: bool = false
## 标记 dixiashi 是否已被 feixu 撞击并切换为损坏状态
var dixiashi_toggled: bool = false


## =============================================================================
## 场景就绪
## =============================================================================

func _ready() -> void:
	# 设置摄像机右边界（level_1 场景宽度为 1920）
	$Player/Camera2D.limit_right = 1920
	get_node("/root/MusicManager").play(BGM_ZONE_A)

	# ZoneB（另一时间线）初始隐藏，Tab 键在两者之间切换
	_set_zone_active($ZoneB, false)

	# 创建魔豆跟随精灵（初始隐藏，拾取后显示）
	_create_modou_follower()

	# 连接 earth 区域的进入/离开信号
	_connect_earth_signals()

	# 连接 feixu 的检测区域信号（ZoneB）
	_connect_feixu_signals()

	# 连接 ZoneB Terrain/level 关卡出口触发器
	_connect_level_exit()

	# 连接 niupixian 的 interacted 信号（嵌套在实例化场景内，需代码连接）
	get_node("ZoneA/LV1-background/niupixian").interacted.connect(_on_niupixian_interacted)

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


## 控制魔豆跟随精灵的可见性
## 切换到 ZoneB 时隐藏，切回 ZoneA 时恢复（仅在已拾取时显示）
func _set_modou_visible(visible_flag: bool) -> void:
	if not modou_follower:
		return
	if not modou_picked_up:
		return
	modou_follower.visible = visible_flag


## =============================================================================
## 每帧处理
## =============================================================================

func _process(delta: float) -> void:
	# 更新魔豆跟随位置
	if modou_picked_up:
		_update_modou_follower()

	# ZoneA：earth 区域的 F 键交互（仅在玩家在 earth 区域内 AND 魔豆已拾取时触发）
	if player_near_earth and modou_picked_up and Input.is_action_just_pressed("interact"):
		_on_earth_interacted()

	# ZoneB：feixu 推动逻辑
	_process_feixu_push(delta)

	# feixu 推落后：监测是否已跌落到 kong 区域并禁用碰撞
	_check_kong_fall()


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
func _set_earth_prompt(visible_prompt: bool) -> void:
	var texture_rect := $ZoneA/earth_area/TextureRect as TextureRect
	if texture_rect:
		texture_rect.visible = visible_prompt


## =============================================================================
## earth 交互：玩家携带魔豆按 F 键种下魔豆
## =============================================================================

func _on_earth_interacted() -> void:
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
			DialogueManager.flags["modou_planted"] = true
	)


## =============================================================================
## feixu 信号连接（ZoneB）
## =============================================================================

## 连接 feixu 子节点的 detect_area 进入/离开信号
## feixu 是 RigidBody2D，detect_area 是其子节点 Area2D
## 同时连接 feixu 的 body_entered 信号用于检测碰撞（dixiashi 等）
func _connect_feixu_signals() -> void:
	var feixu := $ZoneB/lv_1_background_a_2/prop/feixu as RigidBody2D
	if not feixu:
		push_error("_connect_feixu_signals: feixu 节点未找到")
		return

	var detect_area := feixu.get_node_or_null("detect_area") as Area2D
	if not detect_area:
		push_error("_connect_feixu_signals: detect_area 节点未找到，请用 Godot 编辑器打开 feixu.tscn 确认 detect_area 子节点存在")
		return

	# 监听玩家进入/离开 feixu 检测范围
	detect_area.body_entered.connect(_on_feixu_detect_entered)
	detect_area.body_exited.connect(_on_feixu_detect_exited)

	# 监听 feixu 碰撞：用于检测 feixu 碰到 dixiashi 后切换精灵/碰撞体
	feixu.body_entered.connect(_on_feixu_body_collided)


## 玩家进入 feixu 的检测范围：显示 F 键推动提示
func _on_feixu_detect_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_near_feixu = true
		if not feixu_pushed:
			_set_feixu_prompt(true)


## 玩家离开 feixu 的检测范围：隐藏 F 键提示，取消正在进行的推动
func _on_feixu_detect_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_near_feixu = false
		_set_feixu_prompt(false)
		# 玩家离开检测区域时取消推动
		_cancel_push()


## 设置 feixu 的 F 键提示可见性
func _set_feixu_prompt(visible_prompt: bool) -> void:
	var feixu := $ZoneB/lv_1_background_a_2/prop/feixu
	if not feixu:
		return
	var texture_rect := feixu.get_node_or_null("detect_area/TextureRect") as TextureRect
	if texture_rect:
		texture_rect.visible = visible_prompt


## =============================================================================
## feixu 推动逻辑（ZoneB）
## =============================================================================

## 每帧处理 feixu 的推动交互
## 按住 F 键累计时长，达到 1 秒后推动 feixu 向左跌落
## 提前松手则取消，不影响 feixu 位置
func _process_feixu_push(delta: float) -> void:
	# 对话中或 feixu 已推落时不做处理
	if DialogueManager.is_active or feixu_pushed:
		return

	if is_pushing:
		if Input.is_action_pressed("interact"):
			# 按住 F 键，累计时长
			push_hold_time += delta
			if push_hold_time >= 1.0:
				# 达到 1 秒阈值：推动成功
				_complete_push()
		else:
			# 提前松手：推动取消
			_cancel_push()
	else:
		# 未在推动状态：检测 F 键按下以开始推动
		# 仅在玩家处于 feixu 检测范围内且当前在 ZoneB 时触发
		if player_near_feixu and $ZoneB.visible and Input.is_action_just_pressed("interact"):
			_start_push()


## 开始推动：冻结玩家移动，切换 push 动画并水平翻转
func _start_push() -> void:
	is_pushing = true
	push_hold_time = 0.0

	# 冻结玩家正常移动
	$Player.set_movement_enabled(false)
	# 切换到推动动画（set_movement_enabled 会设为 idle，在此覆盖）
	$Player/AnimationPlayer.current_animation = "push"
	# 水平翻转 push 动画：玩家面朝左侧推动 feixu
	$Player/cha.flip_h = true

	_set_feixu_prompt(false)


## 推动成功：唤醒 feixu RigidBody2D 并向左上方施加冲量
## feixu 从 paltfarm 平台跌落后与 Terrain 的 kong 碰撞体接触
func _complete_push() -> void:
	is_pushing = false
	push_hold_time = 0.0
	feixu_pushed = true
	DialogueManager.flags["level_1_2_unlocked"] = true

	# 恢复玩家正常移动和动画
	$Player.set_movement_enabled(true)

	# 唤醒并推动 feixu RigidBody2D
	var feixu := $ZoneB/lv_1_background_a_2/prop/feixu as RigidBody2D
	if not feixu:
		return
	# can_sleep=false 已在 .tscn 中设置，保证冲量持续生效
	# 向左上方施加冲量使其飞出 paltfarm 平台
	feixu.apply_central_impulse(Vector2(-300, -150))

	# 播放废墟坠落音效
	var sfx := AudioStreamPlayer2D.new()
	sfx.bus = &"SFX"
	sfx.stream = load("res://.godot/imported/freesound_community-stones-falling-6375.mp3-79b06d30e8ec1c91c233dfbb86a82178.mp3str")
	add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()


## 推动取消：玩家松手太早，feixu 不动，恢复玩家状态
func _cancel_push() -> void:
	if not is_pushing:
		return
	is_pushing = false
	push_hold_time = 0.0

	# 恢复玩家正常移动和动画
	$Player.set_movement_enabled(true)

	# 如果玩家仍在检测范围内，重新显示 F 键提示
	if player_near_feixu and not feixu_pushed:
		_set_feixu_prompt(true)


## =============================================================================
## feixu 推落后监测：kong 碰撞体 + dixiashi 碰撞切换
## =============================================================================

## feixu 推落后持续监测：
## - 跌落到 kong 区域高度以下 → 禁用 kong 碰撞体
## - 碰到 dixiashi → 切换 dixiashi 的精灵和碰撞体（完好→损坏）
func _check_kong_fall() -> void:
	var feixu := $ZoneB/lv_1_background_a_2/prop/feixu as RigidBody2D
	if not feixu:
		return

	# kong 碰撞体：feixu 落到平台下方时禁用
	if feixu_pushed and not kong_disabled and feixu.global_position.y > 750:
		_disable_kong()

	# dixiashi 碰撞切换：feixu 的 body_entered 信号在碰撞时调用 _on_feixu_body_collided


## 禁用 lv_1_background_a_2 中 Terrain/Terrain 下的 kong 碰撞体
## 禁用后玩家可以自由通过该区域
func _disable_kong() -> void:
	var terrain_sprite := $ZoneB/lv_1_background_a_2/Terrain as Sprite2D
	if not terrain_sprite:
		return
	var terrain_body := terrain_sprite.get_node_or_null("Terrain") as StaticBody2D
	if not terrain_body:
		return
	var kong := terrain_body.get_node_or_null("kong") as CollisionShape2D
	if kong:
		kong.disabled = true
		kong_disabled = true


## feixu 与 StaticBody2D 碰撞时触发（RigidBody2D.body_entered）
## feixu 碰到 dixiashi 时切换精灵和碰撞体（完好 → 损坏）
func _on_feixu_body_collided(body: Node) -> void:
	if not feixu_pushed or dixiashi_toggled:
		return
	if body is StaticBody2D and body.name == "dixiashi":
		# 播放撞击音效
		var sfx := AudioStreamPlayer2D.new()
		sfx.stream = load("res://.godot/imported/levigoodway-vine-boom-sound-410789.mp3-4dbeababaf6566c78604366589af2c61.mp3str")
		sfx.bus = &"SFX"
		add_child(sfx)
		sfx.finished.connect(sfx.queue_free)
		sfx.play()

		_toggle_dixiashi.call_deferred(body as StaticBody2D)


## 切换 dixiashi 精灵和碰撞体：完好(hao/hao2) → 损坏(huai/huai2/huai3)
## 使用 set_deferred 修改碰撞状态，避免 "Can't change state while flushing queries" 错误
func _toggle_dixiashi(di: StaticBody2D) -> void:
	dixiashi_toggled = true
	di.get_node("hao").visible = false
	di.get_node("huai").visible = true
	(di.get_node("hao2") as CollisionPolygon2D).set_deferred("disabled", true)
	(di.get_node("huai2") as CollisionPolygon2D).set_deferred("disabled", false)
	(di.get_node("huai3") as CollisionPolygon2D).set_deferred("disabled", false)


## =============================================================================
## 场景切换（Tab 键）：在同一地点的两个时间之间切换
## =============================================================================

func _input(event: InputEvent) -> void:
	if DialogueManager.is_active:
		return
	# 推动过程中禁止切换场景
	if is_pushing:
		return
	if event.is_action_pressed("switch"):
		if $ZoneA.visible:
			_set_zone_active($ZoneA, false)
			_set_zone_active($ZoneB, true)
			_apply_modou_flag()
			# 切换到 ZoneB（未来）→ 隐藏魔豆跟随精灵
			_set_modou_visible(false)
			get_node("/root/MusicManager").crossfade(BGM_ZONE_B)
		else:
			_set_zone_active($ZoneB, false)
			_set_zone_active($ZoneA, true)
			# 切换回 ZoneA（现在）→ 恢复魔豆跟随精灵
			_set_modou_visible(true)
			get_node("/root/MusicManager").crossfade(BGM_ZONE_A)


## 设置区域的激活状态（可见性 + 物理碰撞）
func _set_zone_active(zone: Node, active: bool) -> void:
	zone.visible = active
	_set_physics_recursive(zone, active)


## 递归遍历节点子树，按类型启用/禁用物理交互
## 隐藏区域中的 StaticBody2D 碰撞层清零，Area2D 关闭检测
## 跳过 tree / feixu 节点：由各自的逻辑独立管理物理状态
func _set_physics_recursive(node: Node, enabled: bool) -> void:
	# tree / feixu 节点不在此处理，由各自的逻辑独立管理物理状态
	if node.name == "tree" or node.name == "feixu":
		for child in node.get_children():
			_set_physics_recursive(child, enabled)
		return

	if node is Area2D:
		node.monitoring = enabled
		node.monitorable = enabled
	elif node is StaticBody2D:
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
	var tree := $ZoneB/lv_1_background_a_2/prop/tree

	# picture：进度控制显隐
	$ZoneB/lv_1_background_a_2/prop/picture.visible = modou_done

	# tree：进度控制显隐 + 碰撞
	tree.visible = modou_done
	if modou_done:
		for i in range(1, 5):
			tree.set_collision_layer_value(i, true)
		tree.set_collision_mask_value(1, true)
	else:
		for i in range(1, 32):
			tree.set_collision_layer_value(i, false)
		tree.set_collision_mask_value(1, false)


## =============================================================================
## 交互回调：ZoneA（现在 / level_1 内容）
## =============================================================================

## Jack 对话：对话结束后 Jack 消失（不可重复交互）
## 第2行"犬吠，像是在回应"显示时和对话结束时各播放一次狗叫
func _on_jack_interacted() -> void:
	# 创建临时音效播放器
	var bark_player := AudioStreamPlayer2D.new()
	bark_player.stream = preload("res://level1asset/第一关/狗叫.wav")
	bark_player.bus = &"SFX"
	add_child(bark_player)

	# 监听每行对话显示：第2行（index 1）时播放狗叫
	var _on_line: Callable = func(index: int):
		if index == 1:
			bark_player.play()

	DialogueManager.line_shown.connect(_on_line)

	DialogueManager.show_dialogue(
		dialog_lines,
		$Player,
		"res://scene/textboxA.tscn",
		func():
			# 对话结束：再播放一次狗叫，然后断开信号、移除播放器
			bark_player.play()
			# 等音效播完再清理
			await get_tree().create_timer(0.5).timeout
			DialogueManager.line_shown.disconnect(_on_line)
			bark_player.queue_free()
			$ZoneA/jack.visible = false
	)


## 魔豆对话：对话结束后魔豆被拾取，跟随玩家身后
## 原始位置的魔豆消失，跟随精灵出现
func _on_modou_interacted() -> void:
	DialogueManager.show_dialogue(
		modou_lines,
		$Player,
		"res://scene/textboxB.tscn",
		func():
			$ZoneA/modou.visible = false
			modou_picked_up = true
			if modou_follower:
				modou_follower.visible = true
				_update_modou_follower()
			if player_near_earth:
				_set_earth_prompt(true)
	)


## =============================================================================
## ZoneB Terrain/level 关卡出口触发器
## =============================================================================

## 连接 ZoneB/lv_1_background_a_2/Terrain/level Area2D 的 body_entered
func _connect_level_exit() -> void:
	var level_area := $ZoneB/lv_1_background_a_2/Terrain/level as Area2D
	if not level_area:
		push_error("_connect_level_exit: Terrain/level Area2D 未找到")
		return
	level_area.body_entered.connect(_on_level_exit_entered)


## 玩家触碰 Terrain/level 触发器 -> 解锁 lv_2 并切换到 level_3_1
func _on_level_exit_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	DialogueManager.flags["level_2_unlocked"] = true
	get_tree().change_scene_to_file("res://scene/level_3_1.tscn")


## niupixian 分支对话交互：对话结束后弹出 "查看" / "不查看" 选项
## - "查看" → 显示 niupixiantanchaung 弹窗，点击叉号关闭
## - "不查看" → 直接结束对话
## 对话结束后按 F 仍可再次与 niupixian 交互
func _on_niupixian_interacted() -> void:
	DialogueManager.show_branching_dialogue(
		niupixian_lines,
		$Player,
		"res://scene/textboxB.tscn",
		"查看",
		"不查看",
		"res://scene/niupixiantanchaung.tscn",
		Callable(),
		Callable(),
		func(): $"ZoneA/LV1-background/niupixian".unlock_interaction()
	)
