extends Node2D

@export var unitName: String = ""
@onready var nameLabel: Label = $CharacterName
@onready var health: Control = $HealthControl

var associatedCharacter: Object = null

func _ready() -> void:
	if unitName != "":
		changeUsername(unitName)
	associatedCharacter = get_parent()

func refreshHealth() -> void:
	if associatedCharacter != null:
		match associatedCharacter.getCurrentHealth():
			3:
				for el in health.get_children():
					el.visible = true
			2:
				for el in health.get_children():
					if "3" in el.name:
						el.visible = false
			1:
				for el in health.get_children():
					if "3" in el.name or "2" in el.name:
						el.visible = false
			0:
				for el in health.get_children():
					el.visible = false

func changeUsername(newUsername: String) -> void:
	nameLabel.text = newUsername
