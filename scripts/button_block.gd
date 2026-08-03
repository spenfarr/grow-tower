extends Block
class_name ButtonBlock

enum VisualState {
	FRONT,
	LEFT,
	RIGHT,
	EXTENDED
}

var visual_state: VisualState = VisualState.FRONT

func _ready() -> void:
	super._ready()

func on_tower_updated(new_index: int) -> void:
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
					visual_state = VisualState.EXTENDED
					sprite.offset = Vector2(-50,0)
					if tower_manager != null and block_index >= 0:
						tower_manager.notify_block_height_changed(block_index)
					Events.all_animation_finished.emit()
				_:
					print("Button Oopsy")
					Events.all_animation_finished.emit()
				
	if new_index == block_index:
		Events.all_animation_finished.emit()
			
