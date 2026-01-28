extends Node

func random_string(length: int = 6):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var chars = "0123456789abcdef"
	var out = ""
	for i in length:
		out += chars[rng.randi_range(0, chars.length() - 1)]
	return out
