extends CanvasLayer

var focus_symbols = [preload("res://Assets/Sprites/Utility/MenuMarkerWhiteLeft.png"), preload("res://Assets/Sprites/Utility/MenuMarkerWhiteRight.png")]

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
	var _err = $MenuControl/ButtonBox/ButtonRestart.connect("pressed", Callable(get_parent(), "_on_Restart_pressed"))
	$TextAnimationClock.start(animationClock)
	$MenuControl/ButtonBox/ButtonRestart.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		call_deferred("queue_free")

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
	var symbolLeft = Sprite2D.new()
	symbolLeft.texture = focus_symbols[0]
	var symbolRight = Sprite2D.new()
	symbolRight.texture = focus_symbols[1]

	$MenuControl/ButtonBox.add_child(symbolLeft)
	$MenuControl/ButtonBox.add_child(symbolRight)

	symbolLeft.position = Vector2(longestButton.position.x - symbolLeft.texture.get_width(), 
									$MenuControl/ButtonBox.get_children().find(focBtn) * 80 + longestButton.size.y / 2)
	symbolRight.position = Vector2(longestButton.position.x + longestButton.size.x + symbolRight.texture.get_width(), 
									$MenuControl/ButtonBox.get_children().find(focBtn) * 80 + longestButton.size.y / 2)

func _on_ButtonRestart_pressed() -> void:
	get_tree().paused = false
	call_deferred("queue_free")

func _on_ButtonRestart_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonRestart)

func _on_ButtonRestart_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonRestart != hoveredButton:
		$MenuControl/ButtonBox/ButtonRestart.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonRestart_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonRestart:
		hoveredButton = $MenuControl/ButtonBox/ButtonRestart

func _on_ButtonRestart_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonRestart:
		$MenuControl/ButtonBox/ButtonRestart.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonBackToMenu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menus/Main/MenuMain.tscn")

func _on_ButtonBackToMenu_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonBackToMenu)

func _on_ButtonBackToMenu_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonBackToMenu != hoveredButton:
		$MenuControl/ButtonBox/ButtonBackToMenu.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonBackToMenu_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonBackToMenu:
		hoveredButton = $MenuControl/ButtonBox/ButtonBackToMenu

func _on_ButtonBackToMenu_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonBackToMenu:
		$MenuControl/ButtonBox/ButtonBackToMenu.modulate = Color(1, 1, 1, 1)
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
