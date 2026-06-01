extends StaticBody2D
## 联控灯光 — 单个灯光单元
## 物理屏障：图案错误时碰撞体阻挡A1，正确时消失
## 灯光纹理朝下照射


enum LightColor { RED, GREEN, BLUE }

@export var light_color: LightColor = LightColor.RED:
	set(v):
		light_color = v
		_update_sprite()


func _ready() -> void:
	_update_sprite()


func _update_sprite() -> void:
	var sprite: Sprite2D = $Sprite2D as Sprite2D
	if not sprite:
		return
	match light_color:
		LightColor.RED:
			sprite.texture = load("res://minigame_assets/Level2-1/灯光/灯光 红.png")
		LightColor.GREEN:
			sprite.texture = load("res://minigame_assets/Level2-1/灯光/灯光 绿.png")
		LightColor.BLUE:
			sprite.texture = load("res://minigame_assets/Level2-1/灯光/灯光 蓝.png")
