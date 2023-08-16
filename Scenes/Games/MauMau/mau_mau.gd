extends Node2D
#TODO: Player Controls, NPC matchingCards selection (maybe chosen color)
@onready var player: Node = $Gameobjects/Participants/PlayerMauMau
@onready var carddeck: Node = $Gameobjects/CardpileButton/Cardpile
var discardpile: Node = null

var npcPositions: Array = [
	Vector2(254, 450),
	Vector2(430, 60),
	Vector2(1490, 60),
	Vector2(1666, 450),
]

# General Properties #
var recallClock: float = 0.1

# Participant Properties #
var playerSequence: Array
var cardRecipientIndex: int = 0
var haveAllReceived: bool = false

# Game Properties #
var counter7: int = 0
var last_card_8: bool = false
var last_card_B: bool = false
var chosenColor: String = ""
var is_choosing_color: bool = false

# System Message Properties #
var nextSystemMessage: String = ""
var currentShownCharacters: int = 0

# On Start System Message Properties #
var startupPhase: int = 0
var startDelay: float = 1
const startTime: float = 5
var startTimeLeft: float = startTime - 1

# Game Start Properties #
var startGamePhase: int = 0

var is_recycling_deck: bool = false

func _ready() -> void:
	GlobalRules.setRoot(self)
	$Background.color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))
	load("res://Assets/Themes/Text/MenuLabel.tres").set_color("font_color", "Label", Settings.config.get_value("Colors", "textcolor", Color(0, 0, 0, 0)))
	GlobalRules.reset()
	loadNPCs()
	for el in $Gameobjects/Participants.get_children():
		GlobalRules.addPlayer(el)
	onStartSystemMessage()
	startGame()
	#GlobalRules.setCurrentPlayer(player)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_recycling_deck:
			$SystemMessage.process_mode = Node.PROCESS_MODE_INHERIT
			$SysMsgRemoteCaller.process_mode = Node.PROCESS_MODE_INHERIT
			$Gameobjects/CardpileButton/Cardpile.process_mode = Node.PROCESS_MODE_INHERIT
			$Gameobjects/Discardpile.process_mode = Node.PROCESS_MODE_INHERIT
		get_tree().paused = true
		add_child(load("res://Scenes/Menus/Pause/pause_menu.tscn").instantiate())

func newSystemMessage(message: String = "") -> void:
	if currentShownCharacters == 0:
		GlobalRules.is_system_buffering = true
		nextSystemMessage = message
		$SystemMessage.text = nextSystemMessage.substr(0, 0)
		currentShownCharacters = 1
		$SysMsgRemoteCaller.callDelayed("newSystemMessage", float(1) / float(nextSystemMessage.length()))
	else:
		if $SystemMessage.text == nextSystemMessage:
			GlobalRules.is_system_buffering = false
			currentShownCharacters = 0
		else:
			currentShownCharacters += 1
			$SystemMessage.text = nextSystemMessage.substr(0, currentShownCharacters)
			$SysMsgRemoteCaller.callDelayed("newSystemMessage", float(1) / float(nextSystemMessage.length()))

func onStartSystemMessage() -> void:
	match startupPhase:
		0:
			GlobalRules.is_system_buffering = true
			$SystemMessage.text = "Game starts in " + str(startTime)
			startupPhase = 1
			$SysMsgRemoteCaller.callDelayed("onStartSystemMessage", startDelay)
		1:
			if startTimeLeft >= 0:
				$SystemMessage.text = "Game starts in " + str(startTimeLeft)
				startTimeLeft -= 1
				$SysMsgRemoteCaller.callDelayed("onStartSystemMessage", 1)
			else:
				GlobalRules.is_system_buffering = false

func startTurnSystemMessage() -> void:
	if counter7 > 0:
		if GlobalRules.getCurrentPlayer() == player:
			newSystemMessage("You need to draw " + str(counter7 * 2) + " cards")
		else:
			newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + " needs to draw " + str(counter7 * 2) + " cards")
	else:
		if GlobalRules.getCurrentPlayer() == player:
			newSystemMessage("Your turn!")
		else:
			if GlobalRules.getCurrentPlayer().getIdentifier().ends_with("s"):
				newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + "' turn!")
			else:
				newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + "s turn!")

