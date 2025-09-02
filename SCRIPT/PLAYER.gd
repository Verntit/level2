extends CharacterBody2D
#fix that fall damage constant its not stopping, health regening when taking damage


#checkpoint stuff 
var last_checkpoint: Vector2 = Vector2(100, 100) # Default spawn position

@onready var regen_timer = $regen_timer
var health_regen_rate = 20  # How much health to regenerate per second
var health_regen_delay = 2  # How long to wait before regeneration starts (in seconds)
var can_regenerate = true  # Whether health regeneration is allowed
@onready var health_bar = $"../UI/HealthBar" # Path to the HealthBar
var max_health = 400

var is_regenerating = false 
var fall_damage_cooldown = false
var is_falling = false
var health = 400  # Initialize at max health

 #camera shake
@onready var camera = $Camera2D
var shake_intensity = 0.0
var shake_decay = 5.0  # How fast the shake stops

@onready var death_overlay = $"../GameOverOverlay"

const FALL_DAMAGE_THRESHOLD = 450  # Speed at which damage starts
const DAMAGE_MULTIPLIER =  10 #0.255  # Scale of damage taken
var last_fall_velocity = 0        # Store velocity before landing

const SPEED = 300.0
const JUMP_VELOCITY = -600

#dashing 
const DASH_SPEED = 1500.0
var dashing = false
var can_dash = true

#wall slides/jumps and double jumps 
@export var wall_jump_force = -400
@export var wall_slide_speed = 5000
var is_wall_sliding = false
var can_wall_jump = false
var double_jump_available = true 
var wall_jump_count = 0 

#coyote time
@export var coyote_time: float = 0.2
var was_on_floor: bool = false 
var can_coyote_jump: bool = false


#buffer jump
@export var jump_buffer_time: float = 0.1
var jumped_pressed:bool = false 
var jump_buffer_timer: Timer


func _process(delta):
	$DebugLabel.text = "FALL: %.1f/1500\n%s\nHP: %d/%d" % [
	abs(velocity.y),
 	"GROUND" if is_on_floor() else "WALL" if is_on_wall() else "AIR", 
	health,
	max_health
]
func _init():
	add_to_group("player")  # Registers before ANY collisions process
	print("Player initialized - Group added")

func _ready() -> void:
	print("Player layer: ", collision_layer, " | Checkpoint mask: ", get_node("../Checkpoint").collision_mask)
	# Force enable all collisions
	collision_layer = 0x7FFFFFFF
	print("Player collision shape exists:", $CollisionShape2D.shape != null)

	add_to_group("player")
	
	if not OS.is_debug_build():
		$DebugLabel.queue_free()
	
	jump_buffer_timer = Timer.new()
	jump_buffer_timer.one_shot = true
	jump_buffer_timer.timeout.connect(func(): jumped_pressed = false)
	add_child(jump_buffer_timer)
	#health regen
	regen_timer.wait_time = health_regen_delay
	regen_timer.one_shot = true
	health_bar.max_value = max_health
	health_bar.value = health
	
	
	# Changed from original:
	regen_timer.wait_time = health_regen_delay
	regen_timer.one_shot = true  # Changed to one-shot timer
	regen_timer.timeout.connect(_start_continuous_regen)
	
	
	camera.make_current()  # Ensures this camera is active



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
# New fall damage check 
	if not is_on_floor():
		last_fall_velocity = velocity.y
		is_falling = true
	elif is_falling:  # Just landed
		is_falling = false
		if last_fall_velocity > FALL_DAMAGE_THRESHOLD and not fall_damage_cooldown:
			apply_fall_damage(last_fall_velocity - FALL_DAMAGE_THRESHOLD)

# Keep your existing was_on_floor code after this
	was_on_floor = is_on_floor()
	
	# ... rest of your physics process ...
		
	if health <= 0:
		die()  # Replace with a respawn or death function
		health_bar.value = health
	
	handle_input(delta)
	handle_movement(delta)
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		if was_on_floor and velocity.y >= 0:
			can_coyote_jump = true 
			get_tree().create_timer(coyote_time).timeout.connect(func(): can_coyote_jump = false)
	else:
		if jumped_pressed:
			velocity.y = JUMP_VELOCITY
			jumped_pressed = false
			jump_buffer_timer.stop()
			
			
		
	if shake_intensity > 0 && !get_tree().paused:  # NEW: Check for pause
		camera.offset = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
		shake_intensity = max(shake_intensity - (shake_decay * delta), 0)
	elif camera.offset != Vector2.ZERO:  # NEW: More precise reset
		camera.offset = Vector2.ZERO

		
func apply_fall_damage(fall_speed):
	var damage = (fall_speed - FALL_DAMAGE_THRESHOLD) * DAMAGE_MULTIPLIER
	damage = max(1, damage)  # Ensure minimum 1 damage
	
	health -= damage
	print("Fall Damage! Speed: ", fall_speed, " Damage: ", damage)
	
	# Visual feedback
	shake_intensity = min(damage * 0.1, 10)
	health_bar.value = health
	
	# Cooldown with await (more reliable)
	fall_damage_cooldown = true
	await get_tree().create_timer(0.5).timeout
	fall_damage_cooldown = false
	
	# Reset regeneration
	_stop_regen()
	regen_timer.start(health_regen_delay)
	
	if health <= 0:
		die()

		
# Update health bar
	health_bar.value = health  # Update health bar value
