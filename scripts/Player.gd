extends CharacterBody2D

@export var speed := 150
@export var jump_velocity := -350.0

var gravity := ProjectSettings.get_setting("physics/2d/default_gravity")
var gray_stars := 0
var yellow_stars := 0
var is_hiding := false

@onready var anim := $AnimatedSprite2D

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
	update_animation(dir)

func update_animation(dir: float):
	if not is_on_floor():
		if velocity.y < 0:
			anim.play("Chara_jump")
		else:
			anim.play("Chara_fall")
	elif dir != 0:
		anim.play("Chara_walk")
		anim.flip_h = dir < 0
	else:
		anim.play("idle")
		anim.stop()

func collect_star(type: String):
	if type == "gray":
		gray_stars += 1
	elif type == "yellow":
		yellow_stars += 1

func enter_grass():
	is_hiding = true

func exit_grass():
	is_hiding = false
