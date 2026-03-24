extends Node

var http = preload("res://scripts/network/http.gd").new()

var port: int = 54000
var bind_address: String = "127.0.0.1"
var redirect_server = TCPServer.new()
var secret_pkce: String = "AwesomeSecretKeyAwesomeSecretKeyAwesomeSecr"

var temp_auth_code: String

func start_server():
	GlobalLogger.logs("Starting OAuth redirect server.", 0)
	redirect_server.listen(port, bind_address)
	return

func stop_server():
	GlobalLogger.logs("Closing OAuth redirect server.", 0)
	redirect_server = TCPServer.new()
	return

func check_connection():
	GlobalLogger.logs("Checking OAuth connections.", 0)
	while redirect_server.is_connection_available():
		GlobalLogger.logs("Took a connection!", 0)
		var connection = redirect_server.take_connection()
		var request = connection.get_string(connection.get_available_bytes())
		if request:
			temp_auth_code = request.split("code=")[1].split("&iss=")[0]
			GlobalLogger.logs("Got authentication code: '%s'." % temp_auth_code, 0)
			_exchange_auth_code()

func start_oauth_process(account_server: String):
	var uri_parts := [
		"client_id=%s" % "OpenMinerva-Game-Client",
		"redirect_uri=http://%s:%s" % [bind_address, port],
		"response_type=code",
		"scope=openid",
		"response_mode=query",
		"code_challenge_method=S256",
		"code_challenge=%s" % _get_code_challenge(secret_pkce),
	]
	var uri = account_server + "?" + "&".join(uri_parts)
	OS.shell_open(uri)
	return

func _exchange_auth_code():
	GlobalLogger.logs("Exchanging retrieved auth code for a proper token.", 0)
	var form_parts := [
		"client_id=%s" % "OpenMinerva-Game-Client",
		"grant_type=authorization_code",
		"code=%s" % temp_auth_code,
		"redirect_uri=http://%s:%s" % [bind_address, port],
		"code_challenge_method=S256",
		"code_verifier=%s" % secret_pkce,
	]

	var form_string: String = "&".join(form_parts)

	var exchange_response = await http.req(HTTPClient.Method.METHOD_POST, "http://localhost", "/oauth/token", 40400, ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded"], form_string)

	if exchange_response.ok == false:
		GlobalLogger.logs("Unhandled error with exchanging auth code for access_token.", 2)
		return

	var token_data = JSON.parse_string(exchange_response.get("body"))

	print(token_data)

func _get_code_challenge(verifier: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(verifier.to_utf8_buffer())
	var hash_bytes = ctx.finish()
	var base64_str = Marshalls.raw_to_base64(hash_bytes)

	base64_str = base64_str.replace("+", "-")
	base64_str = base64_str.replace("/", "_")

	while base64_str.ends_with("="):
		base64_str = base64_str.substr(0, base64_str.length() - 1)

	return base64_str

# End listening redirect server
# Refresh tokens
# Validate tokens
