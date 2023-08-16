extends CanvasLayer

var focus_symbols = [preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Cross_40x40.png"), preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Diamond_40x40.png"),
						preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Heart_40x40.png"), preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Spade_40x40.png")]

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	$MenuControl/Border.color = Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0))
	$MenuControl/Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	load("res://Assets/Themes/Text/MenuButton.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	var _err = $MenuControl/ButtonOk.connect("pressed", Callable(get_parent(), "_on_PopUp_closed"))
	$MenuControl/ButtonOk.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$MenuControl/ButtonOk.emit_signal("pressed")

func return_random_symbol() -> Sprite2D:
	rng.randomize()
	var symbolIndex = rng.randi_range(0, focus_symbols.size() - 1)
	var newSprite = Sprite2D.new()
	newSprite.texture = focus_symbols[symbolIndex]
	return newSprite

func _on_ButtonOk_focus_entered() -> void:
	var symbolLeft = return_random_symbol()
	symbolLeft.name = "symbolLeft"
	
	var symbolRight = return_random_symbol()
	while symbolRight.texture == symbolLeft.texture:
		symbolRight = return_random_symbol()
	symbolRight.name = "symbolRight"
	
	symbolLeft.position = Vector2($MenuControl/ButtonOk.position.x - 40, $MenuControl/ButtonOk.position.y + $MenuControl/ButtonOk.size.y / 2)
	symbolRight.position = Vector2($MenuControl/ButtonOk.position.x + $MenuControl/ButtonOk.size.x + 40, $MenuControl/ButtonOk.position.y + $MenuControl/ButtonOk.size.y / 2)
	
	$MenuControl.add_child(symbolLeft)
	$MenuControl.add_child(symbolRight)

func _on_ButtonOk_focus_exited() -> void:
	for child in $MenuControl.get_children():
		if "symbol" in child.name:
			child.call_deferred("queue_free")

func _on_ButtonOk_pressed() -> void:
	queue_free()
