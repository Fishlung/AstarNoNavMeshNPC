extends CharacterBody3D
class_name RoamingMonster

# ================== SETTINGS ==================
@export_group("Settings")
@export var max_chase_distance := 50.0

@export var turn_speed := 6.0

@export var acceleration := 8.0
@export var deceleration := 10.0

@export var chase_strafe_strength := 0.2   # How much does it move side to side when chasing?
@export var chase_strafe_change_time := 1.2

@export var speed := 4.6
@export var gravity := 20.0

@export var follow_distance := 1.5

@export var wander_min_time := 2.0
@export var wander_max_time := 5.0

# ================== NODE REFERENCES ==================

@export_group("Node References")
@export var front_ray: RayCast3D
@export var left_ray: RayCast3D
@export var right_ray: RayCast3D
@export var line_of_sight: RayCast3D
@export var astar_map: Node

# ================== STATES ==================

enum State {
	IDLE,
	CHASE, 
}

var state: State = State.IDLE
var target: Node3D
var target_closest_node: NavigationNode
var current_goal: Node3D
var goal_index: int = 0
var target_path: Array
var current_speed := 0.0
var strafe_dir := 0.0
var strafe_timer := 0.0

# ================== WANDER ==================

var wander_dir: Vector3 = Vector3.ZERO
var wander_time := 0.0
var idle_timer: float = 0

# ================== READY ==================

func _ready():
	randomize()
	set_target(get_tree().get_first_node_in_group("Players"))
	_reset_strafe()

func _reset_strafe():
	strafe_timer = randf_range(0.6, chase_strafe_change_time)
	strafe_dir = randf_range(-1.0, 1.0)

func _update_speed(target_speed: float, delta: float):
	if current_speed < target_speed:
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, target_speed, deceleration * delta)

# ================== Process ==================
func _physics_process(delta):
	_apply_gravity(delta)

	match state:
		State.IDLE:
			_process_idle(delta)
		State.CHASE:
			_process_chase(delta)

	move_and_slide()

# ================== STATE LOGIC ==================

func _process_idle(delta):
	idle_timer += delta
	if idle_timer >= 5:
		state = State.CHASE

func _process_chase(delta):
	if !target:
		idle_timer = 10
		state = State.IDLE
		return
	move_to_target(delta)

# ================== AUXILLARY FUNCTIONS==================

func move_to_target(delta):
	calculate_target_path()
	
	var to_goal = current_goal.global_position - global_position
	to_goal.y = 0

	var distance = to_goal.length()
	
	# --------- OPTIMIZED DISTANCE CONTROL ---------
	if distance <= 1: # Consider the goal reached if you get close enough
		goal_index += 1
		if target_path.size() > goal_index:
			current_goal = instance_from_id(target_path[goal_index])

	var dir = to_goal.normalized()

	# --------- STRAFE LOGIC ---------
	strafe_timer -= delta
	if strafe_timer <= 0:
		_reset_strafe()

	var right = Vector3(dir.z, 0, -dir.x)
	dir += right * strafe_dir * chase_strafe_strength
	dir = dir.normalized()

	# --------- SPEED ---------
	var target_speed = speed
	if distance < follow_distance && (
			goal_index >= target_path.size() - 1  # Ensures NPC actually reaches current goal
			|| current_goal == target): # But slow down around the targeted player
		target_speed = 0.0

	# --------- OBSTACLE AVOIDANCE ---------
	
	if _is_path_blocked():
		target_speed *= 1.6 # Try to push through blockages
		dir = _avoid_direction(dir)
	
	
	_update_speed(target_speed, delta)

	velocity.x = dir.x * current_speed
	velocity.z = dir.z * current_speed

	_smooth_look(dir, delta)

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

func _pick_new_wander(_force := false):
	wander_time = randf_range(wander_min_time, wander_max_time)

	var dir = Vector3(
		randf_range(-1.0, 1.0),
		0,
		randf_range(-1.0, 1.0)
	).normalized()

	wander_dir = dir

func _is_path_blocked() -> bool:
	return front_ray.is_colliding()

# This entire method is the reason I'm abandoning this NPC
# I've tried for hours to get it to not get stuck in corners and failed miserably
# Maybe I'm just bad at this but nothing I do seems to work
# To whoever tries to improve this, I wish you the best of luck o7
func _avoid_direction(_current_dir: Vector3) -> Vector3:
	if !left_ray.is_colliding():
		return -transform.basis.x
	if !right_ray.is_colliding():
		return transform.basis.x
	
	if (right_ray.get_collision_point().distance_to(current_goal.global_position) <
		left_ray.get_collision_point().distance_to(current_goal.global_position)):
		return transform.basis.x
	else:
		return -transform.basis.x

func _smooth_look(dir: Vector3, delta: float):
	if dir.length() < 0.01:
		return
	var target_yaw = atan2(dir.x, dir.z)
	var speed_mod = clamp(Vector3(velocity.x, 0, velocity.z).length() / speed, 0.3, 1.0)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * speed_mod * delta)

func calculate_target_path():
	if !astar_map:
		current_goal = target
		return
	
	# Make the goal the target if the target is within view
	line_of_sight.look_at(target.global_position)
	line_of_sight.force_raycast_update()
	if line_of_sight.get_collider() == target:
		current_goal = target
	elif current_goal == target:
		# Clear the current goal if target leaves sightline
		target_closest_node = null
		current_goal = null 
	
	# Create a new goal if you don't have one
	if !current_goal:
		current_goal = instance_from_id(astar_map.astar.get_closest_point(self.global_position))
	
	# Only update path if it needs to be updated
	var new_target_closest = instance_from_id(astar_map.astar.get_closest_point(target.global_position))
	if new_target_closest == target_closest_node:
		return
	else:
		target_closest_node = new_target_closest
	
	if !(current_goal is NavigationNode):
		return
	
	# Update the path
	target_path = astar_map.astar.get_id_path(current_goal.get_instance_id(), target_closest_node.get_instance_id())
		
	if target_path.size() <= 0:
		return
	
	# Find the index of whatever the current goal is
	var current_goal_index = target_path.find(current_goal.get_instance_id())
	if current_goal_index > 0:
		goal_index = current_goal_index
	else: 
		current_goal = instance_from_id(target_path[0])
		goal_index = 0
	
	# Start heading towards the next goal if you're already on your way
	if goal_index >= target_path.size() - 1:
		return
	var next_goal = instance_from_id(target_path[goal_index + 1]).global_position
	if current_goal.global_position == next_goal && goal_index < target_path.size() - 2:
		goal_index += 1
		current_goal = instance_from_id(target_path[goal_index])
		next_goal = instance_from_id(target_path[goal_index + 1]).global_position
	
	if (current_goal.global_position.distance_to(next_goal) > self.global_position.distance_to(next_goal)):
			goal_index += 1
			current_goal = instance_from_id(target_path[goal_index])

# ================== EXTERNAL CALLS ==================

func set_target(node: Node3D):
	target = node

