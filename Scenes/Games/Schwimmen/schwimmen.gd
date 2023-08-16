extends Node2D

# Eigenschaften:
# Liste von Teilnehmern
# Kartendeck
# Utility Eigenschaften

# Funktionen:
# Startspieler bestimmen
# Nächsten Spieler bestimmen
# Rundenverlierer bestimmen / Leben abziehen
# Spielgewinner bestimmen
# Kartendeck mischen
# Karten austeilen
# Karten einsammeln
# Feldkarten austauschen
# Runde beenden

@onready var carddeck: Object = $Gameobjects/Kartenstapel
var carddeck_default_pos: Vector2 = Vector2(1280, 540)

var userframePositions: Array = [
	#Vector2(960, 850), Playerposition
	Vector2(170, 840),
	Vector2(170, 450),
	Vector2(170, 60),
	Vector2(690, 60),
	Vector2(1230, 60),
	Vector2(1750, 60),
	Vector2(1750, 450),
	Vector2(1750, 840)
]

var fieldcardPositions: Array = [
	Vector2(840, 540),
	Vector2(960, 540),
	Vector2(1080, 540)
]

var checkCounter = 0
var cardswapPhase = 0
var can_cards_be_removed: bool = true

var cards: Array
var selectedCards: Array

var cardRecipients: Array
var lastRecipientIndex: int = 0

var passedPlayer: Node = null

var startingPlayer: Node = null

# Systemmessage Properties
var textBufferDelayAmount: float = 1
var textBufferTimeoutCounter: int
var textBufferTimeoutMax: int
var nextSystemMessage: String = ""
var currentShownCharacters: int = 0
var additionalDelayTime: float = 0

var roundStartTimerDelay: int = 0

var is_round_starting: bool = true

var was_deck_shuffled: bool = false
var were_cards_dealt: bool = false
var has_player_been_determined: bool = false

var receivedCardsPerPlayer: Array 

## End Round Properties
var is_round_ending: bool = false
var endingPhase: int = 0
var revealingPlayer: Node = null

var losers: Array
var loserIndex: int = 0

var collectionIndex: int = 0
var are_cards_collected: bool = false

var selectedFieldCard: Node = null
var playerSelectedCards: Array

var tradePhase: int = 0
var fieldcardsTrade: Array
var handcardsTrade: Array
var cardIndex: int = -1

var winner: Node = null
var winner_detected: bool = false
var won_with_aces: bool = false

# NPC TRADE #
var npcTrade: Node = null
var npcTradeTarget: Node = null
var npcCard: Node = null
var eliminatedPlayers: Array

var is_paused: bool = false

func _ready() -> void:
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	GlobalRules.reset()
	loadNPCs()
	$Gameobjects/Participants/Player.focusMenu()
	for el in $Gameobjects/Participants.get_children():
		GlobalRules.addPlayer(el)
	if is_round_starting:
		roundStartTimerDelay = 5
		self.newSystemMessage("Round starts in " + str(roundStartTimerDelay))
		$ShortDelayTimer.start(0.5)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = true
		add_child(load("res://Scenes/Menus/Pause/pause_menu.tscn").instantiate())

func loadNPCs() -> void:
	var npcResource: Resource = load("res://Scenes/Actors/NPC/npc_controller.tscn")
	var npc: Node = null
	var index: int = 0
	while index < GlobalRules.numberOfNPCs:
		npc = npcResource.instantiate()
		npc.name = "NPC" + str(index)
		$Gameobjects/Participants.add_child(npc)
		connectNPC(npc)
		npc.position = userframePositions[index]
		index += 1

func connectNPC(npc: Node) -> void:
	npc.connect("winning_hand_31", Callable(self, "_on_winning_hand_31"))
	npc.connect("winning_hand_blitz", Callable(self, "_on_winning_hand_blitz"))
	npc.connect("player_checked", Callable(self, "_on_current_checked"))
	npc.connect("player_passed", Callable(self, "_on_current_passed"))
	npc.connect("singleTrade", Callable(self, "_on_npc_controller_single_trade"))
	npc.connect("fullTrade", Callable(self, "_on_npc_controller_full_trade"))
	npc.connect("has_lost", Callable(self, "_on_player_has_lost"))

