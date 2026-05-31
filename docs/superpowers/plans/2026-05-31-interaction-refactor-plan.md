# 交互系统重构 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 消除 4 份重复的交互脚本、统一对话引擎为 AutoLoad、清理项目杂物，所有原有行为保持不变。

**Architecture:** 创建 `interactable.gd`（通用 Area2D 交互组件）替代 4 份副本 + 收音机；创建 `dialogue_manager.gd`（AutoLoad）替代两个关卡中重复的对话逻辑。场景节点结构不变，只改脚本引用。

**Tech Stack:** Godot 4.6, GDScript

---

## 文件变更总览

| 操作 | 文件 | 说明 |
|------|------|------|
| 新建 | `scripts/interactable.gd` | 通用 Area2D 交互组件 |
| 新建 | `scripts/dialogue_manager.gd` | AutoLoad 全局对话引擎 |
| 修改 | `project.godot` | 添加 DialogueManager AutoLoad |
| 修改 | `scene/yiwu.tscn` | 脚本引用 → interactable.gd |
| 修改 | `scene/picture.tscn` | 脚本引用 → interactable.gd |
| 修改 | `scene/modou.tscn` | 脚本引用 → interactable.gd, 添加 visible=false |
| 修改 | `scene/jack.tscn` | 脚本引用 → interactable.gd |
| 修改 | `scene/radio.tscn` | 脚本引用 → interactable.gd, 移除 InteractZone |
| 修改 | `scripts/radio_main.gd` | 简化为音乐逻辑 |
| 修改 | `scripts/level_1.gd` | 使用 DialogueManager |
| 修改 | `scripts/lv_1_background_a_2.gd` | 使用 DialogueManager |
| 删除 | `scripts/yiwu.gd` + `.uid` | 并入 interactable.gd |
| 删除 | `scripts/picture.gd` + `.uid` | 并入 interactable.gd |
| 删除 | `scripts/modou.gd` + `.uid` | 并入 interactable.gd |
| 删除 | `scripts/jack.gd` + `.uid` | 并入 interactable.gd |
| 删除 | `scene/interact_zone.gd.uid` | 孤立 UID |
| 清理 | `scene/*.tmp` (3个) | 编辑器临时文件 |

---

### Task 1: 创建 `scripts/interactable.gd`

**Files:**
- Create: `scripts/interactable.gd`

- [ ] **Step 1: 写入 interactable.gd**

```gdscript
extends Area2D
class_name Interactable

## 玩家进入范围并按下交互键时触发
signal interacted

## 是否显示提示图标（TextureRect 或 FHint Label）
@export var show_prompt: bool = true

var player_in_range: bool = false
var interaction_locked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_in_range and not interaction_locked and Input.is_action_just_pressed("interact"):
		interaction_locked = true
		_set_prompt_visible(false)
		interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
		if not interaction_locked:
			_set_prompt_visible(true)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		_set_prompt_visible(false)


## 解锁交互，允许再次触发（由对话系统调用）
func unlock_interaction() -> void:
	interaction_locked = false
	if player_in_range:
		_set_prompt_visible(true)


## 隐藏或显示提示图标
func _set_prompt_visible(v: bool) -> void:
	if not show_prompt:
		return
	# 优先找 TextureRect（yiwu/picture/modou）
	var node := get_node_or_null("TextureRect") as TextureRect
	if node:
		node.visible = v
	# 同时也处理 FHint Label（jack 独有）
	var label := get_node_or_null("FHint") as Label
	if label:
		label.visible = v
```

- [ ] **Step 2: 运行 Godot 生成 .uid 文件**

```bash
cd E:/gamejam/minigamejam/clone/Minigame
godot --headless --quit 2>&1 || echo "Godot may not be in PATH; UID will be generated on next editor open"
```

> **注意:** 如果 `godot` 命令不在 PATH 中，跳过此步骤。`.uid` 文件会在下次编辑器打开场景时自动生成。

- [ ] **Step 3: 提交**

