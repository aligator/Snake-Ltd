extends Node2D

class Cookie:
	var position: Vector2i
	var is_in_snake: bool

@onready var map = $Map
@onready var camera = $Camera2D

enum DIRECTION { LEFT, RIGHT, TOP, DOWN } 

var snake: Array[Vector2i] = []
var direction = DIRECTION.RIGHT
var speed: float = 7
var step: float = 0.0
var growCookieIndex: int = -1
var dead: bool = false

var cookies: Array[Cookie] = []
var do_shrink = false

func _shrink():
	if !do_shrink:
		return
		
	# Clear cookie layer to avoid calculation errors
	map.clear_layer(2)
		
	do_shrink = false
	var current_size = map.get_used_rect().size
	var current_position = map.get_used_rect().position
	for x in range(current_size.x):
		map.erase_cell(0, Vector2i(x, 0) + current_position)
		map.erase_cell(0, Vector2i(x, current_size.y-1) + current_position)
		
	for y in range(current_size.y):
		map.erase_cell(0, Vector2i(0, y) + current_position)
		map.erase_cell(0, Vector2i(current_size.x-1, y) + current_position)
		
	# change all outer to wall
	current_size = map.get_used_rect().size
	current_position = map.get_used_rect().position
	for x in range(current_size.x):
		map.set_cell(0, Vector2i(x, 0) + current_position, 0, Vector2i(1, 0))
		map.set_cell(0, Vector2i(x, current_size.y-1) + current_position, 0, Vector2i(3, 0))
		
	for y in range(current_size.y):
		map.set_cell(0, Vector2i(0, y) + current_position, 0, Vector2i(0, 0))
		map.set_cell(0, Vector2i(current_size.x-1, y) + current_position, 0, Vector2i(2, 0))
	
	map.set_cell(0, current_position, 0, Vector2i(5, 0))
	map.set_cell(0, Vector2i(current_position.x + current_size.x-1, current_position.y), 0, Vector2i(6, 0))
	map.set_cell(0, Vector2i(current_position.x + current_size.x-1, current_position.y + current_size.y-1), 0, Vector2i(7, 0))
	map.set_cell(0, Vector2i(current_position.x, current_position.y-1 + current_size.y), 0, Vector2i(4, 0))
	
	# Check if the tail has to be cut
	var position_to_cut = -1
	for i in range(snake.size()):
		var tile = map.get_cell_tile_data(0, snake[i])
		
		if tile == null || map.get_cell_tile_data(0, snake[i]).get_custom_data("wall"):
			position_to_cut = i
			
	if position_to_cut >= 0:
		if _cut_snake(position_to_cut):
			return

func _cut_snake(at: int) -> bool:
	snake = snake.slice(at, snake.size())
	if snake.size() <= 3:
		dead = true

	return dead

func _spawn_cookie():
	var bounding = map.get_used_rect()
	var x = randi_range(0, bounding.size.x-1)
	var y = randi_range(0, bounding.size.y-1)
	
	var cookie = Cookie.new()
	cookie.position = Vector2i(x, y)
	cookie.is_in_snake = false
	
	for snake_body_part in snake:
		if snake_body_part == cookie.position:
			_spawn_cookie()
			return
	
	cookies.append(cookie)
	pass

func _check_cookie():
	var recreate: int = 0
	for i in range(cookies.size()):
		var cookie = cookies[i]
		var tile = map.get_cell_tile_data(0, cookie.position)
		if tile == null || map.get_cell_tile_data(0, cookie.position).get_custom_data("wall"):
			cookies[i] = null
			recreate+=1
	
	cookies = cookies.filter(func(cookie): return cookie != null)
		
	for i in range(recreate):
		_spawn_cookie()
	
	if recreate > 0:
		_check_cookie()

# Called when the node enters the scene tree for the first time.
func _ready():
	# spawn initial snake
	snake.append(Vector2i(1, 5))
	snake.append(Vector2i(2, 5))
	snake.append(Vector2i(3, 5))
	snake.append(Vector2i(4, 5))
	snake.append(Vector2i(5, 5))
	snake.append(Vector2i(6, 5))
	snake.append(Vector2i(7, 5))
	snake.append(Vector2i(8, 5))
	snake.append(Vector2i(9, 5))
	
	_spawn_cookie()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dead:
		return
	
	_shrink()
	
	if dead:
		return
		
	_check_cookie()
	
	if Input.is_action_pressed("Right"):
		if direction != DIRECTION.LEFT:
			direction = DIRECTION.RIGHT
	elif Input.is_action_pressed("Left"):
		if direction != DIRECTION.RIGHT:
			direction = DIRECTION.LEFT
	elif Input.is_action_pressed("Up"):
		if direction != DIRECTION.DOWN:
			direction = DIRECTION.TOP
	elif Input.is_action_pressed("Down"):
		if direction != DIRECTION.TOP:
			direction = DIRECTION.DOWN
	
	step += delta * speed
	
	if step >= 1.0:
		step = step - 1.0
		var head = snake.back()
		var new_head = Vector2i(head.x, head.y)
		if direction == DIRECTION.RIGHT:
			new_head.x += 1	
		if direction == DIRECTION.LEFT:
			new_head.x -= 1	
		if direction == DIRECTION.TOP:
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
			snake = snake.slice(collision_index, snake.size())
			if snake.size() <= 3:
				dead = true
				return
		
		var isWall = map.get_cell_tile_data(0, new_head).get_custom_data("wall")
		if isWall:
			dead = true
			return
			
		snake.append(new_head)
		
		for cookie in cookies:
			if cookie.position == new_head:
				cookie.is_in_snake = true
		
		if growCookieIndex == -1:
			snake.pop_front()
		else:
			growCookieIndex = -1
			cookies.pop_at(growCookieIndex)
			_spawn_cookie()
	
	# Cookie eaten
	for i in range(cookies.size()):
		if cookies[i].position == snake.front():
			growCookieIndex = i
			break
	
	# render cookies
	map.clear_layer(2)
	for cookie in cookies:
		if cookie.is_in_snake:
			map.set_cell(2, cookie.position, 0, Vector2i(1, 1))
		else:
			map.set_cell(2, cookie.position, 0, Vector2i(0, 1))

	
	# render snake
	map.clear_layer(1)
	camera.position = map.map_to_local(snake.back())
	for i in range(snake.size()):
		var body_part = snake[i]
		var type = 0;
				
		
		if i == 0: # Tail
			if snake[1].x > body_part.x && snake[1].y == body_part.y:
				type = 3 # right open
			if snake[1].x < body_part.x && snake[1].y == body_part.y:
				type = 1 # left open
			if snake[1].x == body_part.x && snake[1].y > body_part.y:
				type = 0 # bottom open
			if snake[1].x == body_part.x && snake[1].y < body_part.y:
				type = 2 # top open
				
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
	
