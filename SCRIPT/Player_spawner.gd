extends Node2D
#getting player 
var player_scene = preload("res://scene/player.tscn")
var player = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if player == null:
		var new_obj = player_scene.instantiate()
		new_obj.position = position
		get_parent().add_child(new_obj)
		player = new_obj

