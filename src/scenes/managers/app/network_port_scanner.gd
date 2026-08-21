# --- License
# File: /client/src/scenes/managers/app/network_port_scanner.gd
# Project: OpenMinerva
# Created Date: 20 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node
## This file contains all of the port-related probing functionality.

## The minimum port used by the application (By default)
const MINIMUM_INCREMENTAL_PORT = 20205


## Returns the first port available starting from the [param target_port].
## Finds an available port starting from a target_port and incrementing by one until a open port is found.
## [param target_port] is the port to start the search.
func find_available_port(target_port: int = MINIMUM_INCREMENTAL_PORT) -> int:
	GlobalLogger.log("Trying to find an available port starting at '%s'." % target_port)
	var _found_port = null
	var _is_found = false

	while _is_found == false:
		var port_available = !is_port_in_use(target_port)
		if port_available:
			_found_port = target_port
			_is_found = true
			break
		target_port = target_port + 1

	GlobalLogger.log("Using port '%s'" % target_port, Enum.LogLevel.INFO)

	return _found_port


## Returns true if the port is currently in use. Returns false if the port is free.
## Checks to see if a single port is in use.
## [param port] is the target port to check.
func is_port_in_use(port: int) -> bool:
	var _udp_server = UDPServer.new()
	var _err_udp = _udp_server.listen(port, "*")
	var _tcp_server = TCPServer.new()
	var _err_tcp = _tcp_server.listen(port, "*")

	if _err_udp == OK && _err_tcp == OK:
		_udp_server.stop()
		_tcp_server.stop()
		GlobalLogger.log("Port '%s' is free." % port)
		return false

	_udp_server.stop()
	_tcp_server.stop()
	GlobalLogger.log("Port '%s' is in use." % port)
	return true
