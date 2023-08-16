extends Button

@export var labelText: String = ""

var defaultColorBorder: Color
var defaultColorBody: Color
var defaultColorLabel: Color

func _ready() -> void:
	$ButtonLabel.text = labelText
	defaultColorBorder = Settings.config.get_value("Colors", "textcolor")
	defaultColorBody = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	defaultColorLabel = Settings.config.get_value("Colors", "textcolor")
	setColors()

func setColors() -> void:
	$BorderColor.color = defaultColorBorder
	$BodyColor.color = defaultColorBody

func activate() -> void:
	$DisabledShadow.visible = false

func deactivate() -> void:
	$DisabledShadow.visible = true

func _on_ButtonDown() -> void:
	for el in get_children():
		if "Border" in el.name:
			el.color = defaultColorBorder.lightened(0.2)
		elif "Body" in el.name:
			el.color = defaultColorBody.lightened(0.2)
		elif "Label" in el.name:
			el.add_theme_color_override("font_color", defaultColorLabel.lightened(0.2))

func _on_ButtonUp() -> void:
	for el in get_children():
		if "Border" in el.name:
			el.color = defaultColorBorder
		elif "Body" in el.name:
			el.color = defaultColorBody
		elif "Label" in el.name:
			el.add_theme_color_override("font_color", defaultColorLabel)

func _on_Focused_or_Hovered() -> void:
	for el in get_children():
		if "Border" in el.name:
			el.color = defaultColorBorder.lightened(0.1)
		elif "Body" in el.name:
			el.color = defaultColorBody.lightened(0.1)
		elif "Label" in el.name:
			el.add_theme_color_override("font_color", defaultColorLabel.lightened(0.1))

func _on_FocusExited() -> void:
	if !is_hovered():
		for el in get_children():
			if "Border" in el.name:
				el.color = defaultColorBorder
			elif "Body" in el.name:
				el.color = defaultColorBody
			elif "Label" in el.name:
				el.add_theme_color_override("font_color", defaultColorLabel)

func _on_MouseExited() -> void:
	if !has_focus():
		for el in get_children():
			if "Border" in el.name:
				el.color = defaultColorBorder
			elif "Body" in el.name:
				el.color = defaultColorBody
			elif "Label" in el.name:
				el.add_theme_color_override("font_color", defaultColorLabel)

