extends Node

# NOTE: To keep things consistent, please keep the signature always in base64. Only convert it where it will be used.

func decode(jwt_string: String = "") -> Dictionary:
	var return_dict = {"ok": false, "data": {}}
	
	var jwt_parts = _get_jwt_parts(jwt_string)

	return_dict.data.head = JSON.parse_string(Marshalls.base64_to_utf8(_base64url_to_base64(jwt_parts.head)))
	return_dict.data.payload = JSON.parse_string(Marshalls.base64_to_utf8(_base64url_to_base64(jwt_parts.payload)))
	# The signature should not be converted from base64
	return_dict.data.signature = _base64url_to_base64(jwt_parts.signature)
	return_dict.ok = true
	return return_dict

func verify(jwt_string: String, public_key: CryptoKey) -> bool:
	var crypto: Crypto = Crypto.new()
	var jwt_parts: Dictionary = _get_jwt_parts(jwt_string)
	if jwt_parts.ok != true:
		GlobalLogger.logs("Failed to deconstruct jwt when verifying jwt.", 2)
		GlobalLogger.logs(str(jwt_string), 0)
		return false

	var formatted_payload: Dictionary = _format_jwt_payload(jwt_parts.head, jwt_parts.payload)
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

# Private functions
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

func _base64url_to_base64(base64url: String):
	# TODO: Error checks
	var fixed: String = base64url

	fixed = fixed.replace("_", "/").replace("-", "+")
	var padding = 4 - (fixed.length() % 4)

	if padding < 4:
		fixed += "=".repeat(padding)

	return fixed

func _get_jwt_parts(jwt_string: String = "") -> Dictionary:
	# TODO: Error checks
	var return_dict = {"ok": false, "head": "", "payload": "", "signature": ""}
	
	var jwt_split = jwt_string.split(".")

	if len(jwt_split) != 3:
		GlobalLogger.logs("JWT token is not formatted correctly.", 2)
		return return_dict
	
	return_dict.head = jwt_split[0]
	return_dict.payload = jwt_split[1]
	return_dict.signature = _base64url_to_base64(jwt_split[2])
	return_dict.ok = true

	return return_dict
