extends CanvasLayer

@onready var http_get_request = HTTPRequest.new()
@onready var http_post_request = HTTPRequest.new()
@onready var highscore_list: VBoxContainer = $"DeadScreen/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer"
@onready var name_input: TextEdit = $"DeadScreen/PanelContainer/MarginContainer/VBoxContainer/NameInput"
@onready var next_level_button: Button = $"DeadScreen/PanelContainer/MarginContainer/VBoxContainer/CenterContainer/MarginContainer/NextLevel"

const GAME_NAME = "snake_ltd_beta"

var highscore: Variant

func _load_highscore():
	# load highscore
	var error = http_get_request.request("https://scores.edv-bitches.de/highscore/" + GAME_NAME + str(Global.level) + "?page=0&page_size=10", PackedStringArray(), HTTPClient.METHOD_GET)
	print("err", error)

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(http_get_request)
	add_child(http_post_request)
	
	http_get_request.request_completed.connect(self._on_get_highscore_request_completed)
	http_post_request.request_completed.connect(self._on_post_highscore_request_completed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if visible && Input.is_action_pressed("Restart"):
		_on_next_level_pressed()

func _on_get_highscore_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	highscore = response

	for i in range(highscore.highscores.size()):
		var score = highscore.highscores[i]
		highscore_list.get_child(i).text = str(i+1) + ". " + score.name +  ": " + str(score.score)
	pass

func _on_post_highscore_request_completed(result, response_code, headers, body):
	
	Global.next_level()
	pass

func try_auto_process_highscore():
	if name_input.text == "":
		return false
	
	_on_new_highscore_pressed()
	return true

func _on_new_highscore_pressed():
	if next_level_button.disabled:
		return 
		
	next_level_button.disabled = true
	
	var username = name_input.text.replace("\n", "")
	
	var regex = RegEx.new()
	regex.compile("^[A-Za-z0-9 ]+$")
	if !regex.search(username):
		next_level_button.disabled = false
		name_input.text = ""
		return
	
	Global.username = username
	
	var body = JSON.stringify({"name": Global.username, "score": Global.score})
	var uri = "https://scores.edv-bitches.de/highscore/" + GAME_NAME + str(Global.level)
	print(uri, body)
	var error = http_post_request.request(uri, PackedStringArray(), HTTPClient.METHOD_POST, body)
	print("Highscore done", error)


func _on_visibility_changed():
	if visible:
		name_input.text = Global.username
		_load_highscore()
		

func _on_next_level_pressed():
	if !try_auto_process_highscore():
		Global.next_level() 
	
	pass # Replace with function body.