func newSystemMessage(message: String) -> void:
	GlobalRules.is_system_buffering = true
	nextSystemMessage = message
	$SystemMessage.text = nextSystemMessage.substr(0, 0)
	currentShownCharacters = 1
	var bufferTime = float(textBufferDelayAmount) / message.length()
	textBufferTimeoutCounter = 0
	textBufferTimeoutMax = message.length()
	$SystemMessage/TextBuffer.start(bufferTime)

func startRound() -> void:
	if !GlobalRules.is_system_buffering:
		if !was_deck_shuffled:
			checkCounter = 0
			roundStartTimerDelay = 5
			passedPlayer = null
			self.shuffeCards()
			was_deck_shuffled = true
		else:
			if !were_cards_dealt:
				if is_round_starting:
					self.newRecipientList()
					newSystemMessage("Dealing cards...")
					is_round_starting = false
				if !GlobalRules.is_system_buffering:
					self.dealCards()
			else:
				if !has_player_been_determined:
					self.determinStartingPlayer()
					has_player_been_determined = true

	if was_deck_shuffled and were_cards_dealt and has_player_been_determined:
		$GameSequenceTimer.stop()
		if winner_detected:
			announceWinner()
		else:
			$PlayerStartTurnTimer.start(0.1)
	else:
		$GameSequenceTimer.start(0.1)

func endRound() -> void:
	is_round_ending = true
	if !GlobalRules.is_system_buffering:
		match endingPhase:
			-1:
				if winner != $Gameobjects/Participants/Player:
					if winner_detected and !winner.areCardsRevealed():
						winner.revealLastCard()
						$RemoteCaller.callDelayed("endRound", GlobalRules.systemBufferingAmountDealCards)
					else:
						endingPhase = 0
						$RemoteCaller.callDelayed("announceEndRoundMsg", 2)
				else:
					endingPhase = 0
					$RemoteCaller.callDelayed("announceEndRoundMsg", 2)
			0: # 1. Reveal Handcards of all Players
				var areAllCardsRevealed: bool = true
				for el in $Gameobjects/Participants.get_children():
					if !el.areCardsRevealed():
						areAllCardsRevealed = false
				if areAllCardsRevealed:
					endingPhase = 1
					generateArrayOfLosers()
					for el in $Gameobjects/Participants.get_children():
						if el != $Gameobjects/Participants/Player:
							el.resetRevealStates()
					$RemoteCaller.callDelayed("endRound", 3)
				else:
					if revealingPlayer == $Gameobjects/Participants/Player:
						var cardsReavealed: bool = true
						for el in cardRecipients.slice(0, cardRecipients.find($Gameobjects/Participants/Player)):
							if !el.areCardsRevealed:
								cardsReavealed = false
						if cardsReavealed:
							revealingPlayer.showHandvalue()
						revealingPlayer = GlobalRules.getNextPlayerAfter(revealingPlayer)
					revealingPlayer.revealLastCard()
					if revealingPlayer.areCardsRevealed():
						revealingPlayer.showHandvalue()
					revealingPlayer = GlobalRules.getNextPlayerAfter(revealingPlayer)
					$RemoteCaller.callDelayed("endRound", GlobalRules.systemBufferingAmountDealCards)
			1: # 2. Announce the loser/s of the Round
				if loserIndex == losers.size():
					losers.clear()
					loserIndex = 0
					endingPhase = 2
				else:
					if losers[loserIndex] == $Gameobjects/Participants/Player:
						newSystemMessage(losers[loserIndex].getIdentifier() + " have lost with " + str(losers[loserIndex].getHandValue()) + "!")
					else:
						newSystemMessage(losers[loserIndex].getIdentifier() + " has lost with " + str(losers[loserIndex].getHandValue()) + "!")
					losers[loserIndex].hasLostRound()
					loserIndex += 1
				$RemoteCaller.callDelayed("endRound", 2.5)
			2: # 3. Check if more than 1 Player has remaining lives
				for entry in eliminatedPlayers:
					if entry in cardRecipients:
						cardRecipients.erase(entry)
						GlobalRules.getPlayers().erase(entry)
					if entry == $Gameobjects/Participants/Player:
						add_child(load("res://Scenes/Menus/GameOver/game_over_menu.tscn").instantiate())
						get_tree().paused = true
					elif GlobalRules.getPlayers().size() == 1:
						add_child(load("res://Scenes/Menus/WonGame/won_game_menu.tscn").instantiate())
						get_tree().paused = true
					entry.call_deferred("queue_free")
				eliminatedPlayers.clear()
				loserIndex = 0
				var remainingPlayers: int = 0
				for el in $Gameobjects/Participants.get_children():
					if el.isAlive():
						remainingPlayers += 2
				if remainingPlayers > 1: # Collect the Cards of all Players and start the next Round
					if are_cards_collected:
						won_with_aces = false
						winner = null
						is_round_ending = false
						winner_detected = false
						are_cards_collected = false
						collectionIndex = 0
						endingPhase = 0
						was_deck_shuffled = false
						were_cards_dealt = false
						has_player_been_determined = false
						$Gameobjects/Participants/Player.shrinkCards()
						self.newSystemMessage("Round starts in " + str(roundStartTimerDelay))
						$ShortDelayTimer.start(0.5)
					else:
						for el in GlobalRules.getPlayers():
							el.hideHandvalue()
						if nextSystemMessage != "Collecting Cards...":
							newSystemMessage("Collecting Cards...")
							$RemoteCaller.callDelayed("endRound", GlobalRules.systemBufferingAmountDealCards)
						else:
							if collectionIndex == cardRecipients.size():
								collectionIndex = 0
							are_cards_collected = collectCards()
							$RemoteCaller.callDelayed("endRound", GlobalRules.systemBufferingAmountDealCards)
				else:
					for el in $Gameobjects/Participants.get_children():
						newSystemMessage(el.getIdentifier() + " has won the Game!")
	else:
		$RemoteCaller.callDelayed("endRound", 0.05)

