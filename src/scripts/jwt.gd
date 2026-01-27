# This provides basic JWT features
extends Node

func verify(jwt_string: String = "", signature_pem: String = "") -> bool:
	# TODO: Error checks
	var crypto: Crypto = Crypto.new()
	var public_key: CryptoKey = _signature_pem_to_cryptokey(signature_pem)
	var jwt_parts: Dictionary = _get_jwt_parts(jwt_string)
	var formatted_payload: Dictionary = _format_jwt_payload(jwt_parts.head, jwt_parts.payload)

	return crypto.verify(
		HashingContext.HASH_SHA256,
		formatted_payload.payload_bytes,
		Marshalls.base64_to_raw(jwt_parts.signature),
		public_key
	)

func decode_jwt(jwt_string: String) -> Dictionary:
	# TODO: Error checks
	var return_dict = {"head": {}, "payload": {}}

	var jwt_parts = _get_jwt_parts(jwt_string)

	jwt_parts.head = _base64url_to_base64(jwt_parts.head)
	jwt_parts.head = Marshalls.base64_to_utf8(jwt_parts.head)
	return_dict.head = JSON.parse_string(jwt_parts.head)

	jwt_parts.payload = _base64url_to_base64(jwt_parts.payload)
	jwt_parts.payload = Marshalls.base64_to_utf8(jwt_parts.payload)
	return_dict.payload = JSON.parse_string(jwt_parts.payload)

	return return_dict

func _base64url_to_base64(base64url: String):
	# TODO: Error checks
	var fixed: String = base64url

	fixed = fixed.replace("_", "/").replace("-", "+")
	var padding = 4 - (fixed.length() % 4)

	if padding < 4:
		fixed += "=".repeat(padding)

	return fixed

func _signature_pem_to_cryptokey(signature_pem: String = "") -> CryptoKey:
	# TODO: Error checks
	var public_key := CryptoKey.new()
	if public_key.load_from_string(signature_pem, true) != OK:
		GlobalLogger.log_string("Failed to load signature", 3)
		return null

	return public_key

func _get_jwt_parts(jwt_string: String = "") -> Dictionary:
	# TODO: Error checks
	var return_dict = {"ok": false, "head": "", "payload": "", "signature": ""}
	
	var jwt_split = jwt_string.split(".")

	if len(jwt_split) != 3:
		GlobalLogger.log_string("JWT token is not formatted correctly.", 2)
		return return_dict
	
	return_dict.head = jwt_split[0]
	return_dict.payload = jwt_split[1]
	return_dict.signature = _base64url_to_base64(jwt_split[2])
	return_dict.ok = true

	return return_dict

func _format_jwt_payload(head: String, payload: String) -> Dictionary:
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