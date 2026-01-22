extends Node

var keys = {
	"public": "",
	"private": ""
}

# TODO: Move this to Files.gd script.
func read_keys_from_disk(username: String) -> PackedStringArray:
	var pubKeyPath = "user://accounts/%s/keys/pubKey.pem" % username
	var privKeyPath = "user://accounts/%s/keys/privKey.pem" % username

	var pubKey = ""
	var privKey = ""

	var keys_exist = FileAccess.file_exists(pubKeyPath) && FileAccess.file_exists(privKeyPath)

	if keys_exist:
		GlobalLogger.log_string("Using saved account key.")
		pubKey = FileAccess.open(pubKeyPath, FileAccess.READ).get_as_text()
		privKey = FileAccess.open(privKeyPath, FileAccess.READ).get_as_text()

		return [pubKey, privKey]

	GlobalLogger.log_string("No key available. Generating a new one!")
	_generate_keys()
	_write_keys_to_disk(username)

	return [keys.public, keys.private]

func _write_keys_to_disk(username):
	# Make sure directory exists
	var dir = DirAccess.open("user://")
	dir.make_dir_recursive("user://accounts/%s/keys" % username)

	# Write keys to disk
	var pubKeyPath = "user://accounts/%s/keys/pubKey.pem" % username
	var privKeyPath = "user://accounts/%s/keys/privKey.pem" % username

	var pubKeyFile = FileAccess.open(pubKeyPath, FileAccess.WRITE)
	pubKeyFile.store_string(keys.public)

	var privKeyFile = FileAccess.open(privKeyPath, FileAccess.WRITE)
	privKeyFile.store_string(keys.private)
	return

func _generate_keys():
	var crypto = Crypto.new()

	# keys.private = crypto.generate_rsa(2048)
	var generated_keys = crypto.generate_rsa(2048)

	keys.private = generated_keys.save_to_string(false)
	keys.public = generated_keys.save_to_string(true)
	return