func announceEndRoundMsg() -> void:
	newSystemMessage("Revealing Cards...")
	$RemoteCaller.callDelayed("endRound", 1.05)

func collectCards() -> bool:
	if cardRecipients[collectionIndex].cards.size() == 0:
		return true
	else:
		carddeck.addCardToDeck(cardRecipients[collectionIndex].giveLastCardBack())
		collectionIndex += 1
		return false

func giveLastCardBack() -> Node:
	var btnIndex: int = 0
	for el in $Gameobjects/Feldkarten.get_children():
		if el.get_children().size() > 0:
			btnIndex = $Gameobjects/Feldkarten.get_children().find(el)
	var card = $Gameobjects/Feldkarten.get_children()[btnIndex].get_children()[0]
	$Gameobjects/Feldkarten.get_children()[btnIndex].remove_child($Gameobjects/Feldkarten.get_children()[btnIndex].get_children()[0])
	cards.remove_at(cards.find(card))
	return card

func generateArrayOfLosers() -> void:
	if !won_with_aces:
		var lowestValue: float = 100

		for el in $Gameobjects/Participants.get_children():
			if el.getHandValue() < lowestValue:
				lowestValue = el.getHandValue() 

		for el in $Gameobjects/Participants.get_children():
			if el.getHandValue() == lowestValue:
				losers.append(el)
	else:
		for el in GlobalRules.getPlayers():
			if el != winner:
				losers.append(el)

func shuffeCards() -> void:
	self.activateSystemBuffer(GlobalRules.systemBufferingAmountShufflingCards)
	additionalDelayTime = 1
	newSystemMessage("shuffling cards...")
	carddeck.shuffleCards()

func newRecipientList() -> void:
	var subArrayBegin: Array
	var subArrayEnd: Array
	cardRecipients.clear()	
	
	if startingPlayer:
		subArrayBegin = cardRecipients.slice(0, cardRecipients.find(startingPlayer))
		subArrayEnd = cardRecipients.slice(cardRecipients.find(startingPlayer) + 1, cardRecipients.size())
		cardRecipients.append_array(subArrayEnd)
		cardRecipients.append_array(subArrayBegin)
	else:
		cardRecipients.append_array(GlobalRules.getPlayers())
	cardRecipients.append(self)

func dealCards() -> void:
	cardRecipients[lastRecipientIndex].receiveCard(carddeck.getCardFromDeck())
	
	if lastRecipientIndex == cardRecipients.size() - 1:
		lastRecipientIndex = 0
	else:
		lastRecipientIndex += 1
		
	for el in cardRecipients:
		if el.cards.size() < 3:
			were_cards_dealt = false
		else:
			were_cards_dealt = true

