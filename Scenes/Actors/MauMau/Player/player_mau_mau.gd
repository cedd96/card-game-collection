extends Node2D

# Save Position (x-axis) for each card in array alternating with pos and neg coordinates X-Diff between Cards = 59

var cardsize: Vector2 = Vector2(84, 151.2)
var cardscale: Vector2 = Vector2(0.35, 0.35)

var is_player_active: bool = false

# -944 (LEFT MAX) | 860 (RIGHT MAX) |944 + 860|
const cardPositionsXMin: float = -944
const cardPositionsXMax: float = 860
const cardPositionsXDiff: float = 59
var cardPositionsX: Array = [
	-59,
	0,
	-118,
	59,
	-177,
	118,
	-236,
	177,
	-295,
	236,
	-354,
	295,
	-413,
	354,
	-472,
	413,
	-531,
	472,
	-590,
	531,
	-649,
	590,
	-708,
	649,
	-767,
	708,
	-826,
	767,
	-885,
	826,
	-944
]

var cards: Array
var selectedCard: Node = null

var drawAmount: int = 0
var cardsToDraw: int = 0
var drawnCard: Node = null

var needs_to_draw: bool = false
var forcedDrawAmount: int = 0

signal no_cards_left(node)
signal end_turn()
signal menu_pressed()

func getIdentifier() -> String:
	return "You"

func startTurn(counter7: int, _last_card_B: bool, _chosenColor: String, _topcard: Node = null) -> void:
	is_player_active = true
	cardsToDraw = counter7 * 2
	$PlayerUITextureButtonMenu.grab_focus()
	for el in $CardControl.get_children():
		el.disabled = false

func endTurn() -> void:
	is_player_active = false
	$PlayerUITextureButtonMenu.grab_focus()
	selectedCard = null
	for el in $CardControl.get_children():
		el.disabled = true
		el.unselect()
		if el.getState() == 0:
			el.shrinkCard()
	emit_signal("end_turn")
	
func hasToDraw() -> bool:
	return needs_to_draw

func needsToDraw() -> void:
	needs_to_draw = true

func noNeedToDraw() -> void:
	needs_to_draw = false

func setDrawnCard(card: Node) -> void:
	drawnCard = card

func setDrawAmount(amount: int) -> void:
	drawAmount = amount
	
func getDrawAmount() -> int:
	return drawAmount

func getCardCount() -> int:
	return cards.size()

func receiveCard(card: Node = drawnCard) -> void:
	print("drawnCard: " + str(drawnCard))
	if !$CardCountLabel.visible:
		$CardCountLabel.visible = true
	var cardBtn: Node = load("res://Scenes/Games/Utility/CardButton/card_button.tscn").instantiate()
	cardBtn.position.x = cardPositionsX[$CardControl.get_children().size()]
	cardBtn.initialize(self)
	cardBtn.addCard(card)
	card.scale = cardscale
	$CardControl.add_child(cardBtn)
	if card not in cards:
		cards.append(card)
	$CardCountLabel.text = str(getCardCount())

func removeCard(card: Node) -> void:
	cards.erase(card)
	for el in $CardControl.get_children():
		$CardControl.remove_child(el)
		el.deleteFrom(self)
	$CardCountLabel.text = str(0)
	if getCardCount() > 0:
		for entry in cards:
			self.receiveCard(entry)
	else:
		emit_signal("no_cards_left", self)
		
func getHandcards() -> Array:
	return cards
	
func getSelectedCard() -> Node:
	return selectedCard

func resetSelectedCard() -> void:
	selectedCard = null

func isActive() -> bool:
	return is_player_active

func activate() -> void:
	is_player_active = true

func deactivate() -> void:
	is_player_active = false

func on_new_selected_card(card: Node) -> void:
	if selectedCard != card:
		if selectedCard:
			selectedCard.get_parent().unselect()
		selectedCard = card
	else:
		selectedCard = null


func _on_player_ui_texture_button_menu_pressed() -> void:
	emit_signal("menu_pressed")
