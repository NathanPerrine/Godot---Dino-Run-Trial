extends Node

# Preload obstacles
var stump_scene 	= preload("res://Obstacles/Stump/stump.tscn")
var rock_scene 		= preload("res://Obstacles/Rock/rock.tscn")
var barrel_scene 	= preload("res://Obstacles/Barrell/barrell.tscn")
var bird_scene 		= preload("res://Obstacles/Bird/bird.tscn")
var obstacle_types := [stump_scene, rock_scene, barrel_scene]
var obstacles : Array
var bird_heights := [200, 390]

# Save Path
const SAVE_DIR = "user://saves/"
const SAVE_FILE_NAME = "save.json"
const SECURITY_KEY = "SFR@#8944321dsf@#d"

# Game variables
const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)
var difficulty : int
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var speed: float
const START_SPEED : float = 10.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000

var screen_size : Vector2i
var ground_height: int
var game_running : bool
var last_obs

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Check if save directory exists
	# If not, create it
	# Check if save file exists, if not create it
	# If it exists, update score data
	
	# Verify save directory
	verify_save_directory(SAVE_DIR)
	# Verify save file
	var save_file = verify_save_file(SAVE_DIR + SAVE_FILE_NAME)
	if !save_file:
		print('does not exist')
		high_score = 0
	else:
		print('already exists')
		load_data(SAVE_DIR + SAVE_FILE_NAME)
		update_high_score()
		print(save_file)
	
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()
	
func new_game():
	# Reset variables
	score = 0
	difficulty = 0
	get_tree().paused = false
	game_running = false
	show_score()
	
	# Delete all obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	# Reset nodes
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0,0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0,0)
	
	# Reset HUD and game over screen
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running:
		
		# Adjust speed + difficulty
		speed 		= min(START_SPEED + score / SPEED_MODIFIER, MAX_SPEED)
		difficulty 	= min((score/ SPEED_MODIFIER), MAX_DIFFICULTY)
		
		# Generate obstacles
		generate_obs()
		
		# Move dino + camera
		$Dino.position.x += speed
		$Camera2D.position.x += speed
		
		# Update score
		score += speed
		show_score()
		
		# Update ground position if moving off screen
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()


func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)


func check_high_score():
	score = score / SCORE_MODIFIER
	if score > high_score:
		high_score = score
		update_high_score()


func update_high_score():
	$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score)


func generate_obs():
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs 
		var max_obs = difficulty + 1
		
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		# Random chance to spawn a bird
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights.pick_random()
				add_obs(obs, obs_x, obs_y)


func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)


func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)


func hit_obs(body):
	if body.name == "Dino":
		game_over()


func game_over():
	check_high_score()
	save_data(SAVE_DIR + SAVE_FILE_NAME)
	get_tree().paused = true
	game_running = false
	$GameOver.show()


func verify_save_directory(path : String):
	DirAccess.make_dir_absolute(path)


func verify_save_file(path : String):
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SECURITY_KEY)
	if file == null:
		return false
	return file


func save_data(path : String):
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, SECURITY_KEY)
	if file == null:
		print(FileAccess.get_open_error())
		return
	
	var data = {
		"high_score": high_score
	}
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()


func load_data(path : String):
	if FileAccess.file_exists(path):
		var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SECURITY_KEY)
		if file == null:
			print(FileAccess.get_open_error())
			return
		var content = file.get_as_text()
		file.close
		
		var data = JSON.parse_string(content)
		if data == null:
			printerr("Cannot parse %s as json_string: (%s)" % [path, content])
		
		high_score = data.high_score
		print(data.high_score)
		
	else:
		printerr("Cannot open non-existant file at %s!" % [path])
