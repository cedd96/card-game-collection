extends Node2D

# Eigenschaften:
# Handkarten
# Leben
# Hat geschoben?
# Hat gepasst?
# Ist am Zug / Ist aktiv?

# Funktionen:
# Zug starten / aktiv werden - Buttons enablen
# Schieben
# Passen
# Tauschen - Einzel + Gesamttausch in einer Funktion abwickeln
# Zug beenden

# This Script handles Player Input.

var cardPositions: Array = [
	Vector2(875, 990),
	Vector2(960, 990),
	Vector2(1045, 990)
]

var defaultCardScale: float = 0.35

var identifier: String = "You"
var cards: Array
var lives: int = 3

var is_player_active: bool = false

var selectedCards: Array
var focusedCard: Button = null
var hoveredCard: Button = null

enum {
	EXPAND,
	SHRINK
}

const EXPAND_TIME: float = 0.0015625
const SHRINK_TIME: float = 0.003125

var animationStateCard1: int = EXPAND
var animationStateCard2: int = EXPAND
var animationStateCard3: int = EXPAND

signal winning_hand_31(winnerNode)
signal winning_hand_blitz(winnerNode)
signal player_checked(playerNode)
signal player_passed(playerNode)
signal has_lost(playerNode)

signal menu_pressed()
signal ending_turn()

signal card_1_selected()
signal card_2_selected()
signal card_3_selected()
	
