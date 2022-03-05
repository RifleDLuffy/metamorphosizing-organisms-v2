extends Node2D

onready var _root: Main = get_tree().get_root().get_node("Main")

var game_over = false

var curr_player
var curr_player_index
const num_players = 2
var players = []
func get_next_player():
	return players[(curr_player_index+1)%num_players]
func change_to_next_player():
	curr_player_index = (curr_player_index+1)%num_players
	curr_player = players[curr_player_index]

var game_started = false
var world_str = ""

var curr_moves = 2
var max_moves = 2

var curr_time = 0
const time_per_move = 30

const sprite_move_active = preload("res://Assets/UI/Player/Game_Player_Moves_Icon_Active.png");
const sprite_move_used = preload("res://Assets/UI/Player/Game_Player_Moves_Icon_Used.png")

func init(_world_str):
	world_str = _world_str
	return self

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
	
	players = _root.players_for_level_main
	$"CanvasLayer/Players/".add_child(players[0])
	$"CanvasLayer/Players/".add_child(players[1])
	players[1].position = Vector2(1000, 500)
	curr_player = players[0]
	curr_player_index = 0
	
	$Grid.connect("swap_start", self, "before_process")
	$Grid.connect("swap_end", self, "after_process")
	$Grid.connect("collect_mana", self, "distribute_mana")
	
	start_turn()

func distribute_mana(mana_array):
	for organism in curr_player.organisms:
		var mana_to_give = mana_array[organism.mana_enum]
		mana_array[organism.mana_enum] -= organism.change_mana(mana_to_give)

func start_turn():
	curr_moves = 2
	max_moves = 2
	restart_timer()
	update_move_icons()
	update_turn_icons()

# Called when the grid starts processing a move
func before_process():
	var timer = $CanvasLayer/Match_Control/Time_Control/Time_Text/Timer
	timer.stop()
	
	# Assuming that level main handles all the moves, player moves will update here
	curr_moves -= 1;
	update_move_icons()

# Called when the grid is done processing a move
func after_process():
	restart_timer()
	update_move_icons()
	
	# Show available berry actions when the player reaches the max berry count
	if curr_player.berries >= curr_player.max_berries:
		for organism in curr_player.organisms:
			organism.show_berry_actions()
	if curr_moves == 0:
		change_to_next_player()
		start_turn()

var move_icon_active = load("res://Assets/UI/Player/Game_Player_Moves_Icon_Active.png")
var move_icon_used = load("res://Assets/UI/Player/Game_Player_Moves_Icon_Used.png")
onready var move_icons = $CanvasLayer/Match_Control/Moves_Control/Moves_Container
func update_move_icons():
	move_icons.get_children()[2].visible = (max_moves == 3)
	for move_icon in move_icons.get_children():
		move_icon.texture = move_icon_used
	for i in range(curr_moves):
		move_icons.get_children()[i].texture = move_icon_active

func update_turn_icons():
	var dark = Color(0.5, 0.5, 0.5, 1)
	var light = Color(1, 1, 1, 1)
	
	# If the current player is Player #1, darken the Player 2 Icon
	if curr_player == players[0]:
		$CanvasLayer/Player2_Turn.modulate = dark
		$CanvasLayer/Player1_Turn.modulate = light
	else:
		$CanvasLayer/Player1_Turn.modulate = dark
		$CanvasLayer/Player2_Turn.modulate = light

# Restart the move timer
func restart_timer():
	curr_time = time_per_move
	$CanvasLayer/Match_Control/Time_Control/Time_Text.text = str(curr_time)
	
	var timer = $CanvasLayer/Match_Control/Time_Control/Time_Text/Timer
	
	timer.start()
	timer.connect("timeout", self, "on_timer_timeout") 

# The timer waits every second but don't update the text. We do it here.
func on_timer_timeout():
	curr_time -= 1
	$CanvasLayer/Match_Control/Time_Control/Time_Text.text = str(curr_time)
