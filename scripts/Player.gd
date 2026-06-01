extends CharacterBody2D

# 跳跃 250px：v₀y = √(2×800×250) ≈ 632
# 跳跃 300px：v_x = 300 ÷ (2×632÷800) ≈ 190
const GRAVITY: float = 800.0
const JUMP_VELOCITY: float = -632.0
const MOVE_SPEED: float = 400.0
const STEP_INTERVAL := 0.35    # 脚步音效间隔（秒）

var can_move: bool = true
var _step_timer: float = 0.0
var _was_on_floor: bool = true

@onready var _step_sfx: AudioStreamPlayer2D = $StepSFX
@onready var _land_sfx: AudioStreamPlayer2D = $LandSFX


func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		$AnimationPlayer.current_animation = "idle"


func _physics_process(delta: float) -> void:
	if not can_move:
		return
	# 重力（空中下落）
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 水平移动：A=左, D=右（Input Map 中为 "left" / "right"）
	var dir: float = Input.get_axis("left", "right")
	velocity.x = dir * MOVE_SPEED

	# 跳跃（只有在地面时才可起跳，抛物线轨迹固定）
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()

	# 落地检测
	if is_on_floor() and not _was_on_floor:
		_land_sfx.play()
	_was_on_floor = is_on_floor()

	# 行走音效
	if is_on_floor() and abs(dir) > 0.0:
		_step_timer += delta
		if _step_timer >= STEP_INTERVAL:
			_step_timer = 0.0
			_step_sfx.play()
	else:
		_step_timer = 0.0

	update_animation(dir)


func update_animation(dir: float) -> void:
	if not is_on_floor():
		# 空中：上升 jump，下降 fall
		if velocity.y < 0.0:
			$AnimationPlayer.current_animation = "jump"
		else:
			$AnimationPlayer.current_animation = "fall"
	elif dir != 0.0:
		# 地面 + 移动 walk
		$AnimationPlayer.current_animation = "walk"
	else:
		# 地面 + 无输入 idle
		$AnimationPlayer.current_animation = "idle"

	# 水平翻转：A键翻转、D键不翻转（空中同样生效）
	if dir != 0.0:
		$cha.flip_h = dir < 0.0
