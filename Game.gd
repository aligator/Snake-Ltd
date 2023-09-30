extends Node2D

class Cookie:
	var position: Vector2i
	var is_in_snake: bool

@onready var map = $Map
@onready var camera = $Camera2D

enum DIRECTION { LEFT, RIGHT, TOP, DOWN } 

var snake: Array[Vector2i] = []
var direction = DIRECTION.RIGHT
var speed: float = 5
var step: float = 0.0
var grow: bool = false

var cookies: Array[Cookie] = []

func _spawn_cookie():
	var bounding = map.get_used_rect()
	var x = randi_range(0, bounding.size.x-1)
	var y = randi_range(0, bounding.size.y-1)
	
	var cookie = Cookie.new()
	cookie.position = Vector2i(x, y)
	cookie.is_in_snake = false
	cookies.append(cookie)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	# spawn initial snake
	snake.append(Vector2i(1, 1))
	snake.append(Vector2i(2, 1))
	snake.append(Vector2i(3, 1))
	snake.append(Vector2i(4, 1))
	snake.append(Vector2i(5, 1))
	snake.append(Vector2i(6, 1))
	snake.append(Vector2i(7, 1))
	snake.append(Vector2i(8, 1))
	snake.append(Vector2i(9, 1))
	
	_spawn_cookie()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
				# Explosionen!
				print("Dead")
				
			
		snake.append(new_head)
		
		for cookie in cookies:
			if cookie.position == new_head:
				cookie.is_in_snake = true
		
		if !grow:
			snake.pop_front()
		else:
			grow = false
			_spawn_cookie()
	
	# Cookie eaten
	for i in range(cookies.size()):
		if cookies[i].position == snake.front():
			cookies.pop_at(i)
			grow = true
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
				type = 8 # top right open
			if prev.y > body_part.y && body_part.x < next.x:
				type = 6 # bottom left open
			if prev.y > body_part.y && body_part.x > next.x:
				type = 7 # bottom right open
		
		map.set_cell(1, body_part, 1, Vector2i(type, 0))