```bash
git add scripts/interactable.gd
git commit -m "feat: 创建通用交互组件 Interactable"
```

---

### Task 2: 创建 `scripts/dialogue_manager.gd` (AutoLoad)

**Files:**
- Create: `scripts/dialogue_manager.gd`

- [ ] **Step 1: 写入 dialogue_manager.gd**

```gdscript
extends Node

## 当前是否正在显示对话
var is_active: bool = false

var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_lines: Array[String] = []
var _current_index: int = 0
var _player: CharacterBody2D = null
var _on_finished: Callable = Callable()


## 显示对话
## lines: 对话文本数组
## player: 要冻结的玩家节点
## textbox_scene: 对话框场景路径（textboxA 或 textboxB）
## on_finished: 对话结束后的回调
func show_dialogue(
	lines: Array[String],
	player: CharacterBody2D,
	textbox_scene: String = "res://scene/textboxB.tscn",
	on_finished: Callable = Callable()
) -> void:
	if is_active:
		return
	if lines.is_empty():
		return

	is_active = true
	_player = player
	_on_finished = on_finished
	_current_lines = lines
	_current_index = 0

	player.set_movement_enabled(false)

	_canvas = CanvasLayer.new()
	player.get_parent().add_child(_canvas)

	var scene := load(textbox_scene) as PackedScene
	_dialog = scene.instantiate() as Control
	_canvas.add_child(_dialog)

	# 隐藏选项按钮和背景（与原行为一致）
	if _dialog.has_node("VBoxContainer"):
		_dialog.get_node("VBoxContainer").visible = false
	if _dialog.has_node("background"):
		_dialog.get_node("background").visible = false

	_show_current_line()


func _show_current_line() -> void:
	if _current_index < _current_lines.size():
		_dialog.get_node("text").set("text", _current_lines[_current_index])
	else:
		_close_dialogue()


func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventKey and event.pressed:
		_current_index += 1
		_show_current_line()
		get_viewport().set_input_as_handled()


func _close_dialogue() -> void:
	if _canvas:
		_canvas.queue_free()
		_canvas = null
	_dialog = null
	_current_lines.clear()

	if _player:
		_player.set_movement_enabled(true)
		_player = null

	is_active = false

	if _on_finished.is_valid():
		_on_finished.call()
	_on_finished = Callable()
```

- [ ] **Step 2: 运行 Godot 生成 .uid**

```bash
cd E:/gamejam/minigamejam/clone/Minigame
godot --headless --quit 2>&1 || echo "Skip if godot not in PATH"
```

- [ ] **Step 3: 提交**

```bash
git add scripts/dialogue_manager.gd
git commit -m "feat: 创建全局对话管理器 DialogueManager"
```

---

### Task 3: 配置 `project.godot` — 注册 AutoLoad

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: 添加 DialogueManager AutoLoad**

打开 `project.godot`，在文件末尾添加：

```ini
[autoload]

DialogueManager="*res://scripts/dialogue_manager.gd"
```

具体操作 — 在 `project.godot` 末尾添加以上三行。如果 `[autoload]` section 已存在则只添加 `DialogueManager=` 一行。

- [ ] **Step 2: 提交**

```bash
git add project.godot
git commit -m "config: 注册 DialogueManager 为 AutoLoad"
```

---

### Task 4: 更新交互场景脚本引用 (yiwu/picture/modou/jack → interactable.gd)

**Files:**
- Modify: `scene/yiwu.tscn`
- Modify: `scene/picture.tscn`
- Modify: `scene/modou.tscn`
- Modify: `scene/jack.tscn`

每个场景只需要修改 ext_resource 行中的脚本路径，以及确保 `visible = false` 在 TextureRect 上。

- [ ] **Step 1: 更新 `scene/yiwu.tscn`**

将第 3 行：
```
[ext_resource type="Script" uid="uid://bhqp2el546ngq" path="res://scripts/yiwu.gd" id="1_ja8of"]
```
改为（去掉 UID，只保留 path，id 不变）：
```
[ext_resource type="Script" path="res://scripts/interactable.gd" id="1_ja8of"]
```

