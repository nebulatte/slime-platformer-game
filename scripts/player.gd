extends CharacterBody2D

enum State { GROUND, AIR }
var state: State = State.GROUND

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const SLOW_WALK_SPEED = 0.5
const MAX_JUMPS = 2
const PUSH_FORCE = 200

var jumps_remaining: int = MAX_JUMPS


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $CoyoteTimer

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	timer.timeout.connect(_on_coyote_timeout)

func _physics_process(delta: float) -> void:
	# gravity applies in every state
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	sprite.speed_scale = 1
	
	var current_speed = Input.get_axis("left", "right") * SPEED
	if Input.is_action_pressed("walk"):
		sprite.speed_scale = 0.5
		current_speed *= SLOW_WALK_SPEED
	velocity.x = current_speed

	match state:
		State.GROUND:
			_ground_state(current_speed)
		State.AIR:
			_air_state()

	move_and_slide()
	_push_objects()
	

func _ground_state(dir: float) -> void:
	jumps_remaining = MAX_JUMPS
	# walked off a ledge (or spawned in the air): switch to AIR and reduces usable jumps to 1
	if not is_on_floor():
		state = State.AIR
		timer.start()
		sprite.play("fall")
		return

	if dir == 0:
		sprite.play("idle")  # swap in your run animation here
	else:
		sprite.flip_h = dir < 0
		sprite.play("walk")

	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		_jump()

func _air_state() -> void:
	# velocity.y >= 0 avoids "landing" on the first frame of a jump
	if is_on_floor() and velocity.y >= 0:
		state = State.GROUND
		timer.stop()
		return
		
	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		_jump()

func _on_animation_finished() -> void:
	if sprite.animation == "jump_charge" and state == State.AIR:
		sprite.play("fall")
		
func _jump() -> void:
	velocity.y = JUMP_VELOCITY      # launches immediately
	state = State.AIR
	timer.stop()
	sprite.play("jump_charge")      # visual only
	jumps_remaining -= 1
	
func _on_coyote_timeout() -> void:
	jumps_remaining = mini(jumps_remaining, MAX_JUMPS - 1)
	
func _push_objects() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var push_dir := Vector2(-collision.get_normal().x, 0)
			collider.apply_central_impulse(push_dir * PUSH_FORCE)
