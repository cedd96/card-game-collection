extends Button

var focusMarkerArrow: Resource = load("res://Assets/Sprites/Utility/FocusMarkerArrow300x300.png")
var focusMarker: Sprite2D = null
var focusMarkerScale: float = 0.1

@export var labelText: String = ""

## Default Color ##
@export var defaultColorFont: Color = Settings.config.get_value("Colors", "textcolor")
@export var defaultColorBorder: Color = Settings.config.get_value("Colors", "textcolor")
@export var defaultColorCenter: Color = Settings.config.get_value("Colors", "backgroundcolor", Color(0, 0, 0, 0))

## Hovered Colors ##
var hoveredColorFont: Color = defaultColorFont.lightened(0.1)
var hoveredColorBorder: Color = defaultColorBorder.lightened(0.1)
var hoveredColorCenter: Color = defaultColorCenter.lightened(0.1)

## Pressed Colors ##
var pressedColorFont: Color = defaultColorFont.lightened(0.2)
var pressedColorBorder: Color = defaultColorBorder.lightened(0.2)
var pressedColorCenter: Color = defaultColorCenter.lightened(0.2)

func _ready() -> void:
	setColors()
	$Label.text = labelText
	if self.disabled:
		self.disable()

func setColors() -> void:
	$Label.add_theme_color_override("font_color", defaultColorFont)
	$ColorRectBorder.color = defaultColorBorder
	$ColorRectCenter.color = defaultColorCenter

func _on_button_button_down() -> void:
	$Label.add_theme_color_override("font_color", pressedColorFont)
	$ColorRectBorder.color = pressedColorBorder
	$ColorRectCenter.color = pressedColorCenter

func _on_button_button_up() -> void:
	$Label.add_theme_color_override("font_color", defaultColorFont)
	$ColorRectBorder.color = defaultColorBorder
	$ColorRectCenter.color = defaultColorCenter
	
func _on_button_mouse_entered() -> void:
	$Label.add_theme_color_override("font_color", hoveredColorFont)
	$ColorRectBorder.color = hoveredColorBorder
	$ColorRectCenter.color = hoveredColorCenter

func _on_button_mouse_exited() -> void:
	if !has_focus():
		$Label.add_theme_color_override("font_color", defaultColorFont)
		$ColorRectBorder.color = defaultColorBorder
		$ColorRectCenter.color = defaultColorCenter

func enable() -> void:
	self.disabled = false
	$DisabledShadow.visible = false
	
func disable() -> void:
	self.disabled = true
	$DisabledShadow.visible = true

func _on_button_focus_entered() -> void:
	focusMarker = load("res://Scenes/Helper/FocusMarker/focus_marker.tscn").instantiate()
	focusMarker.changeColorTo(defaultColorFont)
	focusMarker.name = "focusMarker"
	focusMarker.position = Vector2(self.size.x + focusMarker.get_rect().size.x * focusMarkerScale, self.size.y / 2)
	self.add_child(focusMarker)
	$Label.add_theme_color_override("font_color", hoveredColorFont)
	$ColorRectBorder.color = hoveredColorBorder
	$ColorRectCenter.color = hoveredColorCenter
	
func _on_button_focus_exited() -> void:
	focusMarker.call_deferred("queue_free")
	if !is_hovered():
		$Label.add_theme_color_override("font_color", defaultColorFont)
		$ColorRectBorder.color = defaultColorBorder
		$ColorRectCenter.color = defaultColorCenter
