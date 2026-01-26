extends Node
var http = preload("res://scripts/http.gd").new()
var database = {}
# TODO: Open metadata file, and keep it opened

# TODO: Validate RSA PEM key 
func get_pem(host: String, port: int) -> String:
	# TODO: Check if we have the key saved
	return ""

func _request_server_pem(host: String, port: int = 443) -> String:
	var key = await http.req(HTTPClient.METHOD_GET, host, "/public_key", port)
	if key.ok == true:
		return key.body
	return ""


func _ready():
	_request_server_pem("http://localhost", 40400)

func _open_or_create_database():
	var dir = DirAccess.open("user://")
	dir.make_dir_recursive("user://account_servers/database.json")