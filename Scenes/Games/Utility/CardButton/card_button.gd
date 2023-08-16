extends Button

var card: Node = null

var is_hovered: bool = false
var is_selected: bool = false
var is_focused: bool = false

enum {
	EXPAND,
	SHRINK
}

var animationState: int = EXPAND

const SWAP_TIME: float = 0.0015625
const EXPAND_TIME: float = 0.0015625
const SHRINK_TIME: float = 0.003125

var oldPos: Vector2
var oldScale: Vector2
var tempPos: Vector2
var tempScale: Vector2 = Vector2(1.5, 1.5)

var newPos: Vector2

signal new_selected_card(card)

func _ready() -> void:
	pass
	
func initialize(parent: Node = null) -> void:
	if parent != null:
		self.connect("new_selected_card", Callable(parent, "on_new_selected_card"))
	oldPos = position
	oldScale = scale
	tempPos = Vector2(oldPos.x - size.x / 2, -80)
	
func deleteFrom(parent: Node) -> void:
	self.disconnect("new_selected_card", Callable(parent, "on_new_selected_card"))
	remove_child(card)
	call_deferred("queue_free")
	
func addCard(newCard: Node) -> void:
	card = newCard 
	add_child(card)

func getCard() -> Node:
	return card

func getState() -> int:
	return animationState

func select() -> void:
	is_selected = true
	z_index = 80
	expandCard()
	card.select()

func unselect() -> void:
	is_selected = false
	if !is_hovered:
		shrinkCard()
	card.unselect()

func expandCard() -> void:
	animationState = EXPAND
	$AnimationClock.start(EXPAND_TIME)

func shrinkCard() -> void:
	animationState = SHRINK
	$AnimationClock.start(SHRINK_TIME)

func _on_pressed() -> void:
	if get_parent().get_parent().isActive():
		if is_selected:
			unselect()
		else:
			emit_signal("new_selected_card", card)
			select()

func _on_focus_entered() -> void:
	is_focused = true
	z_index = 90
	expandCard()

func _on_focus_exited() -> void:
	is_focused = false
	if !is_selected and !is_hovered:
		shrinkCard()

func _on_mouse_entered() -> void:
	is_hovered = true
	z_index = 100
	expandCard()

func _on_mouse_exited() -> void:
	is_hovered = false
	if !is_selected:
		shrinkCard()
	else:
		z_index = 80

func _on_animation_clock_timeout() -> void:
	if animationState == EXPAND:
		if !isMatching(position, tempPos) or !isMatching(scale, tempScale):
			scale += Vector2(abs(tempScale.x - oldScale.x) / 40, abs(tempScale.y - oldScale.y) / 40)
			position -= Vector2(abs(tempPos.x - oldPos.x) / 40, abs(tempPos.y - oldPos.y) / 40)
		else:
			$AnimationClock.stop()
	else:
		if !isMatching(position, oldPos) or !isMatching(scale, oldScale):
			scale -= Vector2(abs(tempScale.x - oldScale.x) / 40, abs(tempScale.y - oldScale.y) / 40)
			position += Vector2(abs(tempPos.x - oldPos.x) / 40, abs(tempPos.y - oldPos.y) / 40)
		else:
			z_index = 0
			$AnimationClock.stop()

func isMatching(val1: Vector2, val2: Vector2) -> bool:
	if abs(val1 - val2) < Vector2(0.0005, 0.0005):
		return true
	return false
