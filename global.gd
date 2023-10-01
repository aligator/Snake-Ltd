extends Node

enum EFFECT_TYPE { NORMAL, SPEED_UP, SLOW_DOWN, GROW, DUAL_COOKIE }

var score: int = 0
var time: int = 0

var effect_timer: int = 0
var effect_type = EFFECT_TYPE.NORMAL

var username = ""

func reset():
	score = 0
	time = 0
	effect_timer = 0
	effect_type = EFFECT_TYPE.NORMAL

func _process(delta):
	if Input.is_action_pressed("Quit"):
		get_tree().quit()
