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
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	$TextAnimationClock.start(animationClock)
	$MenuControl/ButtonBox/ButtonSchwimmen.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$MenuControl/ButtonBox/ButtonBack.emit_signal("pressed")

func animateFocusText(focBtn: Button) -> void:
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

func animateHoverText(focBtn: Button) -> void:
	if hoverAnimationState == DARKEN:
		if focBtn.modulate != min_modulate:
			focBtn.modulate = focBtn.modulate - Color(animationSpeed, animationSpeed, animationSpeed, 0)
			if focBtn.modulate.is_equal_approx(min_modulate):
				hoverAnimationState = LIGHTEN
	else:
		if focBtn.modulate != default_modulate:
			focBtn.modulate = focBtn.modulate + Color(animationSpeed, animationSpeed, animationSpeed, 0)
			if focBtn.modulate.is_equal_approx(default_modulate):
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

func _on_ButtonSchwimmen_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/HowToPlay/Schwimmen/menu_how_to_play_schwimmen.tscn")

func _on_ButtonSchwimmen_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonSchwimmen)

func _on_ButtonSchwimmen_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonSchwimmen != hoveredButton:
		$MenuControl/ButtonBox/ButtonSchwimmen.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonSchwimmen_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonSchwimmen:
		hoveredButton = $MenuControl/ButtonBox/ButtonSchwimmen

func _on_ButtonSchwimmen_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonSchwimmen:
		$MenuControl/ButtonBox/ButtonSchwimmen.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonMauMau_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/HowToPlay/MauMau/menu_how_to_play_mau_mau.tscn")

func _on_ButtonMauMau_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonMauMau)

func _on_ButtonMauMau_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonMauMau != hoveredButton:
		$MenuControl/ButtonBox/ButtonMauMau.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonMauMau_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonMauMau:
		hoveredButton = $MenuControl/ButtonBox/ButtonMauMau

func _on_ButtonMauMau_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonMauMau:
		$MenuControl/ButtonBox/ButtonMauMau.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonBack_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Main/MenuMain.tscn")

func _on_ButtonBack_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonBack)

func _on_ButtonBack_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonBack != hoveredButton:
		$MenuControl/ButtonBox/ButtonBack.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonBack_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonBack:
		hoveredButton = $MenuControl/ButtonBox/ButtonBack

func _on_ButtonBack_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonBack:
		$MenuControl/ButtonBox/ButtonBack.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_TextAnimationClock_timeout() -> void:
	animateFocusText($MenuControl.get_viewport().gui_get_focus_owner())
	if hoveredButton != null && hoveredButton != $MenuControl.get_viewport().gui_get_focus_owner():
		animateHoverText(hoveredButton)

func _on_PopUp_closed() -> void:
	lastFocusedButton.grab_focus()
