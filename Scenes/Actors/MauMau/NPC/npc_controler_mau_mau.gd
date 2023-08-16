extends Node2D

var labelPositionRight: Array = [
	Vector2(254, 450),
	Vector2(430, 60)
]

var labelPositionLeft: Array = [
	Vector2(1490, 60),
	Vector2(1666, 450)
]

var identifier: String = ""

var turnPhase: int = 0
var startTurnProperties: Array = [0, false, "", null]

var cards: Array
var matchingCards: Array
var has_drawn: bool = false

var cardsToDraw: int = 0

const loadAnimInterval: float = 0.05

signal play_card(player, card)
signal end_turn()
signal no_cards_left(player)

func _ready() -> void:
	load("res://Assets/Themes/Text/UserFrameLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	identifier = generateIdentifier()
	$CharacterName.text = getIdentifier()

func setPosition(pos: Vector2) -> void:
	position = pos
	if position in labelPositionLeft:
		$CardCountLabel.position.x = -298
	elif position in labelPositionRight:
		$CardCountLabel.position.x = 216

func generateIdentifier() -> String:
	var newIdentifier: String = GlobalValues.identifierChoices.pick_random()
	
	while newIdentifier in GlobalRules.usedIdentifiers:
		newIdentifier = GlobalValues.identifierChoices.pick_random()
	
	GlobalRules.usedIdentifiers.append(newIdentifier)
	return newIdentifier

func getIdentifier() -> String:
	return identifier

func resetTurnProperties() -> void:
	startTurnProperties = [0, false, false, "", null]
	matchingCards.clear()
	has_drawn = false
	turnPhase = 0
	cardsToDraw = 0

func startTurn(counter7: int = startTurnProperties[0], last_card_B: bool = startTurnProperties[1], chosenColor: String = startTurnProperties[2], topcard: Node = startTurnProperties[3]) -> void:
	startTurnProperties = [counter7, last_card_B, chosenColor, topcard]
	stopLoadCogAnim()
	match turnPhase:
		0: # Entscheiden
			cardsToDraw = counter7 * 2
			if counter7 > 0:
				for card in cards:
					if card.getType() == "7":
						matchingCards.append(card)
			else:
				for card in cards:
					if last_card_B:
						print("calc (chosenColor): " + chosenColor)
						if card.getColor() == chosenColor and card.getType() != "B":
							matchingCards.append(card)
					else:
						if card.getType() == topcard.getType() or card.getColor() == topcard.getColor():
							matchingCards.append(card)
			if matchingCards.size() > 0:
				turnPhase = 1
			else:
				turnPhase = 2
			startLoadCogAnim(loadAnimInterval)
			$RemoteCaller.callDelayed("startTurn", 1.5)
		1: # Karte spielen
			emit_signal("play_card", self, matchingCards.pick_random())
			if getCardCount() == 0:
				emit_signal("no_cards_left", self)
			turnPhase = 0
			resetTurnProperties()
		2: # Karte ziehen
			if cardsToDraw > 0:
				GlobalRules.getRoot().resetCounter()
				singleDraw()
				cardsToDraw -= 1
				GlobalRules.getRoot().refreshDrawText()
				if cardsToDraw == 0:
					turnPhase = 0
					startTurnProperties[0] = 0
				$RemoteCaller.callDelayed("startTurn", 0.7)
			else:
				singleDraw()
				has_drawn = true
				turnPhase = 0
				$RemoteCaller.callDelayed("endTurn", 0.7)

func endTurn() -> void:
	resetTurnProperties()
	emit_signal("end_turn")

func getDrawAmount() -> int:
	return cardsToDraw

func canPlayCard(topcard: Node = null) -> bool:
	if !topcard:
		return true
	for el in cards:
		if el.getType() == topcard.getType() or el.getColor() == topcard.getColor():
			return true
	return false

func singleDraw() -> void:
	print(getIdentifier() + " - DRAW CARD")
	receiveCard(GlobalRules.getDeck().drawCardFromDeck())
	$CardCountLabel.text = str(getCardCount())

func getHandcards() -> Array:
	return cards

func getCardCount() -> int:
	return cards.size()

func receiveCard(card: Node) -> void:
	$CardCountLabel.visible = true
	var numberOfCards: int = cards.size()
	match numberOfCards:
		0:
			$Cards/CardBack1.visible = true
		1:
			$Cards/CardBack2.visible = true
		2:
			$Cards/CardBack3.visible = true
		3:
			$Cards/CardBack4.visible = true
		4:
			$Cards/CardBack5.visible = true
	cards.append(card)
	$CardCountLabel.text = str(int($CardCountLabel.text) + 1)

func playCard(card: Node) -> void:
	if cards.size() <= 5:
		$Cards.get_children()[cards.size() - 1].visible = false
	cards.erase(card)
	$CardCountLabel.text = str(cards.size())

func getColorWish() -> String:
	var heartCount: int = 0
	var diamondCount: int = 0
	var crossCount: int = 0
	var spadeCount: int = 0
	var retString: String = "err:1_getColorWish()"
	
	for el in cards:
		if el.getColor() == "Herz":
			heartCount += 1
		if el.getColor() == "Karo":
			diamondCount += 1
		if el.getColor() == "Kreuz":
			crossCount += 1
		if el.getColor() == "Piek":
			spadeCount += 1
			
	if heartCount == max(heartCount, diamondCount, crossCount, spadeCount):
		retString = "Herz"
	if diamondCount == max(heartCount, diamondCount, crossCount, spadeCount):
		retString = "Karo"
	if crossCount == max(heartCount, diamondCount, crossCount, spadeCount):
		retString = "Kreuz"
	if spadeCount == max(heartCount, diamondCount, crossCount, spadeCount):
		retString = "Piek"

	return retString

func startLoadCogAnim(duration: float) -> void:
	$LoadAnimTimer.start(duration)

func stopLoadCogAnim() -> void:
	$LoadAnimTimer.stop()
	$LoadCogSprite.rotation = 0
	$LoadCogSprite.visible = false

func _on_load_anim_timer_timeout() -> void:
	$LoadCogSprite.visible = true
	$LoadCogSprite.rotation += 3.6
