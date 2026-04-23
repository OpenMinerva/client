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

var port: int = 54000
var bind_address: String = "127.0.0.1"
var redirect_server = TCPServer.new()

var _listen_for_oauth_connections: bool = false

func authenticate(account_server: String) -> Dictionary:
	var secret_pkce: String = random_lib.random_string(50)
	var account_server_url = UrlParser.deconstruct(account_server)

	if account_server_url.ok == false:
		return {}

	account_server_url = account_server_url.data

	GlobalLogger.logs("Starting OAuth flow.")

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

	GlobalLogger.logs("Starting OAuth redirect server.")
	redirect_server.listen(port, bind_address)

	_listen_for_oauth_connections = true
	var _auth_code = await _wait_for_auth_code()

	GlobalLogger.logs("Closing OAuth redirect server.")
	redirect_server = TCPServer.new()

	GlobalLogger.logs("Exchanging retrieved auth code for a proper token.")
	var form_parts := [
		"client_id=%s" % "OpenMinerva-Game-Client",
		"grant_type=authorization_code",
		"code=%s" % _auth_code,
		"redirect_uri=http://%s:%s" % [bind_address, port],
		"code_challenge_method=S256",
		"code_verifier=%s" % secret_pkce,
	]
	var form_string: String = "&".join(form_parts)
	var exchange_response = await http.req(HTTPClient.Method.METHOD_POST, account_server_url.host, "/oauth/token", account_server_url.port, ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded"], form_string)
	var token_data = JSON.parse_string(exchange_response.get("body"))

	return _get_tokens_from_response(token_data)

func _get_code_challenge(verifier: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(verifier.to_utf8_buffer())
	var hash_bytes = ctx.finish()
	var base64_str = Marshalls.raw_to_base64(hash_bytes)

	base64_str = jwt_lib.base64_to_base64url(base64_str)

	return base64_str

func _wait_for_auth_code() -> String:
	var code: String = ""

	while code == "":
		if redirect_server.is_connection_available():
			_listen_for_oauth_connections = false
			code = _handle_auth_callback(redirect_server.take_connection())
		else:
			await get_tree().process_frame

	return code

func _handle_auth_callback(connection: StreamPeerTCP) -> String:
	var request = connection.get_string(connection.get_available_bytes())

	var temp_auth_code: String = request.split("code=")[1].split("&iss=")[0].strip_edges()

	GlobalLogger.logs("Got authentication code: '%s'." % temp_auth_code)

	# Send success.
	var html_response = "HTTP/1.1 200 OK\r\n"
	html_response += "Content-Type: text/html\r\n"
	html_response += "Connection: close\r\n\r\n"
	html_response += "<html><body><h1>Success!</h1> <p>You can close this window now.</p></body></html>"

	connection.put_data(html_response.to_utf8_buffer())
	connection.disconnect_from_host()

	return temp_auth_code

func _exchange_code() -> Dictionary:
	return {}

func _get_tokens_from_response(response: Dictionary) -> Dictionary:
	# TODO: Error checks to prevent overwriting with bad data.
	var oauth_data = {
		"access_token" = response.get("access_token"),
		"refresh_token" = response.get("refresh_token"),
		"id_token" = response.get("id_token"),
		"access_token_expiry" = response.get("expires_in")
	}

	return oauth_data

func validate_token(account: Dictionary) -> bool:
	if account.access_token == "":
		return false

	var form_parts := [
		"client_id=%s" % "OpenMinerva-Game-Client",
		"token=%s" % account.access_token,
	]
	var form_string: String = "&".join(form_parts)

	var account_server_url = UrlParser.deconstruct(account.account_server)
	if account_server_url.ok == false:
		GlobalLogger.logs("Failed to parse account server url.", Enum.LogLevel.WARNING)
		return false
	account_server_url = account_server_url.data

	var introspect_response = await http.req(HTTPClient.Method.METHOD_POST, account_server_url.host, "/oauth/token/introspection", account_server_url.port, ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded"], form_string)
	if introspect_response.ok == false:
		GlobalLogger.logs("Unknown error parsing the introspection response.", Enum.LogLevel.WARNING)
		return false
	introspect_response = JSON.parse_string(introspect_response.body)

	return introspect_response.active
