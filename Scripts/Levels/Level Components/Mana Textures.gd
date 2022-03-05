extends Node

const dict = {
	"null": null,
	"fire": preload("res://Assets/UI/Tiles/Tile_Fire.png"),
	"water": preload("res://Assets/UI/Tiles/Tile_Water.png"),
	"electric": preload("res://Assets/UI/Tiles/Tile_Electric.png"),
	"grass": preload("res://Assets/UI/Tiles/Tile_Grass.png"),
	"psychic": preload("res://Assets/UI/Tiles/Tile_Psychic.png"),
	"berry": preload("res://Assets/UI/Tiles/Tile_Berry.png")}
var values = dict.values()
var keys = dict.keys()

func enum(mana_type):
	return keys.find(mana_type)
