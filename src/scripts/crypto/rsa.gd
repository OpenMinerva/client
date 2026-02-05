extends Node

var jwt = preload("res://scripts/crypto/jwt.gd").new()

## Generates a RSA keypair at a specific bit length
## @returns Dictionary
func generate_keypair(level: int = 0) -> Dictionary:
	# TODO: Error checks
	var return_dictionary = {"public": "", "private": ""}
	var _target_bits = 0

	match level:
		0:
			_target_bits = 2048
		_:
			_target_bits = 4096

	var crypto = Crypto.new()
	var generated_keys = crypto.generate_rsa(_target_bits)

	return_dictionary.private = generated_keys.save_to_string(false)
	return_dictionary.public = generated_keys.save_to_string(true)
	return return_dictionary

## Verify a signature with a provided public key
## @returns bool
func verify_jwt_signature(jwt_string: String = "", signature_pem: String = "") -> bool:
	var crypto: Crypto = Crypto.new()
	var sig: CryptoKey = pem_to_cryptokey(signature_pem)
	var jwt_parts: Dictionary = jwt._get_jwt_parts(jwt_string)
	var formatted_payload = jwt._format_jwt_payload(jwt_parts.head, jwt_parts.payload)

	return crypto.verify(
		HashingContext.HASH_SHA256,
		formatted_payload.payload_bytes,
		Marshalls.base64_to_raw(jwt_parts.signature),
		sig
	)

## Turns a pem into a CryptoKey
## @returns CryptoKey
func pem_to_cryptokey(pem: String = "") -> CryptoKey:
	# TODO: Error checks
	var public_key := CryptoKey.new()
	if public_key.load_from_string(pem, true) != OK:
		GlobalLogger.logs("Failed to load public key", 3)
		return null

	return public_key