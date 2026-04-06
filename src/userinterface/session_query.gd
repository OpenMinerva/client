# --- License
# File: /client/src/userinterface/session_query.gd
# Project: OpenMinerva
# Created Date: 31 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

var http = preload("res://scripts/network/http.gd").new()

const SESSION_SERVERS = ["http://localhost:40500/"]
var api_key = ""

func authenticate() -> Dictionary:
	var _return_arr = {"ok": false, "error": ""}

	var url_deconstructed = UrlParser.deconstruct("http://localhost:40500")
	if url_deconstructed.ok == false:
		const ERROR_MESSAGE = "Failed to parse the session server URL."
		GlobalLogger.logs(ERROR_MESSAGE, 1)
		_return_arr.error = ERROR_MESSAGE
		return _return_arr
	url_deconstructed = url_deconstructed.data

	var body: Dictionary = {
		"id_token": GlobalAccount.active_account.id_token,
		"challenge": "challenge value"
	}
	var authentication_response = await http.req(HTTPClient.Method.METHOD_POST, url_deconstructed.host, "/api/v1/getAuthenticationKey", url_deconstructed.port, ["Accept: application/json", "Content-Type: application/json"], JSON.stringify(body))

	_authentication_request_received(url_deconstructed.host, authentication_response)

	# Get id_token of currently logged in user
	# Sign challenge using private key
	# Send request {id_token, challenge}

	# ... Server does its thing ...

	# Response contains api key, or error

	return _return_arr

func get_sessions() -> Array:
	var _return_arr = []

	for server in SESSION_SERVERS:
		var search = ""
		var tags = ""

		var url_deconstructed = UrlParser.deconstruct(server)
		if url_deconstructed.ok == false:
			GlobalLogger.logs("Failed to parse the session server URL.", 1)
			continue
		url_deconstructed = url_deconstructed.data

		var form_parts := [
			"search=%s" % search,
			"tags=%s" % tags,
		]
		var form_string: String = "&".join(form_parts)

		var sessions_response = await http.req(HTTPClient.Method.METHOD_GET, url_deconstructed.host, "/api/v1/getSessions?%s" % form_string, url_deconstructed.port, ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded", "x-api-key: %s" % api_key])

		var sessions_in_server = _session_request_received(url_deconstructed.host, sessions_response)
		# TODO: Validate request health
		_return_arr.append_array(sessions_in_server.data)

	return _return_arr

func _session_request_received(host: String, response: Dictionary) -> Dictionary:
	var _return_arr = {"ok": false, "error": "", "data": null}

	# TODO: If response.ok
	# TODO: Validate is valid JSON
	# TODO: Validate key exists
	var response_parsed = JSON.parse_string(response.body)
	print(response_parsed)

	_return_arr.data = response_parsed.sessions
	_return_arr.ok = true

	return _return_arr

func _authentication_request_received(host: String, response: Dictionary) -> Dictionary:
	var _return_arr = {"ok": false, "error": "", "data": null}

	# TODO: If response.ok
	# TODO: Validate is valid JSON
	# TODO: Validate key exists

	api_key = JSON.parse_string(response.body).key

	# If authentication succeeded, record data
	# Else report error.
	return _return_arr