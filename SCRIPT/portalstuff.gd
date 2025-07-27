extends Area2D


@export_file("res://scene/the_base.tscn") var next_scene: String



func _on_body_entered(body):
	if body.name == "PLAYER":  # Replace "Player" with your player node's name
		get_tree().change_scene_to_file("res://scene/the_base.tscn")
	print("Something entered:", body.name)
