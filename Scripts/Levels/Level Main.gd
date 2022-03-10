extends Node2D

onready var _root: Main = get_tree().get_root().get_node("Main")

var game_over = false

var curr_player
var next_player
const num_players = 2
var players = []
func change_to_next_player():
	var temp_player = curr_player
	curr_player = next_player
	next_player = temp_player

var game_started = false
var world_str = ""

var curr_moves = 2
var max_moves = 2
const absolute_max_moves = 3

var curr_time = 0
const time_per_move = 30

func init(_world_str):
	world_str = _world_str
	return self

onready var grid = $Grid

func create_mons_and_players():
	for i in range(len(_root.players_for_level_main)):
		var info = _root.players_for_level_main[i]
		var mon1_name = info[0]
		var mon2_name = info[1]
		var player_index = i
		
		var player = get_node("CanvasLayer/Players/Player" + str(player_index+1))
		player.get_node("Organism1").create_base_mon(mon1_name)
		player.get_node("Organism2").create_base_mon(mon2_name)
		player.init("P"+str(player_index+1))
		_root.players_for_level_main[player_index] = player

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
	
	create_mons_and_players()
	players = _root.players_for_level_main
	$"CanvasLayer/Players/".add_child(players[0])
	$"CanvasLayer/Players/".add_child(players[1])
	players[0].position = Vector2(150, -200)
	players[1].position = Vector2(3500, -200)
	
	# Flip the sprites of the organisms in Player 2's control
	for organism in players[1].organisms:
		organism.flip_sprite()

	curr_player = players[0]
	next_player = players[1]
	
	next_player.curr_HP = 90
	next_player.update_ui()
	
	# Giving the organisms and players a reference to the game
	for player in players:
		for organism in player.organisms:
			organism.game = self
			organism.connect("evolving_start", self, "before_process")
			organism.connect("evolving_end", self, "after_process")
		player.game = self
	
	$Grid.connect("swap_start", self, "before_process")
	$Grid.connect("swap_end", self, "after_process")
	$Grid.connect("collect_mana", self, "distribute_mana")
	$Grid.connect("extra_move", self, "add_extra_move")
	$Grid.rng.seed = _root.rng.seed
	$Grid.rng.state = 0
	$Grid.ready()
	
	start_turn()

func distribute_mana(mana_array):
	var berries_to_give = mana_array[ManaTex.enum("berry")]
	mana_array[ManaTex.enum("berry")] -= curr_player.change_berries(berries_to_give)
	for organism in curr_player.organisms:
		var mana_to_give = mana_array[organism.mana_enum]
		mana_array[organism.mana_enum] -= organism.change_mana(mana_to_give)

func start_turn():
	curr_moves = 2
	max_moves = 2
	restart_timer()
	update_move_icons()
	update_turn_icons()
	curr_player.update_ui(false)

func add_extra_move():
	if max_moves != absolute_max_moves:
		curr_moves += 1
		max_moves += 1
		update_move_icons()
		
func remove_move():
	if curr_moves > 0:
		curr_moves -= 1
		update_move_icons()

# Called when the grid starts processing a move
func before_process():
	var timer = $CanvasLayer/Match_Control/Time_Control/Time_Text/Timer
	timer.stop()
	
	# Assuming that level main handles all the moves, player moves will update here
	remove_move()
	process_actions(move_start_actions)

# Called when the grid is done processing a move
func after_process():
	restart_timer()
	update_move_icons()
	
	for organism in curr_player.organisms:
		organism.do_ability()
	
	# Changing turns
	if curr_moves == 0:
		process_actions(turn_end_actions)
		curr_player.update_ui()
		change_to_next_player()
		start_turn()
		process_actions(turn_start_actions)
	else:
		curr_player.update_ui(false)

func compare_actions(action1, action2):
	return action1['num_times'] > action2['num_times']

func process_actions(actions):
	# Why sort the actions?
	# Consider the ability that prevent an organism from absorbing mana
	# It could be on that in the list of actions there's to instances of this ability
	# We don't want the blocking to be set to false if there's still an ability that can set it to true
	# But it could be that the ability that set's it to true get's processed after the one that set's it to false
	# We sort to get around this
	actions.sort_custom(self, "compare_actions")
	for a in actions:
		if a['num_times'] > 0:
			# Check if the action can be executed
			if a['object'].call(a['action'], a['caster']):
				a['num_times'] -= 1
		if a['num_times'] == 0 and ('cleanup' in a):
			a['object'].call(a['cleanup'], a['caster'])
			a['num_times'] -= 1

var turn_end_actions = []
var turn_start_actions = []
var move_start_actions = []

# Format for actions
# [Organism, Ability_Name, Duration, Casting Player]
func register_repeated_action(object, method, num_times, action_type, cleanup = null):
	var subscription = {'num_times': num_times,
						'action': method,
						'caster': curr_player,
						'object': object,
						'action_type': action_type,
						'cleanup': cleanup}
	var actions = get(subscription['action_type']+"_actions")
	actions.append(subscription)

var move_icon_active = load("res://Assets/UI/Player/Game_Player_Moves_Icon_Active.png")
var move_icon_used = load("res://Assets/UI/Player/Game_Player_Moves_Icon_Used.png")
onready var move_icons = $CanvasLayer/Match_Control/Moves_Control/Moves_Container
func update_move_icons():
	# Hide all move icons first
	for move_icon in move_icons.get_children():
		move_icon.visible = false
		
	# Set a tile visible based on how many max moves I have
	for i in range(max_moves):
		move_icons.get_children()[i].visible = true
	
	# Set all the icons' textures to used move texture
	for move_icon in move_icons.get_children():
		move_icon.texture = move_icon_used
		
	# Set a icon's texture to active_move for every move I currently have
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

func is_current_player():
	if not _root.online_game:
		return true
	return players[_root.player_index] == curr_player
	
# Given a player object, return the other player object (This is a 2 person game)
func get_other_player(input_player):
  var local_players = players.duplicate()
  local_players.remove(local_players.find(input_player))
  return local_players[0]
