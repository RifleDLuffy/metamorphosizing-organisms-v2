extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Accepts an array containing dimensions
func zeros(array):
	var retval = []
	if len(array) == 1:
		retval.resize(array[0])
		for i in range(array[0]):
			retval[i] = 0
	elif len(array) == 2:
		for i in range(array[0]):
			var row = []
			row.resize(array[1])
			for j in range(array[1]):
				row[j] = 0
			retval.append(row)
	return retval

func sum2d(array):
	var retval = 0
	for row in array:
		for elem in row:
			retval += elem
	return retval
