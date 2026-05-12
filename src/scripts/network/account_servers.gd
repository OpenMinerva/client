extends Node

var _database = { }


# TODO: Save public account server keys to disk
func get_public_key(host: String, port: int) -> String:
	if host in _database:
		return _database[host]

	var response: Dictionary = await _request_server_pem(host, port)
	if response.ok == true:
		_database[host] = response.data
		return response.data

	return ""


func _request_server_pem(host: String, port: int = 443) -> Dictionary:
	GlobalLogger.log("Requesting server '%s:%s'." % [host, port])
	var return_dict = { "ok": false, "data": "" }
	var key = await HTTP.req(HTTPClient.METHOD_GET, host, "/public_key", port)
	if key.ok == true:
		return_dict.data = key.body
		return_dict.ok = true
		return return_dict
	return return_dict
