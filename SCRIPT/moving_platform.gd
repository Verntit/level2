extends AnimatableBody2D

@export var move_speed: float = 20  # Units per second
@onready var path_follow: PathFollow2D = get_parent()
 
func _physics_process(delta: float) -> void:
	# Move along the path
	path_follow.progress += move_speed * delta
	
	# Update platform position to match PathFollow2D
	global_position = path_follow.global_position
	
	# Reverse direction at path ends (optional)
	if path_follow.progress_ratio >= 1.0 or path_follow.progress_ratio <= 0.0:
		move_speed *= -1
