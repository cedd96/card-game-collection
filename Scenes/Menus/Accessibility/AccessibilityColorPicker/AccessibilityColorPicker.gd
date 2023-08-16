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

var hoveredButton: Button = null
var lastFocusedButton: Button = null

var is_colorblindMode_on: bool = false
var is_cardReading_on: bool = false




func _ready() -> void:
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	load("res://Assets/Themes/Text/MenuTitle.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	
	$TextColorPicker.color = Settings.config.get_value("Colors", "textcolor")
	$BackgroundColorPicker.color = Settings.config.get_value("Colors", "backgroundcolor")
	
	$TextAnimationClock.start(animationClock)
	change_TextColorPicker()
	change_BackgroundColorPicker()
	$TextColorPicker.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$MenuControl/ButtonBox/ButtonBack.emit_signal("pressed")

func animateFocusText(focBtn: Button) -> void:
	if !(focBtn is ColorPickerButton):
		if focBtn != null:
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
	if !(hovBtn is ColorPickerButton):
		if hovBtn != null:
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

func _on_button_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menus/Settings/MenuSettings.tscn")

func _on_button_back_focus_entered():
	addFocusDecorations($MenuControl/ButtonBox/ButtonBack)

func _on_button_back_focus_exited():
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonBack != hoveredButton:
		$MenuControl/ButtonBox/ButtonBack.modulate = GlobalValues.colorDefault
		focusAnimationState = DARKEN

func _on_button_back_mouse_entered():
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonBack:
		hoveredButton = $MenuControl/ButtonBox/ButtonBack

func _on_button_back_mouse_exited():
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonBack:
		$MenuControl/ButtonBox/ButtonBack.modulate = GlobalValues.colorDefault
		hoverAnimationState = DARKEN

func _on_text_animation_clock_timeout():
	animateFocusText($MenuControl.get_viewport().gui_get_focus_owner())
	if hoveredButton != null && hoveredButton != $MenuControl.get_viewport().gui_get_focus_owner():
		animateHoverText(hoveredButton)

func _on_button_default_focus_entered():
	addFocusDecorations($MenuControl/ButtonBox/ButtonDefault)

func _on_button_default_focus_exited():
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonDefault != hoveredButton:
		$MenuControl/ButtonBox/ButtonDefault.modulate = GlobalValues.colorDefault
		focusAnimationState = DARKEN

func _on_button_default_mouse_entered():
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonDefault:
		hoveredButton = $MenuControl/ButtonBox/ButtonDefault

func _on_button_default_mouse_exited():
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonDefault:
		$MenuControl/ButtonBox/ButtonDefault.modulate = GlobalValues.colorDefault
		hoverAnimationState = DARKEN







#------------------TextColorPicker-------------------#

func change_TextColorPicker() -> void:
	$TextColorPicker.get_picker().color_modes_visible = false
	$TextColorPicker.get_picker().sliders_visible = false
	$TextColorPicker.get_picker().hex_visible = false
	$TextColorPicker.get_picker().presets_visible = false

func _on_text_color_picker_color_changed(color):
	load("res://Assets/Themes/Text/MenuButton.tres").set_color("font_color", "Button", color)
	load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", color)
	load("res://Assets/Themes/Text/MenuTitle.tres").set_color("font_color", "Label", color)
	load("res://Assets/Themes/Text/ScrollButton.tres").set_color("font_color", "Button", color)
	load("res://Assets/Themes/Text/UserFrameLabel.tres").set_color("font_color", "Label", color)
	#GlobalValues.colorDefault = color
	Settings.config.set_value("Colors", "textcolor", color)
	Settings.config.save(Settings.save_path)


func _on_text_color_picker_button_popup_closed():
	$TextColorPicker.color = Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0))

func _on_text_color_picker_button_focus_entered():
	$MenuControl/TextColor.modulate = default_modulate
	hoverAnimationState = DARKEN

func _on_text_color_picker_button_focus_exited():
	if $TextColorPicker != hoveredButton:  
		$MenuControl/TextColor.modulate = GlobalValues.colorDefault
		focusAnimationState = DARKEN

func _on_text_color_picker_button_mouse_entered():
	$MenuControl/TextColor.modulate = default_modulate
	hoverAnimationState = DARKEN

func _on_text_color_picker_button_mouse_exited():
	if $TextColorPicker != lastFocusedButton:
		$MenuControl/TextColor.modulate = GlobalValues.colorDefault


#------------------BackgroundColorPicker-------------------#

func change_BackgroundColorPicker() -> void:
	$BackgroundColorPicker.get_picker().color_modes_visible = false
	$BackgroundColorPicker.get_picker().sliders_visible = false
	$BackgroundColorPicker.get_picker().hex_visible = false
	$BackgroundColorPicker.get_picker().presets_visible = false

func _on_background_color_picker_button_color_changed(color):
	GlobalValues.colorBackgroundDefault = color
	Settings.config.set_value("Colors", "backgroundcolor", color)
	Settings.config.save(Settings.save_path)
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))

func _on_background_color_picker_button_focus_entered():
	$MenuControl/BackgroundColor.modulate = default_modulate
	hoverAnimationState = DARKEN

func _on_background_color_picker_button_focus_exited():
	if $BackgroundColorPicker != hoveredButton:
		$MenuControl/BackgroundColor.modulate = GlobalValues.colorDefault
		focusAnimationState = DARKEN

func _on_background_color_picker_button_mouse_entered():
	$MenuControl/BackgroundColor.modulate = default_modulate
	hoverAnimationState = DARKEN

func _on_background_color_picker_button_mouse_exited():
	if $BackgroundColorPicker != lastFocusedButton:
		$MenuControl/BackgroundColor.modulate = GlobalValues.colorDefault
		hoverAnimationState = DARKEN


#------------------DefaultColor-------------------#

func _on_button_default_pressed():
	load("res://Assets/Themes/Text/MenuButton.tres").set_color("font_color", "Button", Color(1, 1, 1, 1))
	load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", Color(1, 1, 1, 1))
	load("res://Assets/Themes/Text/MenuTitle.tres").set_color("font_color", "Label", Color(1, 1, 1, 1))
	
	Settings.config.set_value("Colors", "textcolor", Color(1, 1, 1, 1))
	Settings.config.set_value("Colors", "backgroundcolor", Color(0.10980392247438, 0.20000000298023, 0.08627451211214))
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	
	Settings.config.save(Settings.save_path)

func _on_button_default_button_up():
	$TextColorPicker.color = Settings.config.get_value("Colors", "textcolor")
	$BackgroundColorPicker.color = Settings.config.get_value("Colors", "backgroundcolor")
