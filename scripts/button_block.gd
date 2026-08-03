extends Block
class_name ButtonBlock

enum VisualState {
	FRONT,
	LEFT,
	RIGHT,
	EXTENDED
}

var visual_state: VisualState = VisualState.FRONT

@onready var button_animation: AnimatedSprite2D = $ButtonAnimation as AnimatedSprite2D
@onready var sprite: Sprite2D = $Sprite2D as Sprite2D

func _ready() -> void:
	super._ready()

func on_tower_updated(new_index: int) -> void:
	print(block_index)
	if new_index > block_index:
		if button_animation:
			match visual_state:
				VisualState.FRONT:
					button_animation.visible = true
					sprite.visible = false
					button_animation.play("turn_left_270")
					button_animation.animation_finished.connect(
						func():
							visual_state = VisualState.LEFT
							sprite.texture = load("res://assets/buttonblock/frames/left.tres")
							sprite.visible = true
							button_animation.visible = false
							Events.all_animation_finished.emit()
					)
				VisualState.LEFT:
					button_animation.visible = true
					sprite.visible = false
					button_animation.play("turn_right")
					button_animation.animation_finished.connect(
						func():
							visual_state = VisualState.RIGHT
							sprite.texture = load("res://assets/buttonblock/frames/right.tres")
							
							sprite.visible = true
							button_animation.visible = false
							Events.all_animation_finished.emit()
					)
				VisualState.RIGHT:
					sprite.texture = load("res://assets/buttonblock/frames/stage2.tres")
					if tower_manager != null and block_index >= 0:
						tower_manager.notify_block_height_changed(block_index)
				_:
					print("Button Oopsy")
				
	if new_index == block_index:
		Events.all_animation_finished.emit()
			
