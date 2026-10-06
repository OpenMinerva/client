@warning_ignore("unused_signal")
# --- License
# File: /client/src/scenes/managers/scene/signalbus.gd
# Project: OpenMinerva
# Created Date: 13 April 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends Node

signal node_created(node: Node)
signal node_destroyed(node: Node)
signal node_metadata_change(node: Node)
