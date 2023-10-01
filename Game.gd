extends Node2D

enum DIRECTION { LEFT, RIGHT, UP, DOWN } 
enum COOKIE_TYPE { NORMAL, SPEED_UP, SLOW_DOWN, GROW, DUAL_COOKIE }
const COOKIE_TYPE_COUNT = 5

class Cookie:
	var position: Vector2i
	var is_in_snake: bool
	var cookie_type: COOKIE_TYPE

@onready var map: TileMap
@onready var camera: Camera2D = $Camera2D
@onready var map_bounding_hint: ReferenceRect = $MapBoundingHint
@onready var effect_timer: Timer = $EffectTimer
@onready var shrink_timer: Timer = $ShrinkTimer
@onready var sch_audio: AudioStreamPlayer = $SchAudio
@onready var hcs_audio: AudioStreamPlayer = $HcsAudio
@onready var ham_audio: AudioStreamPlayer = $HamAudio
@onready var au_audio: AudioStreamPlayer = $AuAudio
@onready var brum_audio: AudioStreamPlayer = $BrumAudio
@onready var doet_audio: AudioStreamPlayer = $DoetAudio
@onready var hmm_audio: AudioStreamPlayer = $HmmAudio
@onready var huhu_audio: AudioStreamPlayer = $HuhuAudio
@onready var speed_particles: CPUParticles2D = $SpeedParticles

@onready var death_screen: CanvasLayer = $DeathScreen

var map_bounding

var snake: Array[Vector2i] = []
var direction = DIRECTION.RIGHT
var previous_direction = DIRECTION.RIGHT
const DEFAULT_SPEED = 7
var speed: float = DEFAULT_SPEED
var step: float = 0.0
var dead: bool = false

var cookies: Array[Cookie] = []
var eaten_cookies: Array[Cookie] = []
var do_shrink = false
var do_grow = false

func _grow():
	if !do_grow:
		return
	do_grow = false

	hcs_audio.play()

	for count in range(3):
		var cells: Array[Vector2i] = []
		for x in range(map_bounding.size.x):
			cells.append(Vector2i(x, 0) + map_bounding.position)
			cells.append(Vector2i(x, map_bounding.size.y-1) + map_bounding.position)
					
		for y in range(map_bounding.size.y):
			cells.append(Vector2i(0, y) + map_bounding.position)
			cells.append(Vector2i(map_bounding.size.x-1, y) + map_bounding.position)
			
		for cell in cells:
			map.set_cell(0, cell, 0, Vector2i(8, randi_range(0, 3)))
			
		map_bounding.position = Vector2i(map_bounding.position.x-1, map_bounding.position.y-1)
		map_bounding.size = Vector2i(map_bounding.size.x+2, map_bounding.size.y+2)
		
		# change all outer to wall
		for x in range(map_bounding.size.x):
			map.set_cell(0, Vector2i(x, 0) + map_bounding.position, 0, Vector2i(1, 0))
			map.set_cell(0, Vector2i(x, map_bounding.size.y-1) + map_bounding.position, 0, Vector2i(3, 0))
			
		for y in range(map_bounding.size.y):
			map.set_cell(0, Vector2i(0, y) + map_bounding.position, 0, Vector2i(0, 0))
			map.set_cell(0, Vector2i(map_bounding.size.x-1, y) + map_bounding.position, 0, Vector2i(2, 0))
		
		map.set_cell(0, map_bounding.position, 0, Vector2i(5, 0))
		map.set_cell(0, Vector2i(map_bounding.position.x + map_bounding.size.x-1, map_bounding.position.y), 0, Vector2i(6, 0))
		map.set_cell(0, Vector2i(map_bounding.position.x + map_bounding.size.x-1, map_bounding.position.y + map_bounding.size.y-1), 0, Vector2i(7, 0))
		map.set_cell(0, Vector2i(map_bounding.position.x, map_bounding.position.y-1 + map_bounding.size.y), 0, Vector2i(4, 0))
	
