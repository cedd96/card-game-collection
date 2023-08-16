extends Node

var root: Node = null

# This script controls and checks the rules of the game. Also handles temporary values.

var is_system_buffering: bool = false
var is_npc_buffering: bool = false
var is_trading: bool = false

var prevMenu: NodePath = ""

# Amounts in Seconds
var systemBufferingAmountStartRound: float = 5
var systemBufferingAmountDealCards: float = 0.15
var systemBufferingAmountShufflingCards: float = 1.5
var systemBufferingAmountDefault: float = 1
var systemBufferingAmountTextMsg: float = 1.05
var tradeDelay: float = 0.2
var npcBufferAmount: float = 0.3
var npcBufferingAmount: float = 1

var drawBuffer: float = 0.65

var carddeck: Node = null

var players: Array
var participatingPlayers: Array
var currentPlayer: Object = null

var selectedGame: String = ""
var numberOfNPCs: int = 0

var usedIdentifiers: Array

func setRoot(rtNode: Node) -> void:
	root = rtNode

func getRoot() -> Node:
	return root

func reset() -> void:
	is_system_buffering = false
	is_npc_buffering = false
	is_trading = false
	players.clear()
	participatingPlayers.clear()
	currentPlayer = null
	usedIdentifiers.clear()

func getDeck() -> Node:
	return carddeck

func setDeck(deck: Node) -> void:
	carddeck = deck

func addPlayer(player: Node) -> void:
	players.append(player)

func getPlayers() -> Array:
	return players

func setCurrentPlayer(player: Object) -> void:
	currentPlayer = player

func getCurrentPlayer() -> Object:
	return currentPlayer

func getPlayerAtIndex(index: int) -> Object:
	return players[index]

func getNextPlayerAfter(player: Node) -> Node:
	if players.find(player) == players.size() - 1:
		return players[0]
	else:
		return players[players.find(player) + 1]

func getNextPlayer() -> Object: 
	if players.find(currentPlayer) == players.size() - 1:
		return players[0]
	else:
		return players[players.find(currentPlayer) + 1]

func getPlayerBefore(player: Node) -> Node:
	return players[players.find(player) - 1] 
