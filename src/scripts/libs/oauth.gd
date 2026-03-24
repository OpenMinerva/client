# --- License
# File: /client/src/scripts/libs/oauth.gd
# Project: OpenMinerva
# Created Date: 23 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var http = preload("res://scripts/network/http.gd").new()
var jwt_lib = preload("res://scripts/libs/jwt.gd").new()
var random_lib = preload("res://scripts/utils/random.gd").new()

# TODO: Encrypt and store private token files. https://github.com/OpenMinerva/client/issues/59
# TODO: Validate tokens?
# TODO: Refresh tokens

var port: int = 54000
var bind_address: String = "127.0.0.1"
var redirect_server = TCPServer.new()
var secret_pkce: String = random_lib.random_string(50)

var access_token: String
var refresh_token: String
var id_token: String
var access_token_expiry: int

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
			# TODO: Make this more robust. How can I make sure that the code returned is valid?
			var temp_auth_code: String = request.split("code=")[1].split("&iss=")[0].strip_edges()
			var authentication_server = request.split("Referer: ")[1].split("\n")[0].strip_edges()

			GlobalLogger.logs("Got authentication code: '%s'." % temp_auth_code, 0)
			_exchange_auth_code(temp_auth_code, authentication_server)

func start_oauth_process(account_server: String):
	var uri_parts := [
		"client_id=%s" % "OpenMinerva-Game-Client",
		"redirect_uri=http://%s:%s" % [bind_address, port],
		"response_type=code",
		"scope=openid offline_access",
		"response_mode=query",
		"code_challenge_method=S256",
		"code_challenge=%s" % _get_code_challenge(secret_pkce),
		"prompt=consent"
	]
	var uri = account_server + "?" + "&".join(uri_parts)
	OS.shell_open(uri)
	return

func _exchange_auth_code(temp_auth_code: String, authentication_server: String):
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

	# TODO: Make a better way to split the url into parts
	var auth_server_host = authentication_server.split(":")[0] + ":" + authentication_server.split(":")[1]
	var auth_server_port: int = int(authentication_server.split(":")[2])

	var exchange_response = await http.req(HTTPClient.Method.METHOD_POST, auth_server_host, "/oauth/token", auth_server_port, ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded"], form_string)

	if exchange_response.ok == false:
		GlobalLogger.logs("Unhandled error with exchanging auth code for access_token.", 2)
		return

	var token_data = JSON.parse_string(exchange_response.get("body"))

	_get_tokens_from_response(token_data)

func _get_code_challenge(verifier: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(verifier.to_utf8_buffer())
	var hash_bytes = ctx.finish()
	var base64_str = Marshalls.raw_to_base64(hash_bytes)

	base64_str = jwt_lib.base64_to_base64url(base64_str)

	return base64_str

func _get_tokens_from_response(response: Dictionary) -> void:
	# TODO: Error checks to prevent overwriting with bad data.
	# ! Placeholder for development. Prevents overwriting data.
	if access_token:
		return

	access_token = response.get("access_token")
	refresh_token = response.get("refresh_token")
	id_token = response.get("id_token")
	access_token_expiry = response.get("expires_in")
	return