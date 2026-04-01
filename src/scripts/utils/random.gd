extends Node

func random_string(length: int = 6, hexa_encoding: bool = false):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var chars = "0123456789abcdef" if hexa_encoding else "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var out = ""
	for i in length:
		out += chars[rng.randi_range(0, chars.length() - 1)]
	return out
