extends Node2D
var owned_countries = []
var num_reinforcements = 0
var color = ""
var network_id = null

func save():
	var save_dict = {}
	save_dict["network_id"] = network_id
	save_dict["color"] = color
	save_dict["num_reinforcements"] = num_reinforcements
	return save_dict

func reset():
	owned_countries = []
	num_reinforcements = 0
	color = ""
	network_id = null

func init(_color):
	self.color = _color
	return self

func get_num_troops():
	var num_troops = 0
	for country in owned_countries:
		num_troops += country.num_troops
	return num_troops

func get_num_reinforcements():
	return int(ceil(float(len(owned_countries))/2))

func give_reinforcements():
	num_reinforcements = get_num_reinforcements()
