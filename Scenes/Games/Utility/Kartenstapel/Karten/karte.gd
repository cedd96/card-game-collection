extends TextureRect

var titel: String = "null"
var color: String = "null"
var type: String = "null"
var value: int = 0

func cardInitialize(newColor: String, newType: String, newValue: int) -> void:
	color = newColor
	type = newType
	value = newValue
	titel = color + " " + type
	name = titel
	setTexture()

func setTexture() -> void:
	match getColor():
		"Herz":
			$ColorTexture.texture = load("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Heart_40x40.png")
		"Karo":
			$ColorTexture.texture = load("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Diamond_40x40.png")
		"Kreuz":
			$ColorTexture.texture = load("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Cross_40x40.png")
		"Piek":
			$ColorTexture.texture = load("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Spade_40x40.png")
	if getColor() == "Herz" or getColor() == "Karo":
		$TypeLabel.set("theme_override_colors/font_color", GlobalValues.colorRed)
	else:
		$TypeLabel.set("theme_override_colors/font_color", GlobalValues.colorBlack)
	$TypeLabel.text = getType()

func setSprite() -> void:
	texture = load("res://Assets/Sprites/Cards/Aseprite/Cardbodies/" + color + ".png")
	for label in $OuterNumberAnchor.get_children():
		if color in "Herz Karo":
			label.set("theme_override_colors/font_color", GlobalValues.colorRed)
		elif color in "Kreuz Piek":
			label.set("theme_override_colors/font_color", GlobalValues.colorBlack)
		label.text = type
	for label in $InnerNumberAnchor.get_children():
		if color in "Herz Karo":
			label.set("theme_override_colors/font_color", GlobalValues.colorRed)
		elif color in "Kreuz Piek":
			label.set("theme_override_colors/font_color", GlobalValues.colorBlack)
		label.text = type

func getValue() -> int:
	return value

func getType() -> String:
	return type

func getColor() -> String:
	return color

func toggleSelection() -> void:
	$Highlighter.visible = !$Highlighter.visible
	
func select() -> void:
	$Highlighter.visible = true

func unselect() -> void:
	$Highlighter.visible = false