`script = ExtResource("1_ja8of")` 行不变。

- [ ] **Step 2: 更新 `scene/picture.tscn`**

将第 4 行：
```
[ext_resource type="Script" uid="uid://cqnm3qb07vuw" path="res://scripts/picture.gd" id="1_u80yu"]
```
改为：
```
[ext_resource type="Script" path="res://scripts/interactable.gd" id="1_u80yu"]
```

- [ ] **Step 3: 更新 `scene/modou.tscn`**

将第 4 行：
```
[ext_resource type="Script" uid="uid://bhsgsxro50drj" path="res://scripts/modou.gd" id="1_ioceq"]
```
改为：
```
[ext_resource type="Script" path="res://scripts/interactable.gd" id="1_ioceq"]
```

同时修复 TextureRect 缺少 `visible = false` 的问题 —— TextureRect 节点（第 22-28 行）当前没有 `visible = false`，添加它：
```
[node name="TextureRect" type="TextureRect" parent="." unique_id=849371551]
visible = false
offset_left = -114.00001
...
```

- [ ] **Step 4: 更新 `scene/jack.tscn`**

将第 4 行：
```
[ext_resource type="Script" uid="uid://muin8voupjuq" path="res://scripts/jack.gd" id="1_c7sxc"]
```
改为：
```
[ext_resource type="Script" path="res://scripts/interactable.gd" id="1_c7sxc"]
```

> **注意:** jack.tscn 有 FHint Label + TextureRect 两个提示节点，interactable.gd 的 `_set_prompt_visible()` 会同时处理两者。

- [ ] **Step 5: 提交**

```bash
git add scene/yiwu.tscn scene/picture.tscn scene/modou.tscn scene/jack.tscn
git commit -m "refactor: 交互场景脚本引用迁移到 interactable.gd"
```

---

### Task 5: 迁移收音机

**Files:**
- Modify: `scene/radio.tscn`
- Modify: `scripts/radio_main.gd`

收音机当前未被任何关卡使用，可以自由重构。目标：使用 `interactable.gd` 处理交互检测，保留音乐逻辑。

- [ ] **Step 1: 更新 `scene/radio.tscn` — 更换脚本引用并移除 InteractZone**

将第 4 行：
```
[ext_resource type="Script" uid="uid://dd3c7058a2sot" path="res://scripts/radio_main.gd" id="3_jddx7"]
```
改为：
```
[ext_resource type="Script" path="res://scripts/interactable.gd" id="3_jddx7"]
```

删除整个 InteractZone 子节点（第 29-33 行）及其 connection（第 35-36 行）：
```
[node name="InteractZone" type="Area2D" parent="." unique_id=235233509]

[node name="CollisionShape2D" type="CollisionShape2D" parent="InteractZone" unique_id=1070364584]
position = Vector2(740, 741)
shape = SubResource("RectangleShape2D_osh7q")

[connection signal="body_entered" from="InteractZone" to="." method="_on_interact_zone_body_entered"]
[connection signal="body_exited" from="InteractZone" to="." method="_on_interact_zone_body_exited"]
```

> **说明:** interactable.gd 已通过根 Area2D 处理 body_entered/body_exited，不再需要子 InteractZone。

- [ ] **Step 2: 重写 `scripts/radio_main.gd` 为音乐控制器**

原来 `radio_main.gd` 是场景根节点的脚本。现在根节点使用 `interactable.gd`，所以需要一个小脚本添加到 MusicPlayer 或其他子节点上，或者让收音机的音乐逻辑由使用它的关卡处理。

由于收音机尚未被任何关卡使用，最干净的做法是创建一个轻量的配套脚本。但为了简单，直接更新现有的 radio_main.gd —— 它将变成一个可以用在子节点上的音乐辅助脚本：

```gdscript
extends Node

@onready var _music: AudioStreamPlayer2D = $"../MusicPlayer"
var is_playing: bool = true


func _ready() -> void:
	_music.play()


## 由关卡脚本在接收到 interacted 信号后调用
func toggle_music() -> void:
	if is_playing:
		_music.stop()
		is_playing = false
	else:
		_music.play()
		is_playing = true
```

