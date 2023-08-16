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
var animationStep = 0.05
var animationClock = 0.025
var default_modulate = Color(1, 1, 1, 1)
var min_modulate = Color(0.3, 0.3, 0.3, 1) #default_modulate.darkened(0.3)
var errorMsgDefaultModulate = Color(255, 255, 255, 255)

var schwimmenPlayernumberItems: Array = ["1", "2", "3", "4", "5", "6", "7", "8"]
var maumauPlayernumberItems: Array = ["1", "2", "3", "4"]

var hoveredButton: Node = null
var lastFocusedButton: Node = null

var is_colorblindMode_on: bool = false
var is_cardReading_on: bool = false

var gameOptionSelectedItem: String = ""
var playernumberSelectedItem: String = ""

func _ready() -> void:
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	$MenuControl/ButtonBox/GameOptionControl/GameOptionButton/Background.color = $Background.color.lightened(0.2)
	$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton/Background.color = $Background.color.darkened(0.2)
	$TextAnimationClock.start(animationClock)
	$MenuControl/ButtonBox/GameOptionControl/GameOptionButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$MenuControl/ButtonBox/ButtonBack.emit_signal("pressed")

func animateFocusText(focBtn: Button) -> void:
	if focBtn != null and !focBtn.disabled:
		if focusAnimationState == DARKEN:
			if focBtn.modulate != min_modulate:
				focBtn.modulate = focBtn.modulate - Color(animationStep, animationStep, animationStep, 0)
				if focBtn.modulate.is_equal_approx(min_modulate):
					focusAnimationState = LIGHTEN
		else:
			if focBtn.modulate != default_modulate:
				focBtn.modulate = focBtn.modulate + Color(animationStep, animationStep, animationStep, 0)
				if focBtn.modulate.is_equal_approx(default_modulate):
					focusAnimationState = DARKEN

func animateHoverText(hovBtn: Button) -> void:
	if hovBtn != null and !hovBtn.disabled:
		if hoverAnimationState == DARKEN:
			if hovBtn.modulate != min_modulate:
				hovBtn.modulate = hovBtn.modulate - Color(animationStep, animationStep, animationStep, 0)
				if hovBtn.modulate.is_equal_approx(min_modulate):
					hoverAnimationState = LIGHTEN
		else:
			if hovBtn.modulate != default_modulate:
				hovBtn.modulate = hovBtn.modulate + Color(animationStep, animationStep, animationStep, 0)
				if hovBtn.modulate.is_equal_approx(default_modulate):
					hoverAnimationState = DARKEN

func returnRandomSymbol() -> Sprite2D:
	rng.randomize()
	var symbolIndex = rng.randi_range(0, focus_symbols.size() - 1)
	var newSprite = Sprite2D.new()
	newSprite.texture = focus_symbols[symbolIndex]
	return newSprite

func returnLongestButton() -> Node:
	var longestButton = null
	for button in $MenuControl/ButtonBox.get_children():
		if button is Button or button is Control:
			if not longestButton:
				longestButton = button
			else:
				if longestButton.size.x < button.size.x:
					longestButton = button
				elif longestButton.size.x == button.size.x:
					longestButton = button
	return longestButton

func addFocusDecorations(focBtn: Node) -> void:
	lastFocusedButton = focBtn
	var longestButton = returnLongestButton()
	var symbolLeft = returnRandomSymbol()

	var symbolRight = returnRandomSymbol()
	while symbolRight.texture == symbolLeft.texture:
		symbolRight = returnRandomSymbol()

	$MenuControl/ButtonBox.add_child(symbolLeft)
	$MenuControl/ButtonBox.add_child(symbolRight)

	symbolLeft.position = Vector2(longestButton.position.x - symbolLeft.texture.get_width(), 
									$MenuControl/ButtonBox.get_children().find(focBtn) * 100 + longestButton.size.y / 2)
	symbolRight.position = Vector2(longestButton.position.x + longestButton.size.x + symbolRight.texture.get_width(), 
									$MenuControl/ButtonBox.get_children().find(focBtn) * 100 + longestButton.size.y / 2)

func _on_GameOptionButton_item_selected(index: int) -> void:
	gameOptionSelectedItem = $MenuControl/ButtonBox/GameOptionControl/GameOptionButton.get_item_text(index)
	playernumberSelectedItem = "1"
	$MenuControl/ButtonBox/ButtonStart.disabled = false
	$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.disabled = false
	$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton/Background.color = $Background.color.lightened(0.2)
	while $MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.item_count > 0:
		$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.remove_item($MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.item_count - 1)
	if $MenuControl/ButtonBox/GameOptionControl/GameOptionButton.get_item_text(index) == "Schwimmen (31)":
		for el in schwimmenPlayernumberItems:
			$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.add_item(el)
	else:
		for el in maumauPlayernumberItems:
			$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.add_item(el)

func _on_GameOptionButton_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/GameOptionControl)

func _on_GameOptionButton_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not (child is Button or child is Control):
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/GameOptionControl/GameOptionButton != hoveredButton:
		$MenuControl/ButtonBox/GameOptionControl/GameOptionButton.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_GameOptionButton_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/GameOptionControl/GameOptionButton:
		hoveredButton = $MenuControl/ButtonBox/GameOptionControl/GameOptionButton

func _on_GameOptionButton_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/GameOptionControl/GameOptionButton:
		$MenuControl/ButtonBox/GameOptionControl/GameOptionButton.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_PlayernumberButton_item_selected(index: int) -> void:
	playernumberSelectedItem = $MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.get_item_text(index)
	$MenuControl/ButtonBox/ButtonStart.disabled = false

func _on_PlayernumberButton_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/PlayernumberControl)

func _on_PlayernumberButton_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not (child is Button or child is Control):
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton != hoveredButton:
		$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_PlayernumberButton_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton:
		hoveredButton = $MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton

func _on_PlayernumberButton_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton:
		$MenuControl/ButtonBox/PlayernumberControl/PlayernumberButton.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonStart_pressed() -> void:
	if gameOptionSelectedItem != "" and playernumberSelectedItem != "":
		GlobalRules.numberOfNPCs = int(playernumberSelectedItem)
		if gameOptionSelectedItem == "Schwimmen (31)":
			get_tree().change_scene_to_file("res://Scenes/Games/Schwimmen/schwimmen.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/Games/MauMau/mau_mau.tscn")

func _on_ButtonStart_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonStart)

func _on_ButtonStart_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not (child is Button or child is Control):
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonStart != hoveredButton:
		$MenuControl/ButtonBox/ButtonStart.modulate = Color(1, 1, 1, 1)
		focusAnimationState = DARKEN

func _on_ButtonStart_mouse_entered() -> void:
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonStart:
		hoveredButton = $MenuControl/ButtonBox/ButtonStart

func _on_ButtonStart_mouse_exited() -> void:
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonStart:
		$MenuControl/ButtonBox/ButtonStart.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_ButtonBack_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Main/MenuMain.tscn")

func _on_ButtonBack_focus_entered() -> void:
	addFocusDecorations($MenuControl/ButtonBox/ButtonBack)

func _on_ButtonBack_focus_exited() -> void:
	for child in $MenuControl/ButtonBox.get_children():
		if not (child is Button or child is Control):
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
