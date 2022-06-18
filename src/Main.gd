extends Control

onready var bar: GDBar = $GDBar
const CONFIG_PATH: String = "/home/spectre7/Projects/Godot/BarTest/config.json"

func _ready():
	OS.set_window_title("GDBar")
	OS.window_position = Vector2(1920, 0)
	OS.window_size.y = 29
	
	bar.loadConfig(CONFIG_PATH)
