# --- License
# File: /client/src/scripts/utils/database.gd
# Project: OpenMinerva
# Created Date: 05 August 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

const DATABASE_PATH: String = "user://spawnable_database.db"

var _db: SQLite = SQLite.new()


func _ready() -> void:
	_db.path = DATABASE_PATH

	# Ensure Database it set up
	if _database_exists() == false:
		GlobalLogger.log("Could not open the spawnable database", Enum.LogLevel.ERROR)
		# Since this is a critical error, I should probably display an error window before force-closing the app?
		return

	_build_database_schema()

	# Preform sanity check to ensure database is not corrupted. Or that it has not changed from when we last changed it.
	# Should we hash the database on close, then read the hash on open to ensure not-corrupted / changed?
	# If there was a difference, would we need to rebuild the database? What would that look like? Sounds expensive!
	return


func _exit_tree() -> void:
	_db.close_db()
	return


func get_spawnable(id: int) -> Dictionary:
	return { }


func set_spawnable(item_hash: String, new_data: Dictionary) -> bool:
	GlobalLogger.log("[ Database ] Updating spawnable '%s'." % item_hash, Enum.LogLevel.DEBUG)
	var _success: bool = _db.insert_row("spawnable", new_data)
	return _success


func get_asset(hash: String) -> Dictionary:
	# TODO: Use query bindings?
	GlobalLogger.log("[ Database ] Getting asset '%s'." % hash, Enum.LogLevel.DEBUG)
	_db.query("SELECT * FROM asset WHERE hash = '%s'" % hash)

	if _db.query_result.is_empty():
		GlobalLogger.log("[ Database ] Asset '%s' does not exist." % hash, Enum.LogLevel.DEBUG)
		return { }

	return _db.query_result[0]


func set_asset(item_hash: String, new_data: Dictionary) -> bool:
	# TODO: Validation before inserting into the database.
	GlobalLogger.log("[ Database ] Updating asset '%s'." % item_hash, Enum.LogLevel.DEBUG)
	var _success: bool = _db.insert_row("asset", new_data)
	return _success


func _database_exists() -> bool:
	var _is_open = _db.open_db()
	return _is_open


func _build_database_schema() -> void:
	_db.query("SELECT name FROM sqlite_master WHERE type='table' AND name='spawnable'")

	if _db.query_result.is_empty():
		GlobalLogger.log("The database table does not exist, this probably means the database was not initialized. Adding the tables now.")

		var _spawnable_table: Dictionary = Dictionary()
		_spawnable_table = {
			"hash": { "data_type": "text", "primary_key": true, "unique": true },
			"name": { "data_type": "text", "not_null": true },
			"directory": { "data_type": "text", "not_null": true },
			"original_owner": { "data_type": "text" },
			"creation_date": { "data_type": "int", "default": -1 },
			"modified_date": { "data_type": "int", "default": -1 },
			"type": { "data_type": "int", "default": -1 },
		}

		var _asset_table: Dictionary = Dictionary()
		_asset_table = {
			"hash": { "data_type": "text", "primary_key": true, "unique": true },
			"size": { "data_type": "int", "default": -1 },
			"directory": { "data_type": "text" },
			"type": { "data_type": "int", "default": -1 },
		}

		_db.create_table("spawnable", _spawnable_table)
		_db.create_table("asset", _asset_table)

		return

	GlobalLogger.log("[ Database ] Database tables exist.", Enum.LogLevel.DEBUG)
	return