func determinStartingPlayer() -> void:
	self.activateSystemBuffer(GlobalRules.systemBufferingAmountDefault)
	if !startingPlayer:
		startingPlayer = GlobalRules.getPlayers().pick_random()
	else:
		startingPlayer = GlobalRules.getNextPlayerAfter(startingPlayer)

func nextPlayer() -> void:
	var currentPlayerIndex = GlobalRules.getPlayers().find(GlobalRules.getCurrentPlayer())
	if currentPlayerIndex < GlobalRules.getPlayers().size() - 1:
		GlobalRules.setCurrentPlayer(GlobalRules.getPlayers()[currentPlayerIndex + 1])
	else:
		GlobalRules.setCurrentPlayer(GlobalRules.getPlayers()[0])
		
	GlobalRules.getCurrentPlayer().startTurn()

func receiveCard(card: Node) -> void:
	card.scale = Vector2(0.5, 0.5)
	if cards.size() < 3:
		if $Gameobjects/Feldkarten/CardButton1.get_children().size() == 0:
			cards.insert(0, card)
			$Gameobjects/Feldkarten/CardButton1.add_child(card)
		elif $Gameobjects/Feldkarten/CardButton2.get_children().size() == 0:
			cards.insert(1, card)
			$Gameobjects/Feldkarten/CardButton2.add_child(card)
		elif $Gameobjects/Feldkarten/CardButton3.get_children().size() == 0:
			cards.insert(2, card)
			$Gameobjects/Feldkarten/CardButton3.add_child(card)

func removeCard() -> bool:
	if cards.size() > 0:
		cards.remove_at(cards.size() - 1)
		match cards.size():
			0:
				carddeck.addCardToDeck($Gameobjects/Feldkarten/CardButton1.get_child(0))
				$Gameobjects/Feldkarten/CardButton1.remove_child($Gameobjects/Feldkarten/CardButton1.get_child(0))
			1:
				carddeck.addCardToDeck($Gameobjects/Feldkarten/CardButton2.get_child(0))
				$Gameobjects/Feldkarten/CardButton2.remove_child($Gameobjects/Feldkarten/CardButton2.get_child(0))
			2:
				carddeck.addCardToDeck($Gameobjects/Feldkarten/CardButton3.get_child(0))
				$Gameobjects/Feldkarten/CardButton3.remove_child($Gameobjects/Feldkarten/CardButton3.get_child(0))
		return true
	else:
		return false

func newFieldcard() -> bool:
	receiveCard(carddeck.getCardFromDeck())
	if cards.size() == 3:
		return true
	else:
		return false

func _on_round_start_timer_timeout() -> void:
	roundStartTimerDelay -= 1
	if roundStartTimerDelay >= 0:
		GlobalRules.is_system_buffering = true
		$SystemMessage.text = "Round starts in " + str(roundStartTimerDelay)
	else:
		$RoundStartTimer.stop()
		GlobalRules.is_system_buffering = false
		self.startRound()

func activateSystemBuffer(time: float) -> void:
	GlobalRules.is_system_buffering = true
	$GameBuffer.one_shot = true
	$GameBuffer.start(time)

func _on_game_buffer_timeout() -> void:
	GlobalRules.is_system_buffering = false

func _on_text_buffer_timeout() -> void:
	textBufferTimeoutCounter += 1
	if textBufferTimeoutCounter == textBufferTimeoutMax:
		$SystemMessage/TextBuffer.stop()
		if additionalDelayTime > 0:
			$SystemMessage/AdditionalDelayTimer.start(additionalDelayTime)
		else:
			GlobalRules.is_system_buffering = false
	$SystemMessage.text = nextSystemMessage.substr(0, currentShownCharacters + 1)
	currentShownCharacters += 1
	
func _on_additional_delay_timer_timeout() -> void:
	additionalDelayTime = 0
	$SystemMessage/AdditionalDelayTimer.stop()
	GlobalRules.is_system_buffering = false

func announceWinner() -> void:
	if won_with_aces:
		newSystemMessage(winner.getIdentifier() + " won with three Aces")
	else:
		newSystemMessage(winner.getIdentifier() + " won with 31")
	endingPhase = -1
	$RemoteCaller.callDelayed("endRound", 1.5)

