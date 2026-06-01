extends AnimatableBody2D
## 电梯 — 重力感应装置
## 玩家站上平台自动上升，离开顶部平台自动下降
## 到达顶部后自动打开 A2 侧的门


@export var rise_distance: float = 300.0
@export var rise_duration: float = 2.0
@export var door_to_open: NodePath   ## 到达顶部后打开的门

enum State { BOTTOM, MOVING_UP, TOP, MOVING_DOWN }
var _state: State = State.BOTTOM
var _player_in_range: bool = false
var _bottom_y: float
var _top_y: float
var _door_opened: bool = false

## 玩家脚底偏移: collision(0,8) + capsule_half_height(125) + radius(59) = 192
const PLAYER_FEET_OFFSET: float = 192.0
## 平台表面在电梯本地坐标中的 y 值: platform_collision.y(35) - shape_half_height(14.5) = 20.5
const PLATFORM_SURFACE_LOCAL_Y: float = 20.5


func _ready() -> void:
	sync_to_physics = false
	_bottom_y = global_position.y
	_top_y = _bottom_y - rise_distance


func _physics_process(_delta: float) -> void:
	# 运行中不检测状态变化，避免中途打断
	if _state == State.MOVING_UP or _state == State.MOVING_DOWN:
		return

	var player_on_platform := false
	for body in $TriggerZone.get_overlapping_bodies():
		if body is CharacterBody2D:
			var feet_y: float = body.global_position.y + PLAYER_FEET_OFFSET
			var platform_surface_y: float = global_position.y + PLATFORM_SURFACE_LOCAL_Y
			if abs(feet_y - platform_surface_y) < 15.0:
				player_on_platform = true
				break

	if player_on_platform and not _player_in_range:
		_player_in_range = true
		if _state == State.BOTTOM:
			_go_up()
	elif not player_on_platform and _player_in_range:
		_player_in_range = false
		if _state == State.TOP:
			_go_down()


func _go_up() -> void:
	_state = State.MOVING_UP
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position:y", _top_y, rise_duration)
	tw.finished.connect(_on_arrive_top)


func _go_down() -> void:
	_state = State.MOVING_DOWN
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position:y", _bottom_y, rise_duration)
	tw.finished.connect(func(): _state = State.BOTTOM)


func _on_arrive_top() -> void:
	_state = State.TOP
	if _door_opened:
		return
	_door_opened = true
	if door_to_open.is_empty():
		return
	var door := get_node(door_to_open) as StaticBody2D
	if door and door.has_method("open"):
		door.open()
