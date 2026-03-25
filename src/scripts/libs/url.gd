# --- License
# File: /client/src/scripts/libs/url.gd
# Project: OpenMinerva
# Created Date: 25 March 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

func deconstruct(url: String) -> Dictionary:
	var return_dict = {"ok": false, "error": "", "data": {"host": "", "port": 0, "path": "", "query": ""}}

	var url_regex = RegEx.create_from_string("^((?:https?):\\/\\/)?([^:\\/\\s]+)(?::(\\d+))?((?:\\/[^?#\\s]*)*)([\\w\\-\\.]+[^?#\\s]*)?(\\?[^#\\s]*)?(#.*)?$")

	var match = url_regex.search(url)
	if match:
		var groups = match.get_strings()

		return_dict.data.host = groups[1] + groups[2]
		return_dict.data.port = groups[3]
		return_dict.data.path = groups[4]
		return_dict.data.query = groups[6]

		return_dict.ok = true
		return return_dict

	return_dict.error = "No matches."
	return return_dict

func construct(url_dict: Dictionary) -> Dictionary:
	var return_dict = {"ok": false, "error": "", "data": ""}

	if !url_dict.host:
		return_dict.error = "No host in url_dict. Malformed request!"
		return return_dict
	
	return_dict.data += url_dict.host

	if url_dict.port != "":
		return_dict.data += ":" + url_dict.port

	return_dict.data += url_dict.path
	return_dict.data += url_dict.query
	return_dict.ok = true
	return return_dict