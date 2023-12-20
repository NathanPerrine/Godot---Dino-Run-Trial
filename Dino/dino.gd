extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1800

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	velocity.y += GRAVITY * delta
	
	if is_on_floor():
		$RunCol.disabled = false
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_SPEED
			$JumpSound.play()
		elif Input.is_action_pressed("ui_down"):
			$DinoSprite.play("duck")
			$RunCol.disabled = true
		else:
			$DinoSprite.play("run")
	else:
		$DinoSprite.play("jump")
	
	move_and_slide()
