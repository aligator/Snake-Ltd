extends CanvasLayer

@onready var http_get_request = HTTPRequest.new()
@onready var http_post_request = HTTPRequest.new()
@onready var highscore_list: VBoxContainer = $"DeadScreen/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer"
@onready var name_input: TextEdit = $"DeadScreen/PanelContainer/MarginContainer/VBoxContainer/NameInput"
@onready var highscore_button: Button = $"DeadScreen/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/NewHighscore"

const GAME_NAME = "snke_ltd_beta"

var highscore: Variant

func _load_highscore():
	# load highscore
	var error = http_get_request.request("http://scores.edv-bitches.de/highscore/" + GAME_NAME + "?page=0&page_size=50", PackedStringArray(), HTTPClient.METHOD_GET)
	print("err", error)

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(http_get_request)
	add_child(http_post_request)
	
	http_get_request.request_completed.connect(self._on_get_highscore_request_completed)
	http_post_request.request_completed.connect(self._on_post_highscore_request_completed)
	
	_load_highscore()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_get_highscore_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	print(response)
	highscore = response

	for i in range(highscore.highscores.size()):
		var score = highscore.highscores[i]
		print(score.name)
		print(score.score)
		highscore_list.get_child(i).text = str(i+1) + ". " + score.name +  ": " + str(score.score)
	pass

func _on_post_highscore_request_completed(result, response_code, headers, body):
	_load_highscore()
	pass


func _on_new_highscore_pressed():
	highscore_button.disabled = true
	
	var username = name_input.text
	
	var regex = RegEx.new()
	regex.compile("^[A-Za-z0-9 ]+$")
	if !regex.search(username):
		highscore_button.disabled = false
		name_input.text = ""
		return
	
	Global.username = username
	
	var body = JSON.new().stringify({"name": username, "score": Global.score})
	var error = http_post_request.request("http://scores.edv-bitches.de/highscore/" + GAME_NAME, PackedStringArray(), HTTPClient.METHOD_POST, body)
	print("err", error)
	

func _on_visibility_changed():
	if visible:
		name_input.text = Global.username