func _shrink():
	if !do_shrink:
		return
	do_shrink = false
	
	sch_audio.play()
	
	for x in range(map_bounding.size.x):
		map.erase_cell(0, Vector2i(x, 0) + map_bounding.position)
		map.erase_cell(0, Vector2i(x, map_bounding.size.y-1) + map_bounding.position)
		
	for y in range(map_bounding.size.y):
		map.erase_cell(0, Vector2i(0, y) + map_bounding.position)
		map.erase_cell(0, Vector2i(map_bounding.size.x-1, y) + map_bounding.position)
	
	map_bounding.position = Vector2i(map_bounding.position.x+1, map_bounding.position.y+1)
	map_bounding.size = Vector2i(map_bounding.size.x-2, map_bounding.size.y-2)
	
	# change all outer to wall
	for x in range(map_bounding.size.x):
		map.set_cell(0, Vector2i(x, 0) + map_bounding.position, 0, Vector2i(1, 0))
		map.set_cell(0, Vector2i(x, map_bounding.size.y-1) + map_bounding.position, 0, Vector2i(3, 0))
		
	for y in range(map_bounding.size.y):
		map.set_cell(0, Vector2i(0, y) + map_bounding.position, 0, Vector2i(0, 0))
		map.set_cell(0, Vector2i(map_bounding.size.x-1, y) + map_bounding.position, 0, Vector2i(2, 0))
	
	map.set_cell(0, map_bounding.position, 0, Vector2i(5, 0))
	map.set_cell(0, Vector2i(map_bounding.position.x + map_bounding.size.x-1, map_bounding.position.y), 0, Vector2i(6, 0))
	map.set_cell(0, Vector2i(map_bounding.position.x + map_bounding.size.x-1, map_bounding.position.y + map_bounding.size.y-1), 0, Vector2i(7, 0))
	map.set_cell(0, Vector2i(map_bounding.position.x, map_bounding.position.y-1 + map_bounding.size.y), 0, Vector2i(4, 0))
	
	# Check if you are dead
	var position_to_cut = -1
	for i in range(snake.size()):
		var tile = map.get_cell_tile_data(0, snake[i])
		
		if tile == null || map.get_cell_tile_data(0, snake[i]).get_custom_data("wall"):
			position_to_cut = i
			
	if position_to_cut >= 0:
		au_audio.play()
		dead = true
		return
	
	var need_recreate: Array[Cookie] = []
	for i in range(cookies.size()):
		var cookie = cookies[i]
		if !_check_cookie_location(cookie):
			if cookie.cookie_type == COOKIE_TYPE.NORMAL:
				need_recreate.append(cookie)
			cookies[i] = null
	
	cookies = cookies.filter(func(cookie): return cookie != null)
	
	for i in range(need_recreate.size()):
		_spawn_cookie(need_recreate[i].cookie_type)
			

func _is_in_snake(cookie: Cookie) -> bool:
	for snake_body_part in snake:
		if snake_body_part == cookie.position:
			return true
	return false

func _cut_snake(at: int) -> bool:	
	au_audio.play()
	snake = snake.slice(at, snake.size())
	
	eaten_cookies = eaten_cookies.filter(_is_in_snake)			
	
	if snake.size() <= 3:
		dead = true

	return dead

func _spawn_cookie(cookie_type = COOKIE_TYPE.NORMAL):	
	var is_wrong = true
	var cookie: Cookie
	
	while is_wrong:
		var x = randi_range(1, map_bounding.size.x-2)
		var y = randi_range(1, map_bounding.size.y-2)
	
		cookie = Cookie.new()
		cookie.position = Vector2i(x, y) + map_bounding.position
		cookie.is_in_snake = false
		cookie.cookie_type = cookie_type
	
		is_wrong = !_check_cookie_location(cookie, true)
	
	cookies.append(cookie)
	pass

