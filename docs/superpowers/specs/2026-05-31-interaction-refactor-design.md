# 交互系统重构设计

**日期**: 2026-05-31
**项目**: 时空奇遇记 (Godot 4.6 2D 叙事游戏)
**目标**: 消除代码重复、统一交互与对话系统、清理项目

---

## 1. 问题分析

当前项目存在三个核心问题：

### 1.1 代码重复（4 份完全相同）
- `scripts/yiwu.gd`、`scripts/picture.gd`、`scripts/modou.gd`、`scripts/jack.gd`
- 四个文件内容完全相同（~37 行 Area2D 交互检测逻辑），每个可互动物品都复制了一份

### 1.2 交互模式不统一
- 收音机 (`radio_main.gd`) 使用独立实现，缺少 `interacted` 信号和 `unlock_interaction()`
- 与其余 4 个互动物品的行为不一致

### 1.3 对话引擎分散
- `scripts/level_1.gd` 和 `scripts/lv_1_background_a_2.gd` 各自实现了几乎相同的对话逻辑（~50 行重复）
- CanvasLayer 管理、文本推进、输入处理、清理逻辑在两处重复

### 1.4 杂物清理
- `scene/` 下有 3 个 `.tmp` 文件
- `scene/interact_zone.gd.uid` 是孤立的 UID 文件（对应 .gd 已不存在）

---

## 2. 设计目标

1. **零行为变更** —— 所有原有交互和对话行为保持不变
2. **DRY 原则** —— 消除所有重复代码
3. **统一接口** —— 所有可互动物品和对话使用同一套系统
4. **可扩展** —— 新增交互物品和对话场景只需最少的代码

---

## 3. 方案设计

### 3.1 新建: `scripts/interactable.gd`

通用 Area2D 交互组件，替代 yiwu/picture/modou/jack 四份副本，同时容纳收音机。

```
extends Area2D

## 当玩家按下交互键时触发
signal interacted

## 是否显示提示图标
@export var show_prompt: bool = true

## 是否可以多次交互 (false = 一次性交互，true = 可重复)
@export var repeatable: bool = true

## 关联的提示图标节点引用
@export var prompt_node: NodePath

var player_in_range: bool = false
var interaction_locked: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
    if player_in_range and not interaction_locked and Input.is_action_just_pressed("interact"):
        interaction_locked = true
        _show_prompt(false)
        if not repeatable:
            set_process(false)  # 一次性物品不再响应输入
        interacted.emit()

func _on_body_entered(body: Node2D) -> void:
    if body is CharacterBody2D:
        player_in_range = true
        if not interaction_locked:
            _show_prompt(true)

func _on_body_exited(body: Node2D) -> void:
    if body is CharacterBody2D:
        player_in_range = false
        _show_prompt(false)

func unlock_interaction() -> void:
    interaction_locked = false
    if player_in_range:
        _show_prompt(true)

func _show_prompt(visible: bool) -> void:
    if not show_prompt:
        return
    var node := get_node_or_null(prompt_node) if prompt_node else get_node_or_null("TextureRect")
    if node:
        node.visible = visible
```

与原代码的关键兼容点：
- `body_entered`/`body_exited`/`_process` 逻辑完全不变
- 信号名 `interacted` 不变，关卡连接保持有效
- `interaction_locked` 状态管理完全不变
- `unlock_interaction()` 签名和语义不变

新增扩展：
- `@export repeatable`: 控制是否为一次性交互。`false` 时触发后彻底禁用（如杰克对话后消失的场景）
- `@export prompt_node`: 允许自定义提示图标节点路径，默认为 `TextureRect`

### 3.2 新建: `scripts/dialogue_manager.gd` (AutoLoad)

全局对话引擎，消除关卡中的重复对话逻辑。

```
extends Node

var is_active: bool = false
var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_lines: Array[String] = []
var _current_index: int = 0
var _player: CharacterBody2D = null
var _on_finished: Callable = Callable()

func show_dialogue(
    lines: Array[String],
    player: CharacterBody2D,
    textbox_scene: String = "res://scene/textboxB.tscn",
    on_finished: Callable = Callable()
) -> void:
    if is_active:
        return  # 防止重复打开
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

    # 隐藏选项按钮（与原行为一致）
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

关键兼容：
- 冻结/解冻玩家：`set_movement_enabled(false/true)` 原样保留
- CanvasLayer + textbox 创建/销毁流程不变
- 隐藏 VBoxContainer 和 background 的行为不变
- 按任意键推进文本的 `_input` 逻辑不变
- `is_active` 守卫替代原来 `if _dialog: return` 的重复打开检查

关键改进：
- `on_finished` Callable：替代原来硬编码在 `_close_dialog` 里的特定逻辑（如 `$jack.visible = false`）

### 3.3 修改: `project.godot`

添加 AutoLoad：
```
[autoload]

