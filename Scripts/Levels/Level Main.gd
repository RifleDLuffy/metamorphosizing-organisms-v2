extends Node2D

onready var _root: Main = get_tree().get_root().get_node("Main")

var game_over = false

var curr_player = null
var curr_player_index = null
const num_players = 2
var players = []
var game_started = false
var world_str = ""

var curr_moves = 0
var max_moves = 2

var curr_time = 0
var time_per_move = 30

const sprite_move_active = preload("res://Assets/UI/Player/Game_Player_Moves_Icon_Active.png");
const sprite_move_used = preload("res://Assets/UI/Player/Game_Player_Moves_Icon_Used.png")

func init(_world_str):
	world_str = _world_str
	return self



func spawn():
	# Creating players
	
	players = {"P1": get_node("CanvasLayer/Players/Player 1").init("red"), "blue": get_node("CanvasLayer/Players/Player 2").init("blue")}
	# Randomizing players
	randomize()
	curr_player_index = randi() % num_players
	curr_player = players.values()[curr_player_index]
	
	print("The first player is " + curr_player.color)
	print(curr_player.color)
	
# Called when the node enters the scene tree for the first time.
func _ready():	
	# Button to start the game, when clicked it removes itself and the reroll button
	if _root.online_game:
		get_node("CanvasLayer/Start Game").queue_free()
	else:
		get_node("CanvasLayer/Start Game").connect("button_down", self, "remove_reroll_and_start_butttons")
		
	# Button to go to help menu
	get_node("CanvasLayer/Help").connect("button_down", self, "show_help_menu")
	
	# Button to resign game
	get_node("CanvasLayer/Resign").connect("button_down", self, "show_resignation_menu")
	get_node("CanvasLayer/Confirm Resign/VBoxContainer/CenterContainer/HBoxContainer/No").connect("button_down", self, "confirm_resign", [false])
	get_node("CanvasLayer/Confirm Resign/VBoxContainer/CenterContainer/HBoxContainer/Yes").connect("button_down", self, "confirm_resign", [true])
	get_node("CanvasLayer/Restart").connect("button_down", self, "restart")
	
	#update_player_status(curr_player.color, true)
	
func start_turn():
	restart_timer()
	update_moves()
	update_turn_icon()
	
# TODO:
# Replace with the signal emitted when the grid starts processing a move
func before_process():
	var timer = $CanvasLayer/Match_Control/Time_Control/Time_Text/Timer
	timer.stop()
	
	# Assuming that level main handles all the moves, player moves will update here
	curr_moves -= 1;
	update_moves()

# TODO:
# Replace with the signal emitted when the grid is done processing a move
func after_process():
	restart_timer()
	update_moves()
	
	# Show available berry actions when the player reaches the max berry count
	if curr_player.berries >= curr_player.max_berries:
		for organism in curr_player.organisms:
			organism.show_berry_actions()
		
func update_moves():
	# Get the container so we can add moves textures inside of it
	var container = $CanvasLayer/Match_Control/Moves_Control/Moves_Container
	
	for child in container.get_children().duplicate():
		container.remove_child(child)
		child.queue_free()
	
	for x in curr_moves:
		var texture = TextureRect.new()
		texture.texture = sprite_move_active
		container.add_child(texture)
	
	for x in max_moves - curr_moves:
		var texture = TextureRect.new()
		texture.texture = sprite_move_used
		container.add_child(texture)
		
func update_turn_icon():
	var dark = [0.5, 0.5, 0.5, 1]
	var light = [1, 1, 1, 1]
	
	# If the current player is Player #1, darken the Player 2 Icon
	if curr_player == players[0]:
		$CanvasLayer/Player2_Turn.modulate = dark
		$CanvasLayer/Player1_Turn.modulate = light
	else:
		$CanvasLayer/Player1_Turn.modulate = dark
		$CanvasLayer/Player2_Turn.modulate = light

func restart_timer():
	# Restart the move timer
	curr_time = time_per_move
	
	var timer = $CanvasLayer/Match_Control/Time_Control/Time_Text/Timer
	
	timer.start()
	timer.connect("timeout", self, "on_timer_timeout") 
	
# The timer waits every second but don't update the text. We do it here.
func on_timer_timeout():
	curr_time -= 1
	$CanvasLayer/Match_Control/Time_Control/Time_Text.text = curr_time.str
