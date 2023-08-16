extends CanvasLayer

var focus_symbols = [preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Cross_40x40.png"), preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Diamond_40x40.png"), 
						preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Heart_40x40.png"), preload("res://Assets/Sprites/Cards/Aseprite/40x40_Icons/Spade_40x40.png")]

var rng = RandomNumberGenerator.new()

enum {
	DARKEN,
	LIGHTEN
}

var focusAnimationState = DARKEN
var hoverAnimationState = DARKEN
var animationSpeed = 0.05
var animationClock = 0.025
var default_modulate = Color(1, 1, 1, 1)
var min_modulate = Color(0.3, 0.3, 0.3, 1) #default_modulate.darkened(0.3)

var hoveredButton: Button = null
var lastFocusedButton: Button = null

func _ready() -> void:
	get_tree().paused = false
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	load("res://Assets/Themes/Text/MenuTitle.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	$TextAnimationClock.start(animationClock)
	$MenuControl/ButtonBox/ButtonPlay.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$MenuControl/ButtonBox/ButtonExit.emit_signal("pressed")

func animateFocusText(focBtn: Button) -> void:
	if focBtn != null:
		if focusAnimationState == DARKEN:
			if focBtn.modulate != min_modulate:
				focBtn.modulate = focBtn.modulate - Color(animationSpeed, animationSpeed, animationSpeed, 0)
				if focBtn.modulate.is_equal_approx(min_modulate):
					focusAnimationState = LIGHTEN
		else:
			if focBtn.modulate != default_modulate:
				focBtn.modulate = focBtn.modulate + Color(animationSpeed, animationSpeed, animationSpeed, 0)
				if focBtn.modulate.is_equal_approx(default_modulate):
					focusAnimationState = DARKEN

func animateHoverText(hovBtn: Button) -> void:
	if hovBtn != null:
		if hoverAnimationState == DARKEN:
			if hovBtn.modulate != min_modulate:
				hovBtn.modulate = hovBtn.modulate - Color(animationSpeed, animationSpeed, animationSpeed, 0)
				if hovBtn.modulate.is_equal_approx(min_modulate):
					hoverAnimationState = LIGHTEN
		else:
			if hovBtn.modulate != default_modulate:
				hovBtn.modulate = hovBtn.modulate + Color(animationSpeed, animationSpeed, animationSpeed, 0)
				if hovBtn.modulate.is_equal_approx(default_modulate):
					hoverAnimationState = DARKEN

func returnRandomSymbol() -> Sprite2D:
	rng.randomize()
	var symbolIndex = rng.randi_range(0, focus_symbols.size() - 1)
	var newSprite = Sprite2D.new()
	newSprite.texture = focus_symbols[symbolIndex]
	return newSprite

func returnLongestButton() -> Button:
	var longestButton = null
	for button in $MenuControl/ButtonBox.get_children():
		if button is Button:
			if not longestButton:
				longestButton = button
			else:
				if longestButton.size.x < button.size.x:
					longestButton = button
				elif longestButton.size.x == button.size.x:
					longestButton = button
	return longestButton

func addFocusDecorations(focBtn: Button) -> void:
	lastFocusedButton = focBtn
	var longestButton = returnLongestButton()
	var symbolLeft = returnRandomSymbol()

	var symbolRight = returnRandomSymbol()
	while symbolRight.texture == symbolLeft.texture:
		symbolRight = returnRandomSymbol()

	$MenuControl/ButtonBox.add_child(symbolLeft)
	$MenuControl/ButtonBox.add_child(symbolRight)

	symbolLeft.position = Vector2(longestButton.position.x - symbolLeft.texture.get_width(), 
									$MenuControl/ButtonBox.get_children().find(focBtn) * 80 + longestButton.size.y / 2)
	symbolRight.position = Vector2(longestButton.position.x + longestButton.size.x + symbolRight.texture.get_width(), 
									$MenuControl/ButtonBox.get_children().find(focBtn) * 80 + longestButton.size.y / 2)

func _on_ButtonPlay_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Play/menu_play.tscn")

func _on_ButtonPlay_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonPlay)

func _on_ButtonPlay_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonPlay != hoveredButton:
		$MenuControl/ButtonBox/ButtonPlay.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonPlay_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonPlay:
		hoveredButton = $MenuControl/ButtonBox/ButtonPlay

func _on_ButtonPlay_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonPlay:
		$MenuControl/ButtonBox/ButtonPlay.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonTutorials_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/HowToPlay/MenuHowToPlay.tscn")

func _on_ButtonTutorials_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonTutorials)

func _on_ButtonTutorials_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonTutorials != hoveredButton:
		$MenuControl/ButtonBox/ButtonTutorials.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonTutorials_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonTutorials:
		hoveredButton = $MenuControl/ButtonBox/ButtonTutorials

func _on_ButtonTutorials_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonTutorials:
		$MenuControl/ButtonBox/ButtonTutorials.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonSettings_pressed() -> void:
	GlobalRules.prevMenu = get_path()
	get_tree().change_scene_to_file("res://Scenes/Menus/Settings/MenuSettings.tscn")

func _on_ButtonSettings_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonSettings)

func _on_ButtonSettings_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonSettings != hoveredButton:
		$MenuControl/ButtonBox/ButtonSettings.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonSettings_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonSettings:
		hoveredButton = $MenuControl/ButtonBox/ButtonSettings

func _on_ButtonSettings_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonSettings:
		$MenuControl/ButtonBox/ButtonSettings.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonExit_pressed() -> void:
	get_tree().quit()

func _on_ButtonExit_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonExit)

func _on_ButtonExit_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonExit != hoveredButton:
		$MenuControl/ButtonBox/ButtonExit.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonExit_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonExit:
		hoveredButton = $MenuControl/ButtonBox/ButtonExit

func _on_ButtonExit_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonExit:
		$MenuControl/ButtonBox/ButtonExit.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_TextAnimationClock_timeout() -> void:
	animateFocusText($MenuControl.get_viewport().gui_get_focus_owner())
	if hoveredButton != null && hoveredButton != $MenuControl.get_viewport().gui_get_focus_owner():
		animateHoverText(hoveredButton)

func _on_PopUp_closed() -> void:
	lastFocusedButton.grab_focus()
