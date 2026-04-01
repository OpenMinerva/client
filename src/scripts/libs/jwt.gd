# --- License
# File: /client/src/scripts/libs/jwt.gd
# Project: OpenMinerva
# Created Date: 24 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

# NOTE: To keep things consistent, please keep the signature always in base64. Only convert it where it will be used.
# NOTE: Currently the account server provides JWT that are Base64url encoded. We want to change this to Base64 in this application.

func decode(jwt_string: String = ""):
	var return_dict = {"ok": false, "data": {"head": "", "payload": "", "signature": ""}}
	var jwt_parts = _get_parts(jwt_string)

	return_dict.data.head = JSON.parse_string(Marshalls.base64_to_utf8(base64url_to_base64(jwt_parts.head)))
	return_dict.data.payload = JSON.parse_string(Marshalls.base64_to_utf8(base64url_to_base64(jwt_parts.payload)))
	return_dict.data.signature = base64url_to_base64(jwt_parts.head)
	return_dict.ok = true

	return return_dict

func encode():
	return

func validate(jwt_string: String, public_spki: String):
	var crypto: Crypto = Crypto.new()
	var jwt_parts: Dictionary = _get_parts(jwt_string)
	var public_key: CryptoKey = pem_to_cryptokey(public_spki)
	if jwt_parts.ok != true:
		GlobalLogger.logs("Failed to deconstruct jwt when verifying jwt.", 2)
		GlobalLogger.logs(str(jwt_string), 0)
		return false

	var formatted_payload: Dictionary = _format_payload_for_verification(jwt_parts.head, jwt_parts.payload)
	if formatted_payload.ok != true:
		GlobalLogger.logs("Failed to format the jwt payload when verifying jwt.", 2)
		GlobalLogger.logs(str(jwt_parts), 0)
		return false

	return crypto.verify(
		HashingContext.HASH_SHA256,
		formatted_payload.payload_bytes,
		Marshalls.base64_to_raw(jwt_parts.signature),
		public_key
	)

func base64url_to_base64(input_value: String):
	var fixed: String = input_value

	fixed = fixed.replace("_", "/").replace("-", "+")
	var padding = 4 - (fixed.length() % 4)

	if padding < 4:
		fixed += "=".repeat(padding)

	return fixed

func base64_to_base64url(input_value: String):
	var base64_str = input_value.replace("+", "-")
	base64_str = base64_str.replace("/", "_")

	while base64_str.ends_with("="):
		base64_str = base64_str.substr(0, base64_str.length() - 1)

	return base64_str

func _get_parts(input_value: String):
	# TODO: Error checks
	var return_dict = {"ok": false, "error": "", "head": "", "payload": "", "signature": ""}
	
	var jwt_split = input_value.split(".")

	if len(jwt_split) != 3:
		GlobalLogger.logs("JWT is not formatted correctly.", 2)
		return_dict.error = "JWT is not formatted correctly."
		return return_dict
	
	return_dict.head = jwt_split[0]
	return_dict.payload = jwt_split[1]
	return_dict.signature = base64url_to_base64(jwt_split[2])
	return_dict.ok = true

	return return_dict

func _format_payload_for_verification(head: String, payload: String) -> Dictionary:
	# TODO: Error checks
	var return_dict = {"ok": false, "payload_bytes": []}

	var formatted_payload = head + "." + payload
	var payload_bytes = formatted_payload.to_utf8_buffer()

	var hasher: HashingContext = HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	hasher.update(payload_bytes)

	return_dict.payload_bytes = hasher.finish()
	return_dict.ok = true

	return return_dict

func pem_to_cryptokey(pem: String = "") -> CryptoKey:
	# TODO: Error checks
	var public_key := CryptoKey.new()
	if public_key.load_from_string(pem, true) != OK:
		GlobalLogger.logs("Failed to load public key", 3)
		return null

	return public_key