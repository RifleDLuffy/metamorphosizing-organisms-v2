extends Node2D

var organisms
var pname
var game

var max_HP = 80
var curr_HP = max_HP
var max_berries = 4
var berries = 0

func init(organism1, organism2, _pname, _game):
	self.organisms = [organism1, organism2]
	add_child(organism1)
	add_child(organism2)
	organism1.position = Vector2(0, 300)
	organism1.position = Vector2(0, 600)
	self.pname = _pname
	self.game = _game
	return self

func change_HP(delta):
	# Clamping health
	# The max of current and max hp is done in the case of the start where p2 has 5 extra HP
	curr_HP = clamp(curr_HP + delta, 0, max(max_HP, curr_HP))

func change_berries(delta):
	# Clamping berries
	berries = clamp(berries + delta, 0, max_berries)
	
func update_ui():
	$Health_Control/Health/Text.text = curr_HP.str
	$Berry_Control/Berry/Text.text = berries.str + "/" + max_berries.str
