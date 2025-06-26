extends Area2D

var activated := false

func _ready():
	print("Player layer: ", collision_layer, " | Checkpoint mask: ", get_node("../Checkpoint").collision_mask)
	#1. Force enable all collisions
	collision_mask = 0x7FFFFFFF  # Mask ALL layers
	#2. Connect signal manually as last resort
	body_entered.connect(_on_body_entered)
	#3. Print collision shape status
	print("Checkpoint collision shape exists:", $CollisionShape2D.shape != null)

func _on_body_entered(body):
	print("=== ANY PHYSICS BODY ENTERED ===")
	print("Name:", body.name)
	print("Class:", body.get_class())
	print("Groups:", body.get_groups())
	print("Position:", body.global_position)
	if body.is_in_group("player") and not activated:
		activated = true
		body.set_checkpoint(global_position)
	
	# Visual feedback (ensure you see something happen)
	modulate = Color.RED
	await get_tree().create_timer(0.5).timeout
	modulate = Color.WHITE

#var activated := false
	#egrgsefesgf
# Called when the node enters the scene tree for the first time.

#	body_entered.connect(_on_body_entered)


#Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


#func _on_body_entered(body):
#	if body.is_in_group("player") and not activated:
#		activated = true
#		body.set_checkpoint(global_position)
