# --- License
# File: /client/src/scripts/crypto/rsa.gd
# Project: OpenMinerva
# Created Date: 05 February 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License

extends Node

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

## Turns a pem into a CryptoKey
## @returns CryptoKey
func pem_to_cryptokey(pem: String = "") -> CryptoKey:
	# TODO: Error checks
	var public_key := CryptoKey.new()
	if public_key.load_from_string(pem, true) != OK:
		GlobalLogger.logs("Failed to load public key", Enum.LogLevel.ERROR)
		return null

	return public_key
