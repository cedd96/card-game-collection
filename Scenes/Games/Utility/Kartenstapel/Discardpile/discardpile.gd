extends Button

var cards: Array

var newTopcard: Node = null
var oldTopcard: Node = null

func _ready() -> void:
	GlobalRules.carddeck = self

func addCard(card: Node) -> void:
	cards.append(card)
	newTopcard = card
	$CardFrame/AnimationBody.add_child(card)

func getCards() -> Array:
	return cards

func getTopcard() -> Node:
	return oldTopcard

func changeTopCards() -> void:
	GlobalRules.is_system_buffering = false
	if oldTopcard:
		$CardFrame/TopcardHolder.remove_child(oldTopcard)
	$CardFrame/AnimationBody.remove_child(newTopcard)
	$CardFrame/TopcardHolder.add_child(newTopcard)
	oldTopcard = newTopcard
	newTopcard = null

func getCardsForRecycling() -> Array:
	var tmpCards: Array = []
	for el in cards:
		if el != oldTopcard:
			tmpCards.append(el)
			cards.erase(el)
	return tmpCards

func _on_animation_body_child_entered_tree(_node: Node) -> void:
	$AnimationPlayer.play("NewTopCard")
	GlobalRules.is_system_buffering = true