func _on_winning_hand_31(winnerNode) -> void:
	winner = winnerNode
	winner_detected = true
	won_with_aces = false
	revealingPlayer = winner

func _on_winning_hand_blitz(winnerNode) -> void:
	winner = winnerNode
	winner_detected = true
	won_with_aces = true
	revealingPlayer = winner

func _on_current_checked(playerNode) -> void:
	checkCounter += 1
	if checkCounter == GlobalRules.getPlayers().size():
		checkCounter = 0
		newSystemMessage("Everyone checked!")
		$CardswapTextchangeTimer.start(2)
	else:
		additionalDelayTime = 1
		newSystemMessage(playerNode.getIdentifier() + " checked")
		$NextStartTurnTimer.start(0.1)

func _on_current_passed(playerNode) -> void:
	checkCounter = 0
	if !passedPlayer:
		passedPlayer = playerNode
	additionalDelayTime = 1
	newSystemMessage(playerNode.getIdentifier() + " passed")
	$NextStartTurnTimer.start(1.1)

func _on_game_sequence_timer_timeout() -> void:
	self.startRound()

func _on_short_delay_timer_timeout() -> void:
	$RoundStartTimer.start(1)
	$ShortDelayTimer.stop()

func _on_player_start_turn_timer_timeout() -> void:
	if !GlobalRules.is_system_buffering:
		$PlayerStartTurnTimer.stop()
		if startingPlayer == $Gameobjects/Participants/Player:
			newSystemMessage("Your turn!")
		else:
			if startingPlayer.getIdentifier().ends_with("s"):
				newSystemMessage(startingPlayer.getIdentifier() + "' turn!")
			else:
				newSystemMessage(startingPlayer.getIdentifier() + "s turn!")
		GlobalRules.setCurrentPlayer(startingPlayer)
		GlobalRules.getCurrentPlayer().startTurn()
	else:
		$PlayerStartTurnTimer.start(0.1)

func _on_next_start_turn_timer_timeout() -> void:
	if !GlobalRules.is_system_buffering:
		$NextStartTurnTimer.stop()
		if GlobalRules.getNextPlayer() == passedPlayer:
			newSystemMessage("Round Over!")
			revealingPlayer = passedPlayer
			for entry in selectedCards:
				entry.unselect()
			selectedCards.clear()
			$RemoteCaller.callDelayed("announceEndRoundMsg", 2)
		else:
			for entry in selectedCards:
				entry.unselect()
			selectedCards.clear()
			GlobalRules.setCurrentPlayer(GlobalRules.getNextPlayer())
			GlobalRules.getCurrentPlayer().startTurn()
			if GlobalRules.getCurrentPlayer() == $Gameobjects/Participants/Player:
				newSystemMessage("Your turn!")
			else:
				if GlobalRules.getCurrentPlayer().getIdentifier().ends_with("s"):
					newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + "' turn!")
				else:
					newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + "s turn!")

func tradeSingleCard() -> void:
	match tradePhase:
		0:
			for el in $Gameobjects/Participants/Player.get_children():
				if "CardButton" in el.name:
					if el.get_children()[0] == playerSelectedCards[0]:
						handcardsTrade.append(playerSelectedCards[0])
						$Gameobjects/Participants/Player.removeCardSignal(el)
						el.remove_child(playerSelectedCards[0])
						$Gameobjects/Participants/Player.cards.remove_at($Gameobjects/Participants/Player.cards.find(playerSelectedCards[0]))
						playerSelectedCards[0].scale = Vector2(0.5, 0.5)
			playerSelectedCards.clear()
			$Gameobjects/Participants/Player.selectedCards.clear()
			tradePhase = 1
			$Gameobjects/Participants/Player.shrinkCards()
			$RemoteCaller.callDelayed("tradeSingleCard", GlobalRules.tradeDelay)
		1:
			$Gameobjects/Feldkarten.get_children()[cardIndex].remove_child(selectedFieldCard)
			cards.remove_at(cardIndex)
			tradePhase = 2
			$RemoteCaller.callDelayed("tradeSingleCard", GlobalRules.tradeDelay)
		2:
			selectedFieldCard.unselect()
			$Gameobjects/Participants/Player.receiveCard(selectedFieldCard)
			tradePhase = 3
			$RemoteCaller.callDelayed("tradeSingleCard", GlobalRules.tradeDelay)
		3:
			handcardsTrade[0].unselect()
			self.receiveCard(handcardsTrade[0])
			tradePhase = 4
			$RemoteCaller.callDelayed("tradeSingleCard", 1)
		4:
			$Gameobjects/Participants/Player.endTurn()
			selectedFieldCard = null
			handcardsTrade.clear()
			GlobalRules.is_trading = false
			tradePhase = 0
			if winner_detected:
				announceWinner()
			else:
				$NextStartTurnTimer.start(0.05)

