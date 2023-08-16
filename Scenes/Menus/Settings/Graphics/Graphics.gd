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

var Resolutions: Dictionary = {
	"3840x2160":Vector2i(3840,2160),
	"2560x1440":Vector2i(2560,1440),
	"1920x1080":Vector2i(1920,1080),
	"1600x900":Vector2i(1600,900),
	"1536x864":Vector2i(1536,864),
	"1440x900":Vector2i(1440,900),
	"1366x768":Vector2i(1366,768),
	"1280x720":Vector2i(1280,720),
	"1024x600":Vector2i(1024,600),
	"800x600":Vector2i(800,600),
}


func _ready():
	$MenuControl/ButtonBox/OptionButton.disabled = false
	$MenuControl/Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	$MenuControl/ButtonBox/OptionButton/Background.color = $MenuControl/Background.color.darkened(0.2)
	for button in $MenuControl/ButtonBox.get_children():
		if button.disabled == true:
			button.focus_mode = 0
	$TextAnimationClock.start(animationClock)
	if $MenuControl/ButtonBox/OptionButton.disabled == false:
		$MenuControl/ButtonBox/OptionButton.grab_focus()
	else:
		$MenuControl/ButtonBox/ButtonWindowmode.grab_focus()
	AddResolutions()
	
	if Settings.config.get_value("Graphics", "Fullscreen") == DisplayServer.WINDOW_MODE_FULLSCREEN:
		$MenuControl/ButtonBox/ButtonWindowmode.text = "Mode: Fullscreen"
		$MenuControl/ButtonBox/OptionButton.select(getItemIndex(DisplayServer.window_get_size()))
		$MenuControl/ButtonBox/OptionButton.disabled = true
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$MenuControl/ButtonBox/ButtonBack.emit_signal("pressed")

func animateFocusText(focBtn: Node) -> void:
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

func animateHoverText(hovBtn: Node) -> void:
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
		$MenuControl/ButtonBox/ButtonBack.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_button_windowmode_focus_entered():
	addFocusDecorations($MenuControl/ButtonBox/ButtonWindowmode)

func _on_button_windowmode_focus_exited():
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/ButtonWindowmode != hoveredButton:
		$MenuControl/ButtonBox/ButtonWindowmode.modulate = GlobalValues.colorDefault
		focusAnimationState = DARKEN

func _on_button_windowmode_mouse_entered():
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonWindowmode:
		hoveredButton = $MenuControl/ButtonBox/ButtonWindowmode

func _on_button_windowmode_mouse_exited():
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/ButtonWindowmode:
		$MenuControl/ButtonBox/ButtonWindowmode.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN

func _on_option_button_focus_entered():
	addFocusDecorations($MenuControl/ButtonBox/OptionButton)

func _on_option_button_focus_exited():
	for child in $MenuControl/ButtonBox.get_children():
		if not child is Button:
			child.call_deferred("queue_free")
	if $MenuControl/ButtonBox/OptionButton != hoveredButton:
		$MenuControl/ButtonBox/OptionButton.modulate = GlobalValues.colorDefault
		focusAnimationState = DARKEN

func _on_option_button_mouse_entered():
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/OptionButton:
		hoveredButton = $MenuControl/ButtonBox/OptionButton

func _on_option_button_mouse_exited():
	hoveredButton = null
	if $MenuControl.get_viewport().gui_get_focus_owner() != $MenuControl/ButtonBox/OptionButton:
		$MenuControl/ButtonBox/OptionButton.modulate = Color(1, 1, 1, 1)
		hoverAnimationState = DARKEN




func _on_text_animation_clock_timeout():
	animateFocusText($MenuControl.get_viewport().gui_get_focus_owner())
	if hoveredButton != null && hoveredButton != $MenuControl.get_viewport().gui_get_focus_owner():
		animateHoverText(hoveredButton)



#------------------ResolutionsMenu-------------------#

func AddResolutions():
	var CurrentResolution = DisplayServer.window_get_size()
	var Index = 0
	for r in Resolutions:
		$MenuControl/ButtonBox/OptionButton.add_item(r, Index)
		if Resolutions[r] == CurrentResolution:
			$MenuControl/ButtonBox/OptionButton._select_int(Index)
		else:
			if Resolutions[r] == CurrentResolution + Vector2i(2, 2):
				$MenuControl/ButtonBox/OptionButton._select_int(Index)
		Index += 1

func getItemIndex(resolution: Vector2i) -> int:
	var index = 0
	for entry in Resolutions:
		if Resolutions[entry] == resolution:
			return index
		elif Resolutions[entry] == resolution + Vector2i(2, 2):
			return index
		index += 1
	return -1

func _on_option_button_item_selected(index):
	var size = Resolutions.get($MenuControl/ButtonBox/OptionButton.get_item_text(index))
	Settings.config.set_value("Graphics", "Resolution", size)
	Settings.config.save(Settings.save_path)
	DisplayServer.window_set_size(size)

#------------------FullscreenToggle-------------------#

func _on_button_windowmode_pressed():
	if Settings.config.get_value("Graphics", "Fullscreen") == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		Settings.config.set_value("Graphics", "Fullscreen", DisplayServer.WINDOW_MODE_WINDOWED)
		Settings.config.save(Settings.save_path)
		
		$MenuControl/ButtonBox/ButtonWindowmode.text = "Mode: Window"
		print(Settings.config.get_value("Graphics", "Resolution"))
		DisplayServer.window_set_size(Settings.config.get_value("Graphics", "Resolution"))
		
		var Index = 0
		for i in Resolutions:
			if Resolutions[i] == DisplayServer.window_get_size():
				$MenuControl/ButtonBox/OptionButton.select(Index)
			Index += 1
		
		$MenuControl/ButtonBox/OptionButton.disabled = false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		Settings.config.set_value("Graphics", "Fullscreen", DisplayServer.WINDOW_MODE_FULLSCREEN)
		Settings.config.save(Settings.save_path)
		
		$MenuControl/ButtonBox/ButtonWindowmode.text = "Mode: Fullscreen"
		
		#1920x1080 Standard
		#$MenuControl/ButtonBox/OptionButton.select(2)
		
		var Index = 0
		for i in Resolutions:
			if Resolutions[i] == DisplayServer.screen_get_size(DisplayServer.window_get_current_screen(0)):
				$MenuControl/ButtonBox/OptionButton.select(Index)
			Index += 1
		
		$MenuControl/ButtonBox/OptionButton.disabled = true










