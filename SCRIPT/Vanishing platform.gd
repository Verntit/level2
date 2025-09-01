extends StaticBody2D

@onready var timer = $VanishingTimer
@onready var collision_shape_2d = $CollisionShape2D


func _on_trigger_area_body_entered(body):
	if body.is_in_group("player"):
		timer.start()
	

func _on_vanishing_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.4) 
	collision_shape_2d.position = Vector2(-1000000, 200000)
