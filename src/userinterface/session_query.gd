# --- License
# File: /client/src/userinterface/session_query.gd
# Project: OpenMinerva
# Created Date: 31 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node


func authenticate(url: String) -> Dictionary:
	var _return_dict: Dictionary = { "ok": false, "error": "" }

	# TODO: Do we need a new authentication key?
	if GlobalAccount.get_session_server_token(url) == "":
		var url_deconstructed = UrlParser.deconstruct(url)
		if url_deconstructed.ok == false:
			var ERROR_MESSAGE = "Failed to deconstruct the url '%s'" % url
			GlobalLogger.log(ERROR_MESSAGE, Enum.LogLevel.WARNING)
			_return_dict.error = ERROR_MESSAGE
			return _return_dict
		url_deconstructed = url_deconstructed.data

		var _account = GlobalAccount.get_account(GlobalAccount.active_account)
		var body: Dictionary = {
			"id_token": _account.auth.id_token,
			"challenge": "challenge value",
		}
		var authentication_response = await HTTP.req(HTTPClient.Method.METHOD_POST, url_deconstructed.host, "/api/v1/getAuthenticationKey", url_deconstructed.port, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(body))

		_authentication_request_received(url_deconstructed.host, authentication_response)

	# Get id_token of currently logged in user
	# Sign challenge using private key
	# Send request {id_token, challenge}

	# ... Server does its thing ...

	# Response contains api key, or error

	return _return_dict


func get_sessions() -> Array:
	var _return_arr = []
	var _session_servers = SettingsManager.get_session_servers()

	for server in _session_servers:
		var search = ""
		var tags = ""

		var url_deconstructed = UrlParser.deconstruct(server.url)
		if url_deconstructed.ok == false:
			GlobalLogger.log("Failed to parse the session server URL.", Enum.LogLevel.INFO)
			continue
		url_deconstructed = url_deconstructed.data
		var _api_key = GlobalAccount.get_session_server_token(url_deconstructed.host)
		var form_parts := [
			"search=%s" % search,
			"tags=%s" % tags,
		]
		var form_string: String = "&".join(form_parts)

		var sessions_response = await HTTP.req(HTTPClient.Method.METHOD_GET, url_deconstructed.host, "/api/v1/getSessions?%s" % form_string, url_deconstructed.port, ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded", "x-api-key: %s" % _api_key])

		var sessions_in_server = _session_request_received(url_deconstructed.host, sessions_response)
		# TODO: Validate request health
		_return_arr.append_array(sessions_in_server.data)

	return _return_arr


func _session_request_received(_host: String, response: Dictionary) -> Dictionary:
	var _return_arr = { "ok": false, "error": "", "data": null }

	# TODO: If response.ok
	# TODO: Validate is valid JSON
	# TODO: Validate key exists
	var response_parsed = JSON.parse_string(response.body)

	_return_arr.data = response_parsed.data
	_return_arr.ok = true

	return _return_arr


func _authentication_request_received(_host: String, response: Dictionary) -> Dictionary:
	var _return_arr = { "ok": false, "error": "", "data": null }

	# TODO: If response.ok
	# TODO: Validate is valid JSON
	# TODO: Validate key exists
	var _api_key = JSON.parse_string(response.body).key

	GlobalAccount.set_session_server_token(_host, _api_key)

	# If authentication succeeded, record data
	# Else report error.
	return _return_arr