> **注意:** 将来放置收音机的关卡脚本按如下模式使用：
> ```gdscript
> func _on_radio_interacted() -> void:
>     $Radio/MusicController.toggle_music()
>     DialogueManager.show_dialogue(
>         ["这台收音机正大声放着广场舞音乐……" if $Radio/MusicController.is_playing else "收音机安静了。"],
>         $Player
>     )
> ```
> 本次重构不涉及添加收音机到关卡，只确保代码干净可用。

- [ ] **Step 3: 提交**

```bash
git add scene/radio.tscn scripts/radio_main.gd
git commit -m "refactor: 收音机迁移到 interactable.gd 信号模式"
```

---

### Task 6: 简化 `scripts/level_1.gd`

**Files:**
- Modify: `scripts/level_1.gd`

- [ ] **Step 1: 检查当前 `_on_jack_interacted` 连接**

`scene/level_1.tscn` 第 24 行有：
```
[connection signal="interacted" from="jack" to="." method="_on_jack_interacted"]
```
此信号连接保持不变（interactable.gd 发送同名 `interacted` 信号）。

- [ ] **Step 2: 重写 `scripts/level_1.gd`**

```gdscript
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
```

> **注意:** 保留了原来杰克对话结束后 `$jack.visible = false` 的行为（通过 `on_finished` 回调）。新增了魔豆交互处理方法。

- [ ] **Step 3: 在 `scene/level_1.tscn` 中添加 modou 信号连接**

在 `level_1.tscn` 中添加一行：
```
[connection signal="interacted" from="modou" to="." method="_on_modou_interacted"]
```

- [ ] **Step 4: 提交**

```bash
git add scripts/level_1.gd scene/level_1.tscn
git commit -m "refactor: level_1 使用 DialogueManager，添加魔豆交互"
```

---

### Task 7: 简化 `scripts/lv_1_background_a_2.gd`

**Files:**
- Modify: `scripts/lv_1_background_a_2.gd`

- [ ] **Step 1: 重写 `scripts/lv_1_background_a_2.gd`**

```gdscript
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
	DialogueManager.show_dialogue(yiwu_lines, $Player)


func _on_picture_interacted() -> void:
	DialogueManager.show_dialogue(picture_lines, $Player)
```

> **关键兼容:** DialogueManager 的 `_close_dialogue()` 结束后自动调用玩家的 `set_movement_enabled(true)`。然后由关卡场景的信号连接链触发 `unlock_interaction()`。由于 interactable.gd 保留了 `unlock_interaction()`，原 `lv_1_background_a_2.gd` 中的 `if _dialog_source and _dialog_source.has_method("unlock_interaction"): _dialog_source.unlock_interaction()` 逻辑现在由 interactive.gd 的 `interacted` 信号链自然处理 —— 不需要额外代码。
>
> **等等——这里有兼容问题！** 在原代码中，`_on_yiwu_interacted` 和 `_on_picture_interacted` 通过 `_start_dialog` → `_close_dialog` 路径调用 `unlock_interaction()`。现在 `DialogueManager._close_dialog()` 不调用 `unlock_interaction()`，所以需要在对话结束后手动解锁。
>
> **修复:** 在 `DialogueManager._close_dialog()` 中不处理 unlock（因为 DialogueManager 不知道哪个物品触发了对话）。改为在信号处理函数中利用 `on_finished` 回调来解锁。

等一下——原本的设计 issue: `lv_1_background_a_2.gd` 中需要 unlock 物品以便重复交互。如果用 `on_finished: func(): $prop/yiwu.unlock_interaction()` 来处理，代码会稍长但清晰。

让我更新方式 —— 对 lv_1_background_a_2，每个交互物品需要 unlock：

- [ ] **Step 1 (修订): 重写 `scripts/lv_1_background_a_2.gd`**

```gdscript
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
```