func _ready() -> void:
	load("res://Assets/Themes/Text/UserFrameLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	$PlayerInformationWidget.changeUsername(identifier)
	$PlayerControls/GameButtons/PlayerUITextureButtonMenu.grab_focus()
	
func disableControls() -> void:
	$PlayerControls/GameButtons/PlayerUITextureButtonSchieben.disable()
	$PlayerControls/GameButtons/PlayerUITextureButtonPassen.disable()

func enableControls() -> void:
	$PlayerControls/GameButtons/PlayerUITextureButtonSchieben.enable()
	$PlayerControls/GameButtons/PlayerUITextureButtonPassen.enable()
	
func isAlive() -> bool:
	if lives > -1:
		return true
	return false 
	
func hasLostRound() -> void:
	lives -= 1
	if !isAlive():
		GlobalRules.getPlayers().erase(self)
		emit_signal("has_lost", self)
	else:
		$PlayerInformationWidget.refreshHealth()

func getCurrentHealth() -> int:
	return lives

func areCardsRevealed() -> bool:
	return true
	
func getIdentifier() -> String:
	return identifier
	
func getSelectedCards() -> Array:
	return selectedCards
	
func startTurn() -> void:
	is_player_active = true
	for el in get_children():
		if "CardButton" in el.name:
			el.disabled = false
	enableControls()
	$PlayerControls/GameButtons/PlayerUITextureButtonMenu.grab_focus()
#	self.focusFirstAvailableButton()

func endTurn() -> void:
	is_player_active = false
	disableControls()
	$PlayerControls/GameButtons/PlayerUITextureButtonMenu.grab_focus()
	self.shrinkCards()
	selectedCards.clear()
	focusedCard = null
	hoveredCard = null
	for el in get_children():
		if "CardButton" in el.name:
			el.disabled = true
			el.get_child(0).unselect()
	emit_signal("ending_turn")
	
func giveLastCardBack() -> Node:
	var card = cards[cards.size() - 1]
	for el in get_children():
		if "CardButton" in el.name:
			if card in el.get_children():
				el.remove_child(card)
				cards.remove_at(cards.find(card))
				removeCardSignal(el)
	return card
	
func getCardCount() -> int:
	return cards.size()

func receiveCard(card: Object) -> void:
	card.scale = Vector2(0.35, 0.35)
	if $CardButton1.get_children().size() == 0:
		cards.insert(0, card)
		$CardButton1.add_child(card)
		$CardButton1.pressed.connect(_on_card_button_1_pressed)
		$CardButton1.focus_entered.connect(_on_card_button_1_focus_entered)
		$CardButton1.focus_exited.connect(_on_card_button_1_focus_exited)
		$CardButton1.mouse_entered.connect(_on_card_button_1_mouse_entered)
		$CardButton1.mouse_exited.connect(_on_card_button_1_mouse_exited)
	elif $CardButton2.get_children().size() == 0:
		cards.insert(1, card)
		$CardButton2.add_child(card)
		$CardButton2.pressed.connect(_on_card_button_2_pressed)
		$CardButton2.focus_entered.connect(_on_card_button_2_focus_entered)
		$CardButton2.focus_exited.connect(_on_card_button_2_focus_exited)
		$CardButton2.mouse_entered.connect(_on_card_button_2_mouse_entered)
		$CardButton2.mouse_exited.connect(_on_card_button_2_mouse_exited)
	elif $CardButton3.get_children().size() == 0:
		cards.insert(2, card)
		$CardButton3.add_child(card)
		$CardButton3.pressed.connect(_on_card_button_3_pressed)
		$CardButton3.focus_entered.connect(_on_card_button_3_focus_entered)
		$CardButton3.focus_exited.connect(_on_card_button_3_focus_exited)
		$CardButton3.mouse_entered.connect(_on_card_button_3_mouse_entered)
		$CardButton3.mouse_exited.connect(_on_card_button_3_mouse_exited)
	checkHandValue()

func removeCardSignal(cardBtn: Node) -> void:
	if cardBtn == $CardButton1:
		$CardButton1.pressed.disconnect(_on_card_button_1_pressed)
		$CardButton1.focus_entered.disconnect(_on_card_button_1_focus_entered)
		$CardButton1.focus_exited.disconnect(_on_card_button_1_focus_exited)
		$CardButton1.mouse_entered.disconnect(_on_card_button_1_mouse_entered)
		$CardButton1.mouse_exited.disconnect(_on_card_button_1_mouse_exited)
	if cardBtn == $CardButton2:
		$CardButton2.pressed.disconnect(_on_card_button_2_pressed)
		$CardButton2.focus_entered.disconnect(_on_card_button_2_focus_entered)
		$CardButton2.focus_exited.disconnect(_on_card_button_2_focus_exited)
		$CardButton2.mouse_entered.disconnect(_on_card_button_2_mouse_entered)
		$CardButton2.mouse_exited.disconnect(_on_card_button_2_mouse_exited)
	if cardBtn == $CardButton3:
		$CardButton3.pressed.disconnect(_on_card_button_3_pressed)
		$CardButton3.focus_entered.disconnect(_on_card_button_3_focus_entered)
		$CardButton3.focus_exited.disconnect(_on_card_button_3_focus_exited)
		$CardButton3.mouse_entered.disconnect(_on_card_button_3_mouse_entered)
		$CardButton3.mouse_exited.disconnect(_on_card_button_3_mouse_exited)

func getHandValue() -> float:
	var spadesValue: float = 0
	var crossValue: float = 0
	var heartValue: float = 0
	var diamondValue: float = 0
	
	if cards[0].getType() == cards[1].getType() and cards[0].getType() == cards[2].getType():
		return 30.5
	else:
		for el in cards:
			match el.getColor():
				"Kreuz":
					crossValue += el.getValue()
				"Piek":
					spadesValue += el.getValue()
				"Herz":
					heartValue += el.getValue()
				"Karo":
					diamondValue += el.getValue()
		return max(spadesValue, crossValue, heartValue, diamondValue)

func checkHandValue() -> void:
	if cards.size() == 3:
		if getHandValue() == 31:
			emit_signal("winning_hand_31", self)
		if "A" in cards[0].titel and "A" in cards[1].titel and "A" in cards[2].titel:
			emit_signal("winning_hand_blitz", self)
			
func showHandvalue() -> void:
	$PointLabel.visible = true
	if "A" in cards[0].titel and "A" in cards[1].titel and "A" in cards[2].titel:
		$PointLabel.text = "Blitz"
	else:
		$PointLabel.text = str(getHandValue())
	
func hideHandvalue() -> void:
	$PointLabel.text = ""
	$PointLabel.visible = false

func selectAllCards() -> void:
	selectedCards.clear()
	for el in get_children():
		if "CardButton" in el.name:
			selectedCards.append(el.get_children()[0])

func unselectAllCards() -> void:
	shrinkCards()
	for entry in selectedCards:
		entry.unselect()
	selectedCards.clear()

func _on_player_schieben_pressed() -> void:
	self.endTurn()
	emit_signal("player_checked", self)

func _on_player_passen_pressed() -> void:
	self.endTurn()
	emit_signal("player_passed", self)

func shrinkCards() -> void:
	animationStateCard1 = SHRINK
	$CardExpandTimer1.start(SHRINK_TIME)
	
	animationStateCard2 = SHRINK
	$CardExpandTimer2.start(SHRINK_TIME)
	
	animationStateCard3 = SHRINK
	$CardExpandTimer3.start(SHRINK_TIME)

func _on_card_button_1_pressed() -> void:
	if is_player_active:
		if $CardButton1.get_child(0) in selectedCards:
			selectedCards.remove_at(selectedCards.find($CardButton1.get_child(0)))
		else:
			selectedCards.append($CardButton1.get_child(0))
		$CardButton1.get_child(0).toggleSelection()
		emit_signal("card_1_selected")

func _on_card_button_1_focus_entered() -> void:
	focusedCard = $CardButton1
	animationStateCard1 = EXPAND
	$CardExpandTimer1.start(EXPAND_TIME)

func _on_card_button_1_focus_exited() -> void:
	if $CardButton1.get_child(0) not in selectedCards and $CardButton1.get_child(0) != hoveredCard:
		animationStateCard1 = SHRINK
		$CardExpandTimer1.start(SHRINK_TIME)
	
func _on_card_button_1_mouse_entered() -> void:
	if cards.size() >= 1:
		hoveredCard = $CardButton1
		animationStateCard1 = EXPAND
		$CardExpandTimer1.start(EXPAND_TIME)

func _on_card_button_1_mouse_exited() -> void:
	if $CardButton1.get_child(0) not in selectedCards:
		animationStateCard1 = SHRINK
		$CardExpandTimer1.start(SHRINK_TIME)

func _on_card_expand_timer_1_timeout() -> void:
	## Old Values:
	# Pos:   -131, -5.6
	# Scale: 1.0, 1.0
	## New Values:
	# Pos:   -200, -85
	# Scale: 1.5, 1.5
	var oldPos: Vector2 = Vector2(-131, -5.6)
	var oldScale: Vector2 = Vector2(1.0, 1.0)
	var newPos: Vector2 = Vector2(-200, -85)
	var newScale: Vector2 = Vector2(1.5, 1.5)
	
	if animationStateCard1 == EXPAND:
		if !isMatching($CardButton1.position, newPos) or !isMatching($CardButton1.scale, newScale):
			$CardButton1.scale += Vector2(abs(newScale.x - oldScale.x) / 40, abs(newScale.y - oldScale.y) / 40)
			$CardButton1.position -= Vector2(abs(newPos.x - oldPos.x) / 40, abs(newPos.y - oldPos.y) / 40)
		else:
			$CardExpandTimer1.stop()
	else:
		if !isMatching($CardButton1.position, oldPos) or !isMatching($CardButton1.scale, oldScale):
			$CardButton1.scale -= Vector2(abs(newScale.x - oldScale.x) / 40, abs(newScale.y - oldScale.y) / 40)
			$CardButton1.position += Vector2(abs(newPos.x - oldPos.x) / 40, abs(newPos.y - oldPos.y) / 40)
		else:
			$CardExpandTimer1.stop()

func _on_card_button_2_pressed() -> void:
	if is_player_active:
		if $CardButton2.get_child(0) in selectedCards:
			selectedCards.remove_at(selectedCards.find($CardButton2.get_child(0)))
		else:
			selectedCards.append($CardButton2.get_child(0))
		$CardButton2.get_child(0).toggleSelection()
		emit_signal("card_2_selected")

func _on_card_button_2_focus_entered() -> void:
	focusedCard = $CardButton2
	animationStateCard2 = EXPAND
	$CardExpandTimer2.start(EXPAND_TIME)

func _on_card_button_2_focus_exited() -> void:
	if $CardButton2.get_child(0) not in selectedCards and $CardButton2.get_child(0) != hoveredCard:
		animationStateCard2 = SHRINK
		$CardExpandTimer2.start(SHRINK_TIME)

func _on_card_button_2_mouse_entered() -> void:
	if cards.size() >= 2:
		hoveredCard = $CardButton2
		animationStateCard2 = EXPAND
		$CardExpandTimer2.start(EXPAND_TIME)

func _on_card_button_2_mouse_exited() -> void:
	if $CardButton2.get_child(0) not in selectedCards:
		animationStateCard2 = SHRINK
		$CardExpandTimer2.start(SHRINK_TIME)

func _on_card_expand_timer_2_timeout() -> void:
	## Old Values:
	# Pos:   -42, -5.6
	# Scale: 1.0, 1.0
	## New Values:
	# Pos:   -63, -85
	# Scale: 1.5, 1.5
	var oldPos: Vector2 = Vector2(-42, -5.6)
	var oldScale: Vector2 = Vector2(1.0, 1.0)
	var newPos: Vector2 = Vector2(-63, -85)
	var newScale: Vector2 = Vector2(1.5, 1.5)
	
	if animationStateCard2 == EXPAND:
		if !isMatching($CardButton2.position, newPos) or !isMatching($CardButton2.scale, newScale):
			$CardButton2.scale += Vector2(abs(newScale.x - oldScale.x) / 40, abs(newScale.y - oldScale.y) / 40)
			$CardButton2.position -= Vector2(abs(newPos.x - oldPos.x) / 40, abs(newPos.y - oldPos.y) / 40)
		else:
			$CardExpandTimer2.stop()
	else:
		if !isMatching($CardButton2.position, oldPos) or !isMatching($CardButton2.scale, oldScale):
			$CardButton2.scale -= Vector2(abs(newScale.x - oldScale.x) / 40, abs(newScale.y - oldScale.y) / 40)
			$CardButton2.position += Vector2(abs(newPos.x - oldPos.x) / 40, abs(newPos.y - oldPos.y) / 40)
		else:
			$CardExpandTimer2.stop()

func _on_card_button_3_pressed() -> void:
	if is_player_active:
		if $CardButton3.get_child(0) in selectedCards:
			selectedCards.remove_at(selectedCards.find($CardButton3.get_child(0)))
		else:
			selectedCards.append($CardButton3.get_child(0))
		$CardButton3.get_child(0).toggleSelection()
		emit_signal("card_3_selected")

func _on_card_button_3_focus_entered() -> void:
	focusedCard = $CardButton3
	animationStateCard3 = EXPAND
	$CardExpandTimer3.start(EXPAND_TIME)

func _on_card_button_3_focus_exited() -> void:
	if $CardButton3.get_child(0) not in selectedCards and $CardButton3.get_child(0) != hoveredCard:
		animationStateCard3 = SHRINK
		$CardExpandTimer3.start(SHRINK_TIME)

func _on_card_button_3_mouse_entered() -> void:
	if cards.size() >= 3:
		hoveredCard = $CardButton3
		animationStateCard3 = EXPAND
		$CardExpandTimer3.start(EXPAND_TIME)

func _on_card_button_3_mouse_exited() -> void:
	if $CardButton3.get_child(0) not in selectedCards:
		animationStateCard3 = SHRINK
		$CardExpandTimer3.start(SHRINK_TIME)

func _on_card_expand_timer_3_timeout() -> void:
	## Old Values:
	# Pos:   47, -5.6
	# Scale: 1.0, 1.0
	## New Values:
	# Pos:   74, -85
	# Scale: 1.5, 1.5
	var oldPos: Vector2 = Vector2(47, -5.6)
	var oldScale: Vector2 = Vector2(1.0, 1.0)
	var newPos: Vector2 = Vector2(74, -85)
	var newScale: Vector2 = Vector2(1.5, 1.5)
	
	if animationStateCard3 == EXPAND:
		if !isMatching($CardButton3.position, newPos) or !isMatching($CardButton3.scale, newScale):
			$CardButton3.scale += Vector2(abs(newScale.x - oldScale.x) / 40, abs(newScale.y - oldScale.y) / 40)
			$CardButton3.position -= Vector2(-abs(newPos.x - oldPos.x) / 40, abs(newPos.y - oldPos.y) / 40)
		else:
			$CardExpandTimer3.stop()
	else:
		if !isMatching($CardButton3.position, oldPos) or !isMatching($CardButton3.scale, oldScale):
			$CardButton3.scale -= Vector2(abs(newScale.x - oldScale.x) / 40, abs(newScale.y - oldScale.y) / 40)
			$CardButton3.position += Vector2(-abs(newPos.x - oldPos.x) / 40, abs(newPos.y - oldPos.y) / 40)
		else:
			$CardExpandTimer3.stop()
	
func isMatching(val1: Vector2, val2: Vector2) -> bool:
	if abs(val1 - val2) < Vector2(0.0005, 0.0005):
		return true
	else:
		return false

func focusMenu() -> void:
	$PlayerControls/GameButtons/PlayerUITextureButtonMenu.grab_focus()

func _on_player_ui_texture_button_menu_pressed() -> void:
	emit_signal("menu_pressed")
