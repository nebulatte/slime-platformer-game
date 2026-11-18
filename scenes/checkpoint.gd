extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var activated: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play("red")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if activated:
		return
	if body is CharacterBody2D:
		activated = true
		sprite.play("green")
		
