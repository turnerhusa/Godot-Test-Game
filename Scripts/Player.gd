extends KinematicBody2D

const MOTION_SPEED = 150.0

slave var slave_pos = Vector2()
slave var slave_motion = Vector2()
slave var slave_flip_v = false
slave var slave_weapon_rot = 0
slave var slave_weapon_smoke = false

var gunShotSprite = preload("res://Scenes/GunShot.tscn")

var health = 3

func _process(delta):
	get_node("HealthBar").value = health
	if (is_network_master()):
		
		get_node("Weapon").look_at(get_global_mouse_position())
		if (get_global_mouse_position().x < position.x ):
			get_node("Weapon").flip_v = true
			get_node("Weapon/WeaponSmoke").position.y = 2.82196
		else:
			get_node("Weapon").flip_v = false
			get_node("Weapon/WeaponSmoke").position.y = -2.82196
		
		rset("slave_flip_v", get_node("Weapon").flip_v)
		rset("slave_weapon_rot", get_node("Weapon").rotation)
	else:
		get_node("Weapon").flip_v = slave_flip_v
		get_node("Weapon").rotation = slave_weapon_rot
		get_node("Weapon/WeaponSmoke").emitting = slave_weapon_smoke
		if (slave_flip_v):
			get_node("Weapon/WeaponSmoke").position.y = 2.82196
		else:
			get_node("Weapon/WeaponSmoke").position.y = -2.82196

func _physics_process(delta):
	var motion = Vector2()
	
	if (is_network_master()):
		if (Input.is_action_pressed("move_left")):
			motion += Vector2(-1, 0)
		if (Input.is_action_pressed("move_right")):
			motion += Vector2(1, 0)
		if (Input.is_action_pressed("move_up")):
			motion += Vector2(0, -1)
		if (Input.is_action_pressed("move_down")):
			motion += Vector2(0, 1)
		
		if (Input.is_action_just_pressed("player_fire")):
			
			get_node("Weapon/GunShot").enabled = true
			if (get_node("Weapon/GunShot").is_colliding()):
				var collider = get_node("Weapon/GunShot").get_collider()
				var collider_point = get_node("Weapon/GunShot").get_collision_point()
				var collider_normal = get_node("Weapon/GunShot").get_collision_normal()
				var distance = sqrt(pow(collider_point.x - position.x,2)+pow(collider_point.y - position.y,2))
				
				rpc("display_gunShot", collider_point, distance, position)
				
				if (collider.is_in_group("EnemyCollider") and collider.has_method("takeDamage") ):
					collider.rpc("takeDamage",1)
				
				get_node("Weapon/WeaponSmoke").emitting = true
				rset("slave_weapon_smoke",true)
				get_node("Weapon/SmokeTimer").start()
		
		
		rset("slave_motion", motion)
		rset("slave_pos", position)
	else:
		position=slave_pos
		motion = slave_motion
		
	# FIXME: Use move_and_slide
	move_and_slide(motion*MOTION_SPEED)
	if (not is_network_master()):
		slave_pos = position # To avoid jitter


func set_player_name(new_name):
	get_node("PlayerName").set_text(new_name)
	randomize()
	get_node("PlayerSprite").set_modulate(Color(randf(),randf(),randf(), 1))

func _ready():
	set_process(true)
	get_node("Weapon/GunShot").add_exception(get_node("Collision"))
	slave_pos = position

sync func display_gunShot(collider_point, distance, position):
	var gss = gunShotSprite.instance()
	add_child(gss)
	gss.look_at(collider_point)
	remove_child(gss)
	get_node("../../Map").add_child(gss)
	gss.scale.x = (distance/5)
	gss.scale.y = .25
	gss.position = position

func _on_SmokeTimer_timeout():
	if (is_network_master()):
		get_node("Weapon/WeaponSmoke").emitting = false
		rset("slave_weapon_smoke",false)

sync func takeDamage(dmg):
	health = health - dmg
	print(health)

func getHealth():
	return health
