extends Node

enum EFFECT_TYPE { NORMAL, SPEED_UP, SLOW_DOWN, GROW, DUAL_COOKIE }

var score: int = 0
var time: int = 0

var effect_timer: int = 0
var effect_type = EFFECT_TYPE.NORMAL
