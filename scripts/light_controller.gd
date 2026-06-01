extends Node2D
## 联控灯光控制器
## Light1 红/绿  Light2 蓝(固定)  Light3 红/绿
## 每4秒随机切换 Light1/Light3 的红绿
## 正确顺序 红→蓝→绿 时，所有碰撞关闭，A1 安全通过


const LightBeam = preload("res://scripts/light_beam.gd")

@export var switch_interval: float = 4.0

var _timer: float = 0.0

@onready var light1: StaticBody2D = $Light1
@onready var light2: StaticBody2D = $Light2
@onready var light3: StaticBody2D = $Light3


func _ready() -> void:
	light2.light_color = LightBeam.LightColor.BLUE
	_randomize()
	_update_collisions()


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= switch_interval:
		_timer = 0.0
		_randomize()
		_update_collisions()


func _randomize() -> void:
	light1.light_color = LightBeam.LightColor.RED if randi() % 2 == 0 else LightBeam.LightColor.GREEN
	light3.light_color = LightBeam.LightColor.RED if randi() % 2 == 0 else LightBeam.LightColor.GREEN


func _update_collisions() -> void:
	# 正确顺序 红→蓝→绿 = 安全
	var is_safe: bool = (
		light1.light_color == LightBeam.LightColor.RED and
		light2.light_color == LightBeam.LightColor.BLUE and
		light3.light_color == LightBeam.LightColor.GREEN
	)
	for light in [light1, light2, light3]:
		if light.has_node("CollisionShape2D"):
			light.get_node("CollisionShape2D").set_deferred("disabled", is_safe)
