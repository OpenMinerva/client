extends Node

var _http = preload("res://scripts/network/http.gd").new()
var _database = {}

func get_public_key(url: String):
    GlobalLogger.logs("Requesting public key from account server '%s'" % url, Enum.LogLevel.INFO)

    # Check if we already have the public key in our database

    # If we do, return that data.
    # Otherwise, http request the account server.
    # Validate the response is valid.
    # Add extra metadata to the database entry.
    # Save to the database.
    return

func reset_database():
    GlobalLogger.logs("Clearing the account server database.", Enum.LogLevel.INFO)
    _database = {}
