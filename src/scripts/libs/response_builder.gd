# --- License
# File: /client/src/scripts/libs/response_builder.gd
# Project: OpenMinerva
# Created Date: 13 May 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
class_name ResponseBuilder

const TEMPLATE_RESPONSE = { "ok": false, "error": "", "data": { } }


static func success(data: Variant) -> Dictionary:
	var _return_val = TEMPLATE_RESPONSE.duplicate()
	_return_val.set("ok", true)
	_return_val.set("data", data)
	return _return_val


static func error(message: String) -> Dictionary:
	var _return_val = TEMPLATE_RESPONSE.duplicate()
	_return_val.set("ok", false)
	_return_val.set("error", message)
	return _return_val
