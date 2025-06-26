extends CanvasLayer


func _ready():
	add_to_group("death_screen")  # For backup search
	hide()

func show_death_screen():
	get_tree().paused = true
	show()
	# Make sure you have a "RespawnButton" node as a child of your overlay
	$Respawn.grab_focus()

func _on_respawn_pressed():
	get_tree().paused = false
	hide()
	
	# Three ways to find player, with fallbacks
	var player = get_node("/root/Player") as Node
	if !player:
		player = get_tree().get_first_node_in_group("player")
	
	if player and player.has_method("respawn"):
		player.respawn()
	else:
		print("Player respawn failed - reloading scene")
		get_tree().reload_current_scene()