func tradeAllCards() -> void:
	match tradePhase:
		0:
			for el in $Gameobjects/Participants/Player.get_children():
				if "CardButton" in el.name:
					if el.get_children().size() > 0:
						var card = el.get_children()[0]
						handcardsTrade.append(card)
						el.remove_child(card)
						$Gameobjects/Participants/Player.removeCardSignal(el)
						$Gameobjects/Participants/Player.cards.remove_at($Gameobjects/Participants/Player.cards.find(card))
						card.scale = Vector2(0.5, 0.5)
						break
			if $Gameobjects/Participants/Player.cards.size() == 0:
				$Gameobjects/Participants/Player.selectedCards.clear()
				tradePhase = 1
				$Gameobjects/Participants/Player.shrinkCards()
			$RemoteCaller.callDelayed("tradeAllCards", GlobalRules.tradeDelay)
		1: 
			for el in $Gameobjects/Feldkarten.get_children():
				if el.get_children().size() > 0:
					var card = el.get_children()[0]
					fieldcardsTrade.append(card)
					el.remove_child(card)
					cards.remove_at(cards.find(card))
					break
			if cards.size() == 0:
				tradePhase = 2
			$RemoteCaller.callDelayed("tradeAllCards", GlobalRules.tradeDelay)
		2: 
			if $Gameobjects/Participants/Player.cards.size() < 3:
				fieldcardsTrade[0].unselect()
				$Gameobjects/Participants/Player.receiveCard(fieldcardsTrade[0])
				fieldcardsTrade.remove_at(0)
			else:
				tradePhase = 3
			$RemoteCaller.callDelayed("tradeAllCards", GlobalRules.tradeDelay)
		3:
			if cards.size() < 3:
				handcardsTrade[0].unselect()
				self.receiveCard(handcardsTrade[0])
				handcardsTrade.remove_at(0)
				$RemoteCaller.callDelayed("tradeAllCards", GlobalRules.tradeDelay)
			else:
				tradePhase = 4
				$RemoteCaller.callDelayed("tradeAllCards", 1)
		4:
			$Gameobjects/Participants/Player.endTurn()
			selectedCards.clear()
			selectedFieldCard = null
			handcardsTrade.clear()
			fieldcardsTrade.clear()
			GlobalRules.is_trading = false
			tradePhase = 0
			if winner_detected:
				announceWinner()
			else:
				$NextStartTurnTimer.start(0.05)

func tradeCards() -> bool:
	$Gameobjects/Participants/Player.disableControls()
	playerSelectedCards = $Gameobjects/Participants/Player.getSelectedCards()
	match playerSelectedCards.size():
		1:
			newSystemMessage("Trading Cards...")
			checkCounter = 0
			selectedFieldCard = $Gameobjects/Feldkarten.get_children()[cardIndex].get_child(0)
			self.tradeSingleCard()
		3:
			newSystemMessage("Trading Cards...")
			checkCounter = 0
			self.tradeAllCards()
		_:
			$Gameobjects/Participants/Player.unselectAllCards()
			$Gameobjects/Participants/Player.enableControls()
			return false
	GlobalRules.is_trading = true
	return true

func _on_card_button_1_pressed() -> void:
	if $Gameobjects/Participants/Player == GlobalRules.getCurrentPlayer() and !GlobalRules.is_trading and !is_round_ending:
		if $Gameobjects/Feldkarten/CardButton1.get_children()[0] in selectedCards:
			selectedCards.erase($Gameobjects/Feldkarten/CardButton1.get_children()[0])
		else:
			selectedCards.append($Gameobjects/Feldkarten/CardButton1.get_children()[0])
		cardIndex = 0
		if !self.tradeCards():
			$Gameobjects/Feldkarten/CardButton1.get_child(0).toggleSelection()

