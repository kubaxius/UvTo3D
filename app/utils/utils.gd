extends Node

func get_percent(current, maximum, step = 1):
	return snapped((float(current)/float(maximum)) * 100, step)