func _check_cookie_location(cookie: Cookie, check_cookie_layer = false) -> bool:
	var is_wrong = false
	
	# Get the map tile at this position
	var map_tile = map.get_cell_tile_data(0, cookie.position)
	if map_tile == null || map_tile.get_custom_data("wall"):		
		is_wrong = true
	
	# Get the ssnake layer
	var snake_tile = map.get_cell_source_id(1, cookie.position)
	if snake_tile != -1:
		is_wrong = true
		
	if check_cookie_layer:
		# Get the cookie layer
		var cookie_tile = map.get_cell_source_id(2, cookie.position)
		if cookie_tile != -1:
			is_wrong = true
		
	return !is_wrong

# Called when the node enters the scene tree for the first time.
func _ready():
	# load level
	if $Levels.get_child_count() == Global.level:
		Global.level = 0
		
	map = $Levels.get_child(Global.level)
	map.show()
	
	# spawn initial snake
	snake.append(Vector2i(1, 5))
	snake.append(Vector2i(2, 5))
	snake.append(Vector2i(3, 5))
	
	map_bounding = map.get_used_rect()
	
	_spawn_cookie()
	huhu_audio.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dead:
		death_screen.show()
		return
	
	_shrink()
	_grow()
	
	if dead:
		return
		
	speed_particles.emitting = true
		
	Global.score = snake.size() - 3
	
	if Input.is_action_pressed("Right"):
		direction = DIRECTION.RIGHT
	elif Input.is_action_pressed("Left"):
		direction = DIRECTION.LEFT
	elif Input.is_action_pressed("Up"):
		direction = DIRECTION.UP
	elif Input.is_action_pressed("Down"):
		direction = DIRECTION.DOWN
	
	step += delta * speed
	
	if step >= 1.0:
		step = step - 1.0
		
		if direction == DIRECTION.RIGHT && previous_direction == DIRECTION.LEFT || direction == DIRECTION.LEFT && previous_direction == DIRECTION.RIGHT || direction == DIRECTION.UP && previous_direction == DIRECTION.DOWN || direction == DIRECTION.DOWN && previous_direction == DIRECTION.UP:
			direction = previous_direction
	
		previous_direction = direction
	
		var head = snake.back()
		var new_head = Vector2i(head.x, head.y)
		if direction == DIRECTION.RIGHT:
			new_head.x += 1	
		if direction == DIRECTION.LEFT:
			new_head.x -= 1	
		if direction == DIRECTION.UP:
			new_head.y -= 1		
		if direction == DIRECTION.DOWN:
			new_head.y += 1	
		
		var collision_index = -1
		for i in range(snake.size()):
			var body_part = snake[i]
			if body_part == new_head:
				collision_index = i
				break
				
		if collision_index >= 0:
			# Cut snake at the collision position
			if _cut_snake(collision_index):
				return
		
		var isWall = map.get_cell_tile_data(0, new_head).get_custom_data("wall")
		if isWall:
			au_audio.play()
			dead = true
			return
			
		snake.append(new_head)
		
		for i in range(cookies.size()):
			var cookie = cookies[i]
			if cookie.position == new_head:
				ham_audio.play()
				cookies.pop_at(i)
				eaten_cookies.append(cookie)
				break
		
		if eaten_cookies.size() == 0 || eaten_cookies.front() == null || eaten_cookies.front().position != snake.front():
			snake.pop_front()
		else:
			var cookie: Cookie = eaten_cookies.pop_front()
			if cookie.cookie_type == COOKIE_TYPE.NORMAL:
				_spawn_cookie()
			if cookie.cookie_type == COOKIE_TYPE.DUAL_COOKIE:
				Global.effect_type = Global.EFFECT_TYPE.DUAL_COOKIE
				hmm_audio.play()
				_spawn_cookie()
			if cookie.cookie_type == COOKIE_TYPE.SLOW_DOWN:
				speed = int(roundf(DEFAULT_SPEED / 2.0))
				doet_audio.play()
				Global.effect_type = Global.EFFECT_TYPE.SLOW_DOWN
				effect_timer.start()
			if cookie.cookie_type == COOKIE_TYPE.SPEED_UP:
				speed = int(roundf(DEFAULT_SPEED * 2))
				brum_audio.play()
				Global.effect_type = Global.EFFECT_TYPE.SPEED_UP
				effect_timer.start()
			if cookie.cookie_type == COOKIE_TYPE.GROW:
				Global.effect_type = Global.EFFECT_TYPE.GROW
				do_shrink = false
				do_grow = true
				shrink_timer.start()
	
	map_bounding_hint.size = map_bounding.size * 16
	map_bounding_hint.position = map_bounding.position * 16
	
	# render cookies
	map.clear_layer(2)
	for cookie in cookies:
		map.set_cell(2, cookie.position, 0, Vector2i(1 + cookie.cookie_type, 1))
		
	for cookie in eaten_cookies:
		map.set_cell(2, cookie.position, 0, Vector2i(0, 1))

	# render snake
	map.clear_layer(1)
	camera.position = map.map_to_local(snake.back())
	for i in range(snake.size()):
		var body_part = snake[i]
		var type = 0;
				
		
		if i == 0: # Tail
			speed_particles.position = (snake.front() * 16 + Vector2i(1, 1) * 8) 
			if snake[1].x > body_part.x && snake[1].y == body_part.y:
				type = 3 # right open
				speed_particles.direction = Vector2i(-1, 0)
				speed_particles.position += Vector2(-8, 0)
			if snake[1].x < body_part.x && snake[1].y == body_part.y:
				type = 1 # left open
				speed_particles.direction = Vector2i(1, 0)
				speed_particles.position += Vector2(8, 0)
			if snake[1].x == body_part.x && snake[1].y > body_part.y:
				type = 0 # bottom open
				speed_particles.direction = Vector2i(0, -1)
				speed_particles.position += Vector2(0, -8)
			if snake[1].x == body_part.x && snake[1].y < body_part.y:
				type = 2 # top open
				speed_particles.direction = Vector2i(0, 1)
				speed_particles.position += Vector2(0, 8)
				
		if i == snake.size()-1:
			if snake[snake.size()-2].x > body_part.x && snake[snake.size()-2].y == body_part.y:
				type = 13 # right open
			if snake[snake.size()-2].x < body_part.x && snake[snake.size()-2].y == body_part.y:
				type = 11 # left open
			if snake[snake.size()-2].x == body_part.x && snake[snake.size()-2].y > body_part.y:
				type = 10 # bottom open
			if snake[snake.size()-2].x == body_part.x && snake[snake.size()-2].y < body_part.y:
				type = 12 # top open
		
		if i > 0 && i < snake.size()-1:
			var prev = snake[i-1]
			var next = snake[i+1]

			if prev.x == next.x:
				type = 4 # horizontal
			if prev.y == next.y:
				type = 5 # vertical
			if prev.x < body_part.x && body_part.y < next.y:
				type = 7 # left bottom open
			if prev.x < body_part.x && body_part.y > next.y:
				type = 8 # left top open
			if prev.x > body_part.x && body_part.y < next.y:
				type = 6 # right bottom open
			if prev.x > body_part.x && body_part.y > next.y:
				type = 9 # right top open

			if prev.y < body_part.y && body_part.x < next.x:
				type = 9 # top left open
			if prev.y < body_part.y && body_part.x > next.x:
				type = 8 # top returnpassright open
			if prev.y > body_part.y && body_part.x < next.x:
				type = 6 # bottom left open
			if prev.y > body_part.y && body_part.x > next.x:
				type = 7 # bottom right open
		
		map.set_cell(1, body_part, 1, Vector2i(type, 0))
		
		


func _on_shrink_timer_timeout():
	do_shrink = true
	
func _on_power_up_timer_timeout():
	cookies = cookies.filter(func(cookie): return cookie.cookie_type == COOKIE_TYPE.NORMAL)
	_spawn_cookie(randi_range(1, COOKIE_TYPE_COUNT-1))

func _on_effect_timer_timeout():
	speed = DEFAULT_SPEED
	Global.effect_type = Global.EFFECT_TYPE.NORMAL
	pass # Replace with function body.