func _on_card_button_2_pressed() -> void:
	if $Gameobjects/Participants/Player == GlobalRules.getCurrentPlayer() and !GlobalRules.is_trading and !is_round_ending:
		if $Gameobjects/Feldkarten/CardButton2.get_children()[0] in selectedCards:
			selectedCards.erase($Gameobjects/Feldkarten/CardButton2.get_children()[0])
		else:
			selectedCards.append($Gameobjects/Feldkarten/CardButton2.get_children()[0])
		cardIndex = 1
		if !self.tradeCards():
			$Gameobjects/Feldkarten/CardButton2.get_child(0).toggleSelection()

func _on_card_button_3_pressed() -> void:
	if $Gameobjects/Participants/Player == GlobalRules.getCurrentPlayer() and !GlobalRules.is_trading and !is_round_ending:
		if $Gameobjects/Feldkarten/CardButton3.get_children()[0] in selectedCards:
			selectedCards.erase($Gameobjects/Feldkarten/CardButton3.get_children()[0])
		else:
			selectedCards.append($Gameobjects/Feldkarten/CardButton3.get_children()[0])
		cardIndex = 2
		if !self.tradeCards():
			$Gameobjects/Feldkarten/CardButton3.get_child(0).toggleSelection()

func _on_cardswap_delay_timer_timeout() -> void:
	$CardswapDelayTimer.stop()
	match cardswapPhase:
		0:
			$CardswapDelayTimer.start(GlobalRules.systemBufferingAmountDealCards)
			if can_cards_be_removed:
				can_cards_be_removed = removeCard()
			else:
				can_cards_be_removed = true
				cardswapPhase = 1
		1:
			if !was_deck_shuffled:
				self.shuffeCards()
				was_deck_shuffled = true
			else:
				if !GlobalRules.is_system_buffering:
					cardswapPhase = 2
			$CardswapDelayTimer.start(0.1)
		2:
			var continuationCheck: bool = false
			$CardswapDelayTimer.start(0.01)
			if !GlobalRules.is_system_buffering:
				continuationCheck = newFieldcard()
				if continuationCheck:
					cardswapPhase = 0
					$CardswapDelayTimer.stop()
					$NextStartTurnTimer.start(0.1)
				else:
					activateSystemBuffer(GlobalRules.systemBufferingAmountDealCards)

func _on_cardswap_textchange_timer_timeout() -> void:
	$CardswapTextchangeTimer.stop()
	newSystemMessage("Swapping Cards...")
	$CardswapDelayTimer.start(1.05)
	was_deck_shuffled = false

func npcSingleTrade() -> void:
	match tradePhase:
		0:
			npcTrade.removeCard(npcCard)
			npcCard.scale = Vector2(0.5, 0.5)
			tradePhase = 1
			$RemoteCaller.callDelayed("npcSingleTrade", GlobalRules.tradeDelay)
		1:
			for el in $Gameobjects/Feldkarten.get_children():
				if npcTradeTarget in el.get_children():
					el.remove_child(npcTradeTarget)
					cards.erase(npcTradeTarget)
			tradePhase = 2
			$RemoteCaller.callDelayed("npcSingleTrade", GlobalRules.tradeDelay)
		2:
			npcTrade.receiveCard(npcTradeTarget)
			tradePhase = 3
			$RemoteCaller.callDelayed("npcSingleTrade", GlobalRules.tradeDelay)
		3:
			self.receiveCard(npcCard)
			tradePhase = 4
			$RemoteCaller.callDelayed("npcSingleTrade", 1)
		4:
			npcTrade = null
			npcTradeTarget = null
			npcCard = null
			tradePhase = 0
			if winner_detected:
				announceWinner()
			else:
				$NextStartTurnTimer.start(0.05)