- [ ] **Step 2: 提交**

```bash
git add scripts/lv_1_background_a_2.gd
git commit -m "refactor: lv_1_background_a_2 使用 DialogueManager"
```

---

### Task 8: 删除重复文件并清理

**Files:**
- Delete: `scripts/yiwu.gd`, `scripts/yiwu.gd.uid`
- Delete: `scripts/picture.gd`, `scripts/picture.gd.uid`
- Delete: `scripts/modou.gd`, `scripts/modou.gd.uid`
- Delete: `scripts/jack.gd`, `scripts/jack.gd.uid`
- Delete: `scene/interact_zone.gd.uid`
- Delete: `scene/yiwu.tscn4986730145.tmp`
- Delete: `scene/yiwu.tscn4994268350.tmp`
- Delete: `scene/lv_1_background_a_2.tscn5006546733.tmp`

- [ ] **Step 1: 删除重复脚本文件**

```bash
cd E:/gamejam/minigamejam/clone/Minigame
rm scripts/yiwu.gd scripts/yiwu.gd.uid
rm scripts/picture.gd scripts/picture.gd.uid
rm scripts/modou.gd scripts/modou.gd.uid
rm scripts/jack.gd scripts/jack.gd.uid
```

- [ ] **Step 2: 删除孤立 UID**

```bash
rm scene/interact_zone.gd.uid
```

- [ ] **Step 3: 清理临时文件**

```bash
rm "scene/yiwu.tscn4986730145.tmp"
rm "scene/yiwu.tscn4994268350.tmp"
rm "scene/lv_1_background_a_2.tscn5006546733.tmp"
```

- [ ] **Step 4: 提交**

```bash
git add -A
git commit -m "chore: 删除重复脚本和临时文件"
```

---

### Task 9: Godot 验证

**Files:**
- Verify: 所有修改的场景和脚本

- [ ] **Step 1: 用 Godot 打开项目验证**

```bash
cd E:/gamejam/minigamejam/clone/Minigame
godot --headless --quit 2>&1
```

检查输出中没有错误（特别是脚本引用错误、信号连接错误）。

如果 godot 不在 PATH 中，手动在 Godot 编辑器中打开项目，检查：
- Output 面板无错误
- 场景可以正常打开
- Remote 面板中节点树完整

- [ ] **Step 2: 验证场景加载**

依次打开以下场景，确认无错误：
1. `res://scene/时空奇遇记.tscn`（主菜单）
2. `res://scene/level_1.tscn`（关卡1）
3. `res://scene/lv_1_background_a_2.tscn`（关卡变体）

- [ ] **Step 3: 手动功能验证清单**

1. **杰克对话:** 运行 level_1 → 走近杰克 → 按 F → 对话逐行显示直到结束 → 杰克消失 → 玩家恢复控制
2. **遗物交互:** 运行 lv_1_background_a_2 → 走近遗物按 F → 对话显示 → 结束后可再次触发
3. **简笔画交互:** 同上
4. **魔豆交互:** 运行 level_1 → 走近魔豆按 F → 对话显示
5. **玩家冻结:** 对话期间按 A/D/Space 无响应
6. **玩家解冻:** 对话结束后可以正常移动

- [ ] **Step 4: 最终提交**

```bash
git status
# 确认无意外变更
git add -A
git commit -m "verify: 所有交互系统重构完成并通过验证"
```

---

## 实施顺序依赖

```
Task 1 (interactable.gd)
  └→ Task 4 (场景引用迁移) ─┐
  └→ Task 5 (收音机迁移)   ├→ Task 8 (删除旧文件)
                              │
Task 2 (dialogue_manager.gd)  │
  └→ Task 3 (project.godot)   │
      └→ Task 6 (level_1)    ─┤
      └→ Task 7 (lv_bg_a2)   ─┘
                                  └→ Task 9 (验证)
```

Tasks 1-3 必须先完成（创建新组件），Tasks 4-7 可并行（都迁移到新组件），Task 8 在所有迁移完成后进行，Task 9 最后验证。
