extends Area2D
## 机器人 — 平和巡逻 / 攻击追逐 / 休眠
## 靠近按F → 对话二选一（激怒→攻击  /  离开→保持和平）

enum State { PEACEFUL, ATTACKING, DORMANT }

@export var patrol_speed: float = 80.0
@export var attack_speed: float = 200.0
@export var patrol_left: float = -200.0
@export var patrol_right: float = 200.0
@export var initial_state: State = State.PEACEFUL

var state: State
var _start_x: float = 0.0
var _patrol_dir: float = -1.0
var _target_player: CharacterBody2D = null
var _player_in_range: bool = false
var _talking: bool = false
var _spawn_x: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var f_hint: Sprite2D = $FHint


func _ready() -> void:
	# 全局机器人关闭 → 直接休眠
	if DialogueManager.flags.get("robots_deactivated", false):
		_set_state(State.DORMANT)
		return
	_set_state(initial_state)
	_start_x = position.x
	add_to_group("robots")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	match state:
		State.PEACEFUL:
			_patrol(delta)
		State.ATTACKING:
			_chase(delta)
			_check_kill()
		State.DORMANT:
			pass


func _input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if _talking:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		if state == State.PEACEFUL:
			_show_choice_dialogue()


# ==================== 巡逻 ====================
func _patrol(delta: float) -> void:
	position.x += _patrol_dir * patrol_speed * delta
	if position.x <= _start_x + patrol_left:
		_patrol_dir = 1.0
		sprite.flip_h = false
	elif position.x >= _start_x + patrol_right:
		_patrol_dir = -1.0
		sprite.flip_h = true


# ==================== 追逐 ====================
func _chase(delta: float) -> void:
	if not _target_player:
		return
	# 玩家躲进草里 → 丢失目标
	if _target_player.is_in_group("hidden"):
		_target_player = null
		_set_state(State.PEACEFUL)
		return
	var dir: float = sign(_target_player.global_position.x - global_position.x)
	position.x += dir * attack_speed * delta
	sprite.flip_h = dir > 0


# ==================== 玩家靠近/离开 ====================
func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	if body.is_in_group("hidden"):
		return

	if state == State.ATTACKING:
		# 攻击模式碰到 → 传送回出生点上方，从天而降
		_respawn_player(body)
		return

	if state == State.PEACEFUL:
		_player_in_range = true
		f_hint.visible = true
		_target_player = body
		_spawn_x = body.global_position.x


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_in_range = false
		f_hint.visible = false


# ==================== 对话选择 ====================
func _show_choice_dialogue() -> void:
	_talking = true
	f_hint.visible = false

	# 冻结玩家
	if _target_player == null:
		for b in get_overlapping_bodies():
			if b is CharacterBody2D:
				_target_player = b
				break
	if _target_player and _target_player.has_method("set_movement_enabled"):
		_target_player.set_movement_enabled(false)

	var canvas := CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)

	var textbox := preload("res://scene/textboxB.tscn").instantiate() as Control
	canvas.add_child(textbox)

	# 显示选项按钮
	var vbox := textbox.get_node("VBoxContainer") as VBoxContainer
	vbox.visible = true

	var btn1 := vbox.get_node("button1") as TextureButton
	var btn2 := vbox.get_node("button2") as TextureButton

	# 给按钮加文字标签
	_add_btn_label(btn1, "激怒它")
	_add_btn_label(btn2, "离开")

	btn1.pressed.connect(func():
		_choice_anger(canvas)
	)
	btn2.pressed.connect(func():
		_choice_leave(canvas)
	)


func _add_btn_label(btn: TextureButton, text_str: String) -> void:
	var label := Label.new()
	label.text = text_str
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(0, 0.4, 0.77, 1))
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(label)


func _choice_anger(canvas: CanvasLayer) -> void:
	_cleanup_dialogue(canvas)
	_set_state(State.ATTACKING)
	_talking = false


func _choice_leave(canvas: CanvasLayer) -> void:
	_cleanup_dialogue(canvas)
	_talking = false
	# 即使离开，下次再靠近时仍然会触发对话


func _cleanup_dialogue(canvas: CanvasLayer) -> void:
	if _target_player and _target_player.has_method("set_movement_enabled"):
		_target_player.set_movement_enabled(true)
	if canvas:
		canvas.queue_free()


# ==================== 攻击碰撞检测（逐帧） ====================
func _check_kill() -> void:
	for body in get_overlapping_bodies():
		if body is CharacterBody2D and not body.is_in_group("hidden"):
			_respawn_player(body)
			return


# ==================== 玩家重生（从天而降） ====================
func _respawn_player(body: CharacterBody2D) -> void:
	# 传送到出生点正上方，自然掉落 → 戏剧性重生效果
	body.velocity = Vector2.ZERO
	body.global_position = Vector2(_spawn_x, -200.0)
	# 机器人恢复巡逻
	_set_state(State.PEACEFUL)
	_player_in_range = false
	f_hint.visible = false
	_target_player = null


# ==================== 状态切换 ====================
func set_dormant() -> void:
	_set_state(State.DORMANT)


func set_attacking() -> void:
	_set_state(State.ATTACKING)


func _set_state(new_state: State) -> void:
	state = new_state
	var tex_path: String = ""
	match state:
		State.PEACEFUL:
			tex_path = "res://minigame_assets/Level_01/Level_01_A2/机器人_三状态/机器人 _平和.png"
		State.ATTACKING:
			tex_path = "res://minigame_assets/Level_01/Level_01_A2/机器人_三状态/机器人_攻击.png"
		State.DORMANT:
			tex_path = "res://minigame_assets/Level_01/Level_01_A2/机器人_三状态/机器人_休眠.png"
	if sprite and not tex_path.is_empty():
		sprite.texture = load(tex_path)