func npcFullTrade() -> void:
	match tradePhase:
		0:
			for el in npcTrade.get_node("CardControl").get_children():
				if el.get_children().size() > 0:
					var card = el.get_children()[0]
					handcardsTrade.append(card)
					npcTrade.removeCard(card)
					card.scale = Vector2(0.5, 0.5)
					break
			if npcTrade.cards.size() == 0:
				tradePhase = 1
			$RemoteCaller.callDelayed("npcFullTrade", GlobalRules.tradeDelay)
		1:
			for el in $Gameobjects/Feldkarten.get_children():
				if el.get_children().size() > 0:
					var card = el.get_children()[0]
					fieldcardsTrade.append(card)
					el.remove_child(card)
					cards.remove_at(cards.find(card))
					break
			if cards.size() == 0:
				tradePhase = 2
			$RemoteCaller.callDelayed("npcFullTrade", GlobalRules.tradeDelay)
		2:
			if npcTrade.cards.size() < 3:
				npcTrade.receiveCard(fieldcardsTrade[0])
				fieldcardsTrade.remove_at(0)
			else:
				tradePhase = 3
			$RemoteCaller.callDelayed("npcFullTrade", GlobalRules.tradeDelay)
		3:
			if cards.size() < 3:
				receiveCard(handcardsTrade[0])
				handcardsTrade.remove_at(0)
				$RemoteCaller.callDelayed("npcFullTrade", GlobalRules.tradeDelay)
			else:
				tradePhase = 4
				$RemoteCaller.callDelayed("npcFullTrade", 1)
		4:
			handcardsTrade.clear()
			fieldcardsTrade.clear()
			npcTrade = null
			npcTradeTarget = null
			npcCard = null
			tradePhase = 0
			if winner_detected:
				announceWinner()
			else:
				$NextStartTurnTimer.start(0.05)

func _on_npc_controller_single_trade(tradingPlayer, tradeTarget, ownCardIndex) -> void:
	newSystemMessage("Trading Cards...")
	checkCounter = 0
	npcTrade = tradingPlayer
	npcTradeTarget = tradeTarget
	npcCard = npcTrade.cards[ownCardIndex]
	$RemoteCaller.callDelayed("npcSingleTrade")

func _on_npc_controller_full_trade(tradingPlayer) -> void:
	newSystemMessage("Trading Cards...")
	checkCounter = 0
	npcTrade = tradingPlayer
	$RemoteCaller.callDelayed("npcFullTrade")

func _on_player_has_lost(eliminatedPlayer: Node) -> void:
	eliminatedPlayers.append(eliminatedPlayer)

func _on_Restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_PauseMenu_exited() -> void:
	get_tree().paused = false
	$Gameobjects/Participants/Player.focusMenu()

func _on_player_menu_pressed() -> void:
	get_tree().paused = true
	add_child(load("res://Scenes/Menus/Pause/pause_menu.tscn").instantiate())

func _on_player_card_1_selected() -> void:
	if $Gameobjects/Participants/Player == GlobalRules.getCurrentPlayer() and !GlobalRules.is_trading and !is_round_ending:
		match selectedCards.size():
			1:
				if $Gameobjects/Participants/Player.getSelectedCards().size() == 1:
					tradeCards()
			2:
				for entry in selectedCards:
					entry.unselect()
				selectedCards.clear()
			3:
				$Gameobjects/Participants/Player.selectAllCards()
				tradeCards()

func _on_player_card_2_selected() -> void:
	if $Gameobjects/Participants/Player == GlobalRules.getCurrentPlayer() and !GlobalRules.is_trading and !is_round_ending:
		match selectedCards.size():
			1:
				if $Gameobjects/Participants/Player.getSelectedCards().size() == 1:
					tradeCards()
			2:
				for entry in selectedCards:
					entry.unselect()
				selectedCards.clear()
			3:
				$Gameobjects/Participants/Player.selectAllCards()
				tradeCards()

func _on_player_card_3_selected() -> void:
	if $Gameobjects/Participants/Player == GlobalRules.getCurrentPlayer() and !GlobalRules.is_trading and !is_round_ending:
		match selectedCards.size():
			1:
				if $Gameobjects/Participants/Player.getSelectedCards().size() == 1:
					tradeCards()
			2:
				for entry in selectedCards:
					entry.unselect()
				selectedCards.clear()
			3:
				$Gameobjects/Participants/Player.selectAllCards()
				tradeCards()

func _on_player_ending_turn() -> void:
	for entry in selectedCards:
		entry.unselect()
	selectedCards.clear()
