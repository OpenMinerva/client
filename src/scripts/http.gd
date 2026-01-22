extends Node

signal _completed(result: Dictionary)

# TODO: When the http client fails to connect to server, no error appears.

func req(method: HTTPClient.Method, host: String, path: String = "/", port: int = 443, headers: PackedStringArray = [], body: String = "") -> Dictionary:
	var thread := Thread.new()
	var params := {
		"method": method,
		"host": host,
		"path": path,
		"port": port,
		"headers": headers,
		"body": body,
		"thread": thread
	}
	thread.start(_thread_main.bind(params))

	return await _completed

func _thread_main(params: Dictionary) -> void:
	var client := HTTPClient.new()
	var result := {
		"ok": false
	}

	var err := client.connect_to_host(params.host, params.port)

	# Could not connect to host
	if err != OK:
		result.error = "Connection failed"
		_finish(params, result)
		return
		
   # Wait for connection
	while client.get_status() == HTTPClient.STATUS_CONNECTING:
		client.poll()
		OS.delay_msec(10)

	# TODO: Change the retry attempts?
	while client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.poll()
		OS.delay_msec(10)

	client.request(params.method, params.path, params.headers, params.body)

	while not client.has_response():
		client.poll()
		OS.delay_msec(10)

	result.status_code = client.get_response_code()
	result.response_headers = client.get_response_headers_as_dictionary()
	
	var response_body := ""
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() > 0:
			response_body += chunk.get_string_from_utf8()
		OS.delay_msec(10)

	client.close()

	result.ok = true
	result.body = response_body

	_finish(params, result)

func _finish(params: Dictionary, result: Dictionary) -> void:
	call_deferred("_emit_completed", params.thread, result)

func _emit_completed(thread: Thread, result: Dictionary) -> void:
	emit_signal("_completed", result)
	thread.wait_to_finish()