func die():
	if health > 0:
		return

	print("Player died")
	# NEW: Death camera shake effect
	shake_intensity = 15.0  # Stronger shake for death
	shake_decay = 2.0  # Slower decay
	await get_tree().create_timer(0.5).timeout  # Let shake play briefly
	
	set_physics_process(false)
	visible = false
	
	# Death screen reference remains the same
	var death_screen = get_node("/root/GameOverOverlay") as CanvasLayer
	if !death_screen:
		death_screen = get_tree().get_first_node_in_group("death_screen")
		
	if death_screen:
		if death_screen.has_method("show_death_screen"):
			death_screen.show_death_screen()
		else:
			print("Death screen found but missing show_death_screen method")
			respawn()
			await get_tree().create_timer(2.0).timeout
	else:
		print("Death screen not found - respawning immediately")
		await get_tree().create_timer(1.0).timeout
		respawn()

func respawn():
	# NEW: Reset camera effects first
	shake_intensity = 0.0
	camera.offset = Vector2.ZERO
   
	# Original health reset
	health = max_health
	health_bar.value = health
	
	# Original position reset
	global_position = last_checkpoint
	
	# Original state resets
	velocity = Vector2.ZERO
	dashing = false
	can_dash = true
	is_falling = false
	fall_damage_cooldown = false
	is_wall_sliding = false
	can_wall_jump = false
	double_jump_available = true
	
	# Original enable code
	set_physics_process(true)
	visible = true
	
	# Original regeneration reset
	_stop_regen()
	regen_timer.start(health_regen_delay)


func handle_input(delta):
	# Handle Jump, double jump and wall jump
	if Input.is_action_just_pressed("JUMP"):
		if (is_on_floor() or can_coyote_jump): #or is_on_wall try to get it so coyote time works on wall 
			velocity.y = JUMP_VELOCITY
			double_jump_available = true 
			can_coyote_jump = false 
		elif can_wall_jump and wall_jump_count < 3:
			velocity.y = wall_jump_force
			wall_jump_count + 1 
			print(wall_jump_count)
		elif double_jump_available:
			velocity.y = JUMP_VELOCITY
			double_jump_available = false
		elif can_wall_jump:
			var push_off = 1 if Input.is_action_pressed("RIGHT") else -1
			velocity = Vector2(push_off * SPEED * 0.8, wall_jump_force)
		else:
			jumped_pressed = true 
			jump_buffer_timer.start(jump_buffer_time)
	# Handle releasing jump early for short-hop
	if Input.is_action_just_released("JUMP") and velocity.y < 0:
		velocity.y *= 0.6  # Reduce jump height if the button is released early
		
# In Player.gd input handling
	if Input.is_key_pressed(KEY_T) and OS.is_debug_build():
		last_checkpoint = get_global_mouse_position()


#test

#setting dash to start and end
	if Input.is_action_just_pressed("DASH") and can_dash:
		dashing = true
		can_dash = false
		$Dash_timer.start()
		$Dash_again_timer.start()
	if is_on_wall():
		velocity.x *= 0.5  # Reduce impact

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("LEFT", "RIGHT")
	if direction:
		if dashing:
			velocity.x = direction * DASH_SPEED
		else:
			velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	
#handles movement
func handle_movement(delta):
	if not is_on_floor():
		velocity.y += gravity * delta 
		handle_wall_slide(delta)
	else:
		is_wall_sliding = false
		can_wall_jump = false
		double_jump_available = true 



	move_and_slide()



func handle_wall_slide(delta):
	if is_on_wall()  and velocity.y > 0 and (Input.is_action_pressed("RIGHT") or Input.is_action_pressed("LEFT")):
		is_wall_sliding = true
		velocity.y = wall_slide_speed * delta 
		can_wall_jump = true
	else:
		is_wall_sliding = false 
		can_wall_jump = false 
		
		
		
#functions for dashing on and off 
func _on_dash_timer_timeout():
	dashing = false
func _on_dash_again_timer_timeout():
	can_dash = true 




func start_slow_motion():
	print("Starting slow motion")  # Debugging message
	Engine.time_scale = 0.1  # Slow down the game
	get_tree().paused = true  # Optional: Pause the game if you want to
	$SlowMotionTimer.start()  # Start the slow motion timer

func _on_slow_motion_timer_timeout():
	# Restore the game speed
	get_tree().paused = false  # Unpause the game if it was paused
	Engine.time_scale = 1.0  # Reset the time scale back to normal
	
func update_health_bar():
	health_bar.value = health  # Update the health bar with the current health

# Regenerate health function
func _start_continuous_regen():
	is_regenerating = true
	_regen_tick()

func _regen_tick():
	if not is_regenerating or health <= 0:
		return
		
	if health < max_health:
		health = min(health + health_regen_rate, max_health)
		health_bar.value = health
		get_tree().create_timer(1.0).timeout.connect(_regen_tick, CONNECT_ONE_SHOT)
	else:
		_stop_regen()

func _stop_regen():
	is_regenerating = false
	regen_timer.stop()

func set_checkpoint(position: Vector2):
	last_checkpoint = position
	
func _input(event):
	# For debug teleport when pressing T + clicking
	if OS.is_debug_build() and Input.is_key_pressed(KEY_T) and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			last_checkpoint = get_global_mouse_position()
			print("Debug Teleport: ", last_checkpoint)
		