func loadNPCs() -> void:
	var npcResource: Resource = load("res://Scenes/Actors/MauMau/NPC/npc_controler_mau_mau.tscn")
	var npc: Node = null
	var index: int = 0
	while index < GlobalRules.numberOfNPCs:
		npc = npcResource.instantiate()
		npc.name = "NPC" + str(index)
		$Gameobjects/Participants.add_child(npc)
		connectNPC(npc)
		npc.setPosition(npcPositions[index])
		index += 1

func connectNPC(npc: Node) -> void:
	npc.connect("play_card", Callable(self, "_on_playCard"))
	npc.connect("end_turn", Callable(self, "_on_player_mau_mau_end_turn"))
	npc.connect("no_cards_left", Callable(self, "_on_no_cards_left"))

func startGame() -> void:
	if !GlobalRules.is_system_buffering:
		match startGamePhase:
			0: # Shuffle Deck
				newSystemMessage("Shuffling Cards...")
				shuffleCards()
				$RemoteCaller.callDelayed("startGame", GlobalRules.systemBufferingAmountShufflingCards + 1)
				startGamePhase = 1
			1: # Deal Cards
				if nextSystemMessage != "Dealing Cards...":
					determinStartingPlayer()
					newSystemMessage("Dealing Cards...")
					startGame()
				else:
					if !dealCard():
						$RemoteCaller.callDelayed("startGame", GlobalRules.systemBufferingAmountDealCards)
					else:
						$RemoteCaller.callDelayed("nextPlayer", 1)
	else:
		$RemoteCaller.callDelayed("startGame", recallClock)

func shuffleCards() -> void:
	GlobalRules.setDeck(carddeck)
	carddeck.shuffleCards()

func dealCard() -> bool:
	var handcardsCheck: bool = true
	for el in $Gameobjects/Participants.get_children():
		if el.getCardCount() < 5:
			handcardsCheck = false
	if handcardsCheck:
		receiveCard(carddeck.getCardFromDeck())
		return true
	else:
		playerSequence[cardRecipientIndex].receiveCard(carddeck.getCardFromDeck())
		if cardRecipientIndex == playerSequence.size() - 1:
			cardRecipientIndex = 0
		else:
			cardRecipientIndex += 1
		return false

func receiveCard(card: Node) -> void:
	match card.getType():
		"7":
			counter7 += 1
		"8":
			last_card_8 = true
	$Gameobjects/Discardpile.addCard(card)

func determinStartingPlayer() -> void:
	var tempArr1: Array
	var tempArr2: Array
	var startingPlayer: Node = GlobalRules.getPlayers().pick_random()
	
	tempArr1 = GlobalRules.getPlayers().slice(GlobalRules.getPlayers().find(startingPlayer), GlobalRules.getPlayers().size())
	tempArr2 = GlobalRules.getPlayers().slice(0, GlobalRules.getPlayers().find(startingPlayer))
		
	playerSequence.clear()
	playerSequence.append_array(tempArr1)
	playerSequence.append_array(tempArr2)

func nextPlayer() -> void:
	if GlobalRules.currentPlayer == null:
		if last_card_8:
			last_card_8 = false
			GlobalRules.setCurrentPlayer(playerSequence[1])
		else:
			GlobalRules.setCurrentPlayer(playerSequence[0])
	else:
		if last_card_8:
			print("skipping")
			last_card_8 = false
			GlobalRules.setCurrentPlayer(GlobalRules.getNextPlayerAfter(GlobalRules.getNextPlayer()))
		else:
			GlobalRules.setCurrentPlayer(GlobalRules.getNextPlayer())
		if GlobalRules.getPlayerBefore(GlobalRules.getCurrentPlayer()) != player:
			GlobalRules.getPlayerBefore(GlobalRules.getCurrentPlayer()).resetTurnProperties()
	startTurnSystemMessage()
	GlobalRules.getCurrentPlayer().startTurn(counter7, last_card_B, chosenColor, $Gameobjects/Discardpile.getTopcard())

func getLastPlayedCard() -> Node:
	return $Gameobjects/Discardpile.get_children()[$Gameobjects/Discardpile.get_children().size() - 1]

func refreshDrawText() -> void:
	var currentUser: Node = GlobalRules.getCurrentPlayer()
	
	if currentUser.getDrawAmount() > 0:
		if currentUser == player:
			$SystemMessage.text = "You need to draw " + str(currentUser.getDrawAmount()) + " cards"
		else:
			$SystemMessage.text = currentUser.getIdentifier() + " needs to draw " + str(currentUser.getDrawAmount()) + " cards"
	else:
		startTurnSystemMessage()

