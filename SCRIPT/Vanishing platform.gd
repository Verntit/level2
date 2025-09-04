extends StaticBody2D

@onready var timer = $VanishingTimer
@onready var collision_shape_2d = $CollisionShape2D
@onready var reset_timer = $Reset_Timer

var original_modulate_a: float

func _ready():
	original_modulate_a = modulate.a

func _on_trigger_area_body_entered(body):
	if body.is_in_group("player") and timer.is_stopped(): 
		timer.start()
		reset_timer.start()
		
func _on_vanishing_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.4) 
	collision_shape_2d.set_deferred("disabled", true) 

func _on_reset_timer_timeout():
		# Reset the platform after 5 seconds
	collision_shape_2d.set_deferred("disabled", false) 
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", original_modulate_a, 0.4)
