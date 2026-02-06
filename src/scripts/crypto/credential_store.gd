# FIXME: IMPORTANT!
# This script is more of a placeholder until a more secure method of storing these credentials becomes available.
# Due to security issues revolving around how Godot handles scripts umong other things, any object can be made accessible by anything else.
# As a result, there just isn't a safe spot to store this data.
extends Node

var private_account_server_jwt = {
    "token": "",
    "expire_time": ""
}

var public_account_server_passport = ""

func set_public_account_server_passport(token: String):
    public_account_server_passport = token
    GlobalLogger.logs("Saved public_account_server_passport to memory.")

func set_private_account_server_jwt(credentials: PackedStringArray = []):
    private_account_server_jwt.token = credentials[0]
    private_account_server_jwt.expire_time = credentials[1]
    GlobalLogger.logs("Saved private_account_server_jwt to memory.")

func get_public_account_server_passport() -> String:
    return public_account_server_passport