DialogueManager="*res://scripts/dialogue_manager.gd"
```

仅添加 `DialogueManager` 一项 AutoLoad。

### 3.4 修改: 收音机 `scripts/radio_main.gd`

收音机有额外的状态逻辑（音乐播放/停止），需要特殊处理。保留其音乐逻辑，但交互检测改用 `interactable.gd`。

方案：场景中收音机节点使用 `interactable.gd`，在关卡脚本中连接 `interacted` 信号，由关卡脚本处理音乐开关逻辑。

原收音机的场景结构不变（`Area2D` → `interact_zone` + `MusicPlayer`）。

### 3.5 修改: 关卡脚本简化

**`scripts/level_1.gd`（简化后）:**
```
extends Node2D

@export var dialog_lines: Array[String] = [
    "..."  # 原有对话内容不改
]

func _on_jack_interacted() -> void:
    DialogueManager.show_dialogue(
        dialog_lines,
        $Player,
        "res://scene/textboxA.tscn",
        func(): $jack.visible = false
    )
```

移除：所有 `_canvas`、`_dialog`、`_current_line` 管理代码、`_show_current_line()`、`_input()`、`_close_dialog()`（约 40 行删除）。

**`scripts/lv_1_background_a_2.gd`（简化后）:**
```
extends Node2D

@export var yiwu_lines: Array[String] = [...]
@export var picture_lines: Array[String] = [...]

func _on_yiwu_interacted() -> void:
    DialogueManager.show_dialogue(yiwu_lines, $Player)

func _on_picture_interacted() -> void:
    DialogueManager.show_dialogue(picture_lines, $Player)
```

移除：所有 `_canvas`、`_dialog`、`_start_dialog()`、`_show_current_line()`、`_input()`、`_close_dialog()`、`_dialog_source` 管理（约 50 行删除）。

### 3.6 修改: 场景脚本引用

以下场景的根节点 `Area2D` 的 `script` 属性改为指向 `res://scripts/interactable.gd`：
- `scene/yiwu.tscn`
- `scene/picture.tscn`
- `scene/modou.tscn`
- `scene/jack.tscn`

不需要调整节点结构，只改脚本引用路径。原有 `signal interacted` 连接自动保留（名称相同）。

### 3.7 删除

- `scripts/yiwu.gd` + `.uid` — 并入 interactable.gd
- `scripts/picture.gd` + `.uid` — 并入 interactable.gd
- `scripts/modou.gd` + `.uid` — 并入 interactable.gd
- `scripts/jack.gd` + `.uid` — 并入 interactable.gd
- `scene/interact_zone.gd.uid` — 孤立的 UID 文件

### 3.8 清理临时文件

```
rm scene/yiwu.tscn4986730145.tmp
rm scene/yiwu.tscn4994268350.tmp
rm scene/lv_1_background_a_2.tscn5006546733.tmp
```

---

## 4. 变更总结

| 操作 | 文件 | 说明 |
|------|------|------|
| **新建** | `scripts/interactable.gd` | 通用 Area2D 交互组件 |
| **新建** | `scripts/dialogue_manager.gd` | 全局对话引擎 AutoLoad |
| **修改** | `project.godot` | 添加 DialogueManager AutoLoad |
| **修改** | `scripts/level_1.gd` | 简化为使用 DialogueManager |
| **修改** | `scripts/lv_1_background_a_2.gd` | 简化为使用 DialogueManager |
| **修改** | `scripts/radio_main.gd` | 迁移到信号驱动模式 |
| **修改** | `scene/*.tscn` (4个) | 脚本引用指向 interactable.gd |
| **删除** | `scripts/{yiwu,picture,modou,jack}.gd` (4个) | 并入 interactable.gd |
| **删除** | `scripts/{yiwu,picture,modou,jack}.gd.uid` (4个) | 配套 UID |
| **删除** | `scene/interact_zone.gd.uid` | 孤立 UID |
| **清理** | `scene/*.tmp` (3个) | 编辑器临时文件 |

**收益**: 重复代码 ~140 行 → ~0，交互脚本 5→1，对话引擎 2→1，交互行为 100% 一致。

---

## 5. 不变项（兼容性保证）

- 所有场景节点结构不变
- 所有信号名和连接关系不变
- `unlock_interaction()` API 不变
- 玩家移动冻结/解冻行为不变
- `textboxA` / `textboxB` 两个 UI 资源不变
- 对话文本内容不变
- 物理层、输入映射不变

---

## 6. 测试要点

1. 杰克对话：走近杰克按 F → 对话逐行显示 → 结束后杰克消失
2. 遗物对话：走近遗物按 F → 对话正常 → 可重复交互
3. 简笔画对话：同上
4. 魔豆交互：新物品，交互正常工作
5. 收音机：走近按 F → 显示文字并停止音乐 → 再次交互显示"收音机安静了"
6. 玩家冻结/解冻：对话期间 A/D/Space 不响应，对话结束后恢复
