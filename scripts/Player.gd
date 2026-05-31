extends CharacterBody2D

# 跳跃 250px：v₀y = √(2×800×250) ≈ 632
# 跳跃 300px：v_x = 300 ÷ (2×632÷800) ≈ 190
const GRAVITY: float = 800.0
const JUMP_VELOCITY: float = -632.0
const MOVE_SPEED: float = 400.0

var can_move: bool = true


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