func drawFor7s() -> void:
	if player.getDrawAmount() == 0:
		player.setDrawAmount(counter7 * 2)
		resetCounter()
	player.setDrawnCard(carddeck.drawCardFromDeck())
	player.get_node("RemoteCaller").callDelayed("receiveCard", 0.7)
	player.setDrawAmount(player.getDrawAmount() - 1)
	if player.getDrawAmount() > 0:
		$RemoteCaller.callDelayed("drawFor7s", 0.7)
		refreshDrawText()
	else:
		newSystemMessage("Your Turn!")
		player.get_node("RemoteCaller2").callDelayed("activate", 0.7)

func enableWishControls() -> void:
	$Gameobjects/WishButtonControl.visible = true
	$Gameobjects/WishButtonControl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for btn in $Gameobjects/WishButtonControl.get_children():
		btn.disabled = false

func disableWishControls() -> void:
	$Gameobjects/WishButtonControl.visible = false
	$Gameobjects/WishButtonControl.mouse_filter = Control.MOUSE_FILTER_STOP
	for btn in $Gameobjects/WishButtonControl.get_children():
		btn.disabled = true
	player.endTurn()

func getChosenColorEng(color: String = chosenColor) -> String:
	if color == "Herz":
		return "Hearts"
	if color == "Karo":
		return "Diamonds"
	if color == "Kreuz":
		return "Cross"
	if color == "Piek":
		return "Spades"
	return "err:2_getChosenColorEng()"

func npcChooseColor() -> void:
	newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + " chose " + getChosenColorEng() + "!")
	GlobalRules.getCurrentPlayer().stopLoadCogAnim()
	GlobalRules.getCurrentPlayer().resetTurnProperties()
	$RemoteCaller.callDelayed("nextPlayer", 2)
	
func resetCounter() -> void:
	counter7 = 0

func _on_TextureButtonHeart_pressed() -> void:
	player.deactivate()
	chosenColor = "Herz"
	newSystemMessage("You chose " + getChosenColorEng() + "!")
	$RemoteCaller.callDelayed("disableWishControls", GlobalRules.systemBufferingAmountTextMsg + 1)

func _onTextureButtonCross_pressed() -> void:
	player.deactivate()
	chosenColor = "Kreuz"
	newSystemMessage("You chose " + getChosenColorEng() + "!")
	$RemoteCaller.callDelayed("disableWishControls", GlobalRules.systemBufferingAmountTextMsg + 1)

func _on_TextureButtonDiamond_pressed() -> void:
	player.deactivate()
	chosenColor = "Karo"
	newSystemMessage("You chose " + getChosenColorEng() + "!")
	$RemoteCaller.callDelayed("disableWishControls", GlobalRules.systemBufferingAmountTextMsg + 1)

func _on_TextureButtonSpade_pressed() -> void:
	player.deactivate()
	chosenColor = "Piek"
	newSystemMessage("You chose " + getChosenColorEng() + "!")
	$RemoteCaller.callDelayed("disableWishControls", GlobalRules.systemBufferingAmountTextMsg + 1)

func _on_PauseMenu_exited() -> void:
	if !is_recycling_deck:
		get_tree().paused = false
	else:
		$SystemMessage.process_mode = Node.PROCESS_MODE_ALWAYS
		$SysMsgRemoteCaller.process_mode = Node.PROCESS_MODE_ALWAYS
		$Gameobjects/CardpileButton/Cardpile.process_mode = Node.PROCESS_MODE_ALWAYS
		$Gameobjects/Discardpile.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_cardpile_button_pressed() -> void:
	if player == GlobalRules.getCurrentPlayer() and !GlobalRules.is_system_buffering:
		player.deactivate()
		if counter7 > 0:
			drawFor7s()
		else:
			player.setDrawnCard(carddeck.drawCardFromDeck())
			player.get_node("RemoteCaller").callDelayed("receiveCard", 0.7)
			player.get_node("RemoteCaller2").callDelayed("endTurn", 1)

