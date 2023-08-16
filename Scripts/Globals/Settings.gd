extends Node
#Config

#Save location
var save_path = "res://Savefiles/config.cfg"
var config = ConfigFile.new()
var err = config.load("res://Savefiles/config.cfg")

func _ready():
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	
	if err != OK:
		config.set_value("Colors", "textcolor", Color(1, 1, 1, 1))
		config.set_value("Colors", "backgroundcolor", Color(0.10980392247438, 0.20000000298023, 0.08627451211214))
		config.set_value("Graphics", "Resolution", Vector2i(1440, 900))
		config.set_value("Graphics", "Fullscreen", DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_size(config.get_value("Graphics", "Resolution"))
		DisplayServer.window_set_mode(config.get_value("Graphics", "Fullscreen"))
		load("res://Assets/Themes/Text/MenuButton.tres").set_color("font_color", "Button", config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
		load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
		load("res://Assets/Themes/Text/MenuTitle.tres").set_color("font_color", "Label", config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	config.save(save_path)
 







