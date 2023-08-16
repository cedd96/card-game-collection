extends Node2D

var colors: Array = ["Herz", "Karo", "Kreuz", "Piek"]
var valuesAndTypes32: Dictionary = {
	"7": 7, 
	"8": 8, 
	"9": 9, 
	"10": 10, 
	"B": 10, 
	"D": 10, 
	"K": 10, 
	"A": 11
	}

var valuesAndTypes52: Dictionary = {
	"2": 2,
	"3": 3,
	"4": 4,
	"5": 5,
	"6": 6,
	"7": 7, 
	"8": 8, 
	"9": 9, 
	"10": 10, 
	"B": 10, 
	"D": 10, 
	"K": 10, 
	"A": 11
	}

var cards: Array

signal empty_deck()
signal recycling_finished()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GlobalRules.selectedGame != "Schwimmen (31)":
		if GlobalRules.numberOfNPCs > 2:
			generateCards52()
		else:
			generateCards32()
	else:
		generateCards32()

func generateCards32() -> void:
	var newCard: Node = null
	
	for color in colors:
		for key in valuesAndTypes32.keys():
			newCard = load("res://Scenes/Games/Utility/Kartenstapel/Karten/karte2.tscn").instantiate()
			newCard.cardInitialize(color, key, valuesAndTypes32.get(key))
			cards.append(newCard)

func generateCards52() -> void:
	var newCard: Node = null
	
	for color in colors:
		for key in valuesAndTypes52.keys():
			newCard = load("res://Scenes/Games/Utility/Kartenstapel/Karten/karte2.tscn").instantiate()
			newCard.cardInitialize(color, key, valuesAndTypes52.get(key))
			cards.append(newCard)

func getCardFromDeck() -> Node:
	var card = cards[0]
	cards.remove_at(0)
	return card
	
func drawCardFromDeck() -> Node:
	$AnimationPlayer.play("Draw")
	GlobalRules.is_system_buffering = true
	$RemoteCaller.callDelayed("stopBuffer", 0.7)
	var card = cards[0]
	cards.remove_at(0)
	if cards.size() == 0:
		emit_signal("empty_deck")
	return card
	
func recycleDeck(newCards: Array) -> void:
	cards.append_array(newCards)
	shuffleCards()
	$RemoteCaller.callDelayed("recyclingFinished", GlobalRules.systemBufferingAmountShufflingCards + 1)
	
func recyclingFinished() -> void:
	emit_signal("recycling_finished")
	
func shuffleCards() -> void:
	$AnimationPlayer.play("Mischen")
	cards.shuffle()
	
func stopBuffer() -> void:
	GlobalRules.is_system_buffering = false
	
func addCardToDeck(card: Node) -> void:
	cards.append(card)
	
func addCardsToDeck(newCards: Array) -> void:
	cards.append_array(newCards)
