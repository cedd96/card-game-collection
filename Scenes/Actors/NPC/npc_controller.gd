extends Node2D

var identifier: String = ""
var cards: Array
var lives: int = 3
var is_player_active: bool = false

enum {
	REVEALED,
	UNREVEALED
}

var revealStates: Array = [UNREVEALED, UNREVEALED, UNREVEALED]

var startTurnPhase: int = 0
var endTurnPhase: int = 0

var highestValueSingleTrade: float = 0
var highestValueFullTrade: float = 0
var bestChoiceIndex: int = 0
var hasGoodSingleTrade: bool = false
var hasGoodFullTrade: bool = false

var cardToTrade: Node = null
var targetForTrade: Node = null

const loadAnimInterval: float = 0.05

# SIGNALS #
signal winning_hand_31(winnerNode)
signal winning_hand_blitz(winnerNode)
signal player_checked(playerNode)
signal player_passed(playerNode)
signal singleTrade(tradingPlayer, tradeTarget, ownCardIndex)
signal fullTrade(tradingPlayer)
signal has_lost(playerNode)

func _ready() -> void:
	load("res://Assets/Themes/Text/UserFrameLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	identifier = generateIdentifier()
	$PlayerInformationWidget.changeUsername(identifier)

func generateIdentifier() -> String:
	var newIdentifier: String = GlobalValues.identifierChoices.pick_random()
	
	while newIdentifier in GlobalRules.usedIdentifiers:
		newIdentifier = GlobalValues.identifierChoices.pick_random()
	
	GlobalRules.usedIdentifiers.append(newIdentifier)
	return newIdentifier

func getIdentifier() -> String:
	return identifier

func isAlive() -> bool:
	if lives > -1:
		return true
	return false

func hasLostRound() -> void:
	lives -= 1
	if !isAlive():
		print(str(self) + " is eliminated")
		GlobalRules.getPlayers().erase(self)
		emit_signal("has_lost", self)
	else:
		$PlayerInformationWidget.refreshHealth()

func getCurrentHealth() -> int:
	return lives

func startTurn() -> void:
	stopLoadCogAnim()
	match startTurnPhase:
		0:
			highestValueSingleTrade = 0
			highestValueFullTrade = 0
			getBestTradeTarget()
			calculateValueFullTrade()
			if hasGoodSingleTrade or hasGoodFullTrade:
				if hasGoodSingleTrade:
					startTurnPhase = 1
				elif hasGoodFullTrade:
					startTurnPhase = 2
			else:
				startTurnPhase = 3
			hasGoodSingleTrade = false
			hasGoodFullTrade = false
			$LoadAnimTimer.start(loadAnimInterval)
			$RemoteCaller.callDelayed("startTurn", 1.5)
		1:
			emit_signal("singleTrade", self, getBestTradeTarget(), bestChoiceIndex)
			hasGoodSingleTrade = false
			startTurnPhase = 0
		2:
			emit_signal("fullTrade", self)
			hasGoodFullTrade = false
			startTurnPhase = 0
		3:
			checkOrPass()
			startTurnPhase = 0

func getBestTradeTarget() -> Node:
	var bestChoice: Node = null
	var diffVal: float = getHandValue()
	var fieldcards: Array = get_parent().get_parent().get_parent().cards
	for entry in fieldcards:
		for card in cards:
			if calculateValueOfCards(entry, cards.find(card)) > diffVal:
				bestChoice = entry
				diffVal = calculateValueOfCards(entry, cards.find(card))
				bestChoiceIndex = cards.find(card)
				highestValueSingleTrade = diffVal
	if highestValueSingleTrade > getHandValue():
		hasGoodSingleTrade = true
	return bestChoice
	
func calculateValueFullTrade() -> float:
	var fieldcards: Array = get_parent().get_parent().get_parent().cards
	highestValueFullTrade = getValueOfCards(fieldcards)
	if highestValueFullTrade > getHandValue():
		hasGoodFullTrade = true
	return getValueOfCards(fieldcards)

func calculateValueOfCards(card: Node, index: int) -> float:
	var tempCards: Array
	var spadesValue: float = 0
	var crossValue: float = 0
	var heartValue: float = 0
	var diamondValue: float = 0
	
	match index:
		0:
			tempCards = [card, cards[1], cards[2]]
		1:
			tempCards = [cards[0], card, cards[2]]
		2:
			tempCards = [cards[0], cards[1], card]
	
	if tempCards[0].getType() == tempCards[1].getType() and tempCards[0].getType() == tempCards[2].getType():
		return 30.5
	else:
		for el in tempCards:
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

func getValueOfCards(locCards: Array) -> float:
	var spadesValue: float = 0
	var crossValue: float = 0
	var heartValue: float = 0
	var diamondValue: float = 0
	
	if locCards[0].getType() == locCards[1].getType() and locCards[0].getType() == locCards[2].getType():
		return 30.5
	else:
		for el in locCards:
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

func checkOrPass() -> void:
	var rng = RandomNumberGenerator.new()
	rng = rng.randi_range(1, 10)
	if getHandValue() < 27:
		emit_signal("player_checked", self)
	elif getHandValue() >=27 and getHandValue() <= 28:
		if rng >= 1 and rng <= 5:
			emit_signal("player_checked", self)
		else:
			emit_signal("player_passed", self)
	elif getHandValue() >= 29:
		emit_signal("player_passed", self)

func revealLastCard() -> void:
	var index: int = -1
	for entry in revealStates:
		if entry == UNREVEALED:
			index += 1
	if index > -1:
		$CardControl.get_children()[index].get_children()[0].show_behind_parent = false
		revealStates[index] = REVEALED
	
func areCardsRevealed() -> bool:
	for entry in revealStates:
		if entry == UNREVEALED:
			return false
	return true
	
func resetRevealStates() -> void:
	revealStates = [UNREVEALED, UNREVEALED, UNREVEALED]
	
func giveLastCardBack() -> Node:
	var card: Node = null
	for el in $CardControl.get_children():
		if "CardBack" in el.name and el.get_children().size() > 0:
			card = el.get_children()[0]
	removeCard(card)
	return card
	
func getCardCount() -> void:
	return cards.size()
	
func receiveCard(card: Node) -> void:
	card.show_behind_parent = true
	card.scale = Vector2(1, 1)
	
	if $CardControl/CardBack1.get_children().size() == 0:
		cards.insert(0, card)
		$CardControl/CardBack1.visible = true
		$CardControl/CardBack1.add_child(card)
	elif $CardControl/CardBack2.get_children().size() == 0:
		cards.insert(1, card)
		$CardControl/CardBack2.visible = true
		$CardControl/CardBack2.add_child(card)
	elif $CardControl/CardBack3.get_children().size() == 0:
		cards.insert(2, card)
		$CardControl/CardBack3.visible = true
		$CardControl/CardBack3.add_child(card)

	card.size = card.get_parent().size
	checkHandValue()

func removeCard(card: Node) -> void:
	card.show_behind_parent = false
	card.size = Vector2(240, 432)
	card.scale = Vector2(0.5, 0.5)
	
	for el in $CardControl.get_children():
		if "CardBack" in el.name:
			if card in el.get_children():
				el.visible = false
				el.remove_child(card)
				cards.erase(card)

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

func stopLoadCogAnim() -> void:
	$LoadAnimTimer.stop()
	$LoadCogSprite.rotation = 0
	$LoadCogSprite.visible = false

func _on_load_anim_timer_timeout() -> void:
	$LoadCogSprite.visible = true
	$LoadCogSprite.rotation += 3.6

func _on_player_information_widget_ready() -> void:
	$PlayerInformationWidget.changeUsername(getIdentifier())