func _on_discardpile_pressed() -> void:
	if GlobalRules.getCurrentPlayer() == player:
		var card = player.getSelectedCard()
		if card:
			if chosenColor == "" or chosenColor == card.getColor():
				if player.hasToDraw():
					if card.getType() == "7":
						player.resetSelectedCard()
						player.removeCard(card)
						card.scale = Vector2(0.5, 0.5)
						$Gameobjects/Discardpile.addCard(card)
						if card.getType() == "7":
							counter7 += 1
				else:
					var canPlay: bool = false
						
					if chosenColor == "" and ($Gameobjects/Discardpile.getTopcard() == null or card.getType() == "B" or ($Gameobjects/Discardpile.getTopcard().getType() == card.getType() or $Gameobjects/Discardpile.getTopcard().getColor() == card.getColor())):
						canPlay = true
					if chosenColor == card.getColor() and card.getType() != "B": 
						canPlay = true
					if canPlay:
						chosenColor = ""
						player.deactivate()
						player.resetSelectedCard()
						player.removeCard(card)
						card.scale = Vector2(0.5, 0.5)
						$Gameobjects/Discardpile.addCard(card)
						if card.getType() == "7":
							counter7 += 1
						if card.getType() == "8":
							last_card_8 = true
						if card.getType() == "B":
							last_card_B = true
							enableWishControls()
							newSystemMessage("Choose a color")
						else:
							player.deactivate()
							$RemoteCaller.callDelayed("nextPlayer", 0.7)

func _on_no_cards_left(node) -> void:
	var wonScene: Node = load("res://Scenes/Menus/WonGame/won_game_menu.tscn").instantiate()
	wonScene.setWinnerName(node.getIdentifier())
	
	get_tree().paused = true
	add_child(wonScene)

func _on_playCard(trigger: Node, card: Node) -> void:
	print(trigger.getIdentifier() + " : " + card.name)
	$Gameobjects/Discardpile.addCard(card)
	last_card_B = false
	chosenColor = ""
	trigger.playCard(card)
	if card.getType() == "7":
		counter7 += 1
	if card.getType() == "8":
		last_card_8 = true
	if card.getType() == "B":
		last_card_B = true
		if trigger == player:
			enableWishControls()
		else:
			trigger.startLoadCogAnim(0.75)
			chosenColor = trigger.getColorWish()
			$RemoteCaller.callDelayed("npcChooseColor", 1)
	else:
		trigger.resetTurnProperties()
		$RemoteCaller.callDelayed("nextPlayer", 1.5)

func _on_player_mau_mau_end_turn() -> void:
	nextPlayer()

func _on_cardpile_empty_deck() -> void:
	is_recycling_deck = true
	$SystemMessage.process_mode = Node.PROCESS_MODE_ALWAYS
	$SysMsgRemoteCaller.process_mode = Node.PROCESS_MODE_ALWAYS
	$Gameobjects/CardpileButton/Cardpile.process_mode = Node.PROCESS_MODE_ALWAYS
	$Gameobjects/Discardpile.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	newSystemMessage("Recycling Discardpile...")
	$PausedRemoteCaller.callDelayed("startRecycling", 1)

func startRecycling() -> void:
	$Gameobjects/CardpileButton/Cardpile.recycleDeck($Gameobjects/Discardpile.getCardsForRecycling())

func _on_cardpile_recycling_finished() -> void:
	if GlobalRules.getCurrentPlayer().getDrawAmount() > 0:
		refreshDrawText()
	else:
		if GlobalRules.getCurrentPlayer() == player:
			newSystemMessage("Your turn!")
		else:
			if GlobalRules.getCurrentPlayer().getIdentifier().ends_with("s"):
				newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + "' turn!")
			else:
				newSystemMessage(GlobalRules.getCurrentPlayer().getIdentifier() + "s turn!")
	$PausedRemoteCaller.callDelayed("recyclingFinished", 1.05)

func recyclingFinished() -> void:
	$SystemMessage.process_mode = Node.PROCESS_MODE_INHERIT
	$SysMsgRemoteCaller.process_mode = Node.PROCESS_MODE_INHERIT
	$Gameobjects/CardpileButton/Cardpile.process_mode = Node.PROCESS_MODE_INHERIT
	$Gameobjects/Discardpile.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	is_recycling_deck = false

func _on_player_mau_mau_menu_pressed() -> void:
	get_tree().paused = true
	add_child(load("res://Scenes/Menus/Pause/pause_menu.tscn").instantiate())
