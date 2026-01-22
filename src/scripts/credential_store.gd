# FIXME: IMPORTANT!
# This script is more of a placeholder until a more secure method of storing these credentials becomes available.
# Due to security issues revolving around how Godot handles scripts umong other things, any object can be made accessible by anything else.
# As a result, there just isn't a safe spot to store this data.

extends Node

var info = {
    "token": "",
    "expire_time": ""
}

func set_account_credential(credentials: PackedStringArray = []):
    info.token = credentials[0]
    info.expire_time = credentials[1]
    GlobalLogger.log_string("Saved JWT to memory.")
