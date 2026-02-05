extends StaticBody2D

# --- CONFIGURACIÓN ---
@export var health: int = 2
@export var bullet_scene: PackedScene 
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 250.0 

# --- REFERENCIAS ---
# Usamos nombres genéricos y comprobamos en el _ready
var muzzle = null
var shoot_timer = null
var detection_area = null

var target: Node2D = null 

func _ready():
	add_to_group("enemigos")
	
	# Buscamos los nodos manualmente para evitar errores de "Node not found"
	muzzle = get_node_or_null("Muzzle")
	shoot_timer = get_node_or_null("ShootTimer")
	detection_area = get_node_or_null("DetectionArea")
	
	# Verificación de seguridad
	if not shoot_timer:
		print_rich("[color=red][b]ERROR:[/b][/color] No encuentro el nodo 'ShootTimer'. Revisa el nombre en el árbol.")
	else:
		shoot_timer.wait_time = fire_rate
		if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
			shoot_timer.timeout.connect(_on_shoot_timer_timeout)
			
	if not detection_area:
		print_rich("[color=red][b]ERROR:[/b][/color] No encuentro el 'DetectionArea'.")
	else:
		# Conectamos las señales por código para asegurar que funcionen
		if not detection_area.body_entered.is_connected(_on_body_entered):
			detection_area.body_entered.connect(_on_body_entered)
		if not detection_area.body_exited.is_connected(_on_body_exited):
			detection_area.body_exited.connect(_on_body_exited)

func _process(_delta):
	if is_instance_valid(target):
		look_at(target.global_position)
		rotation += PI/2 

func _on_body_entered(body):
	if body.is_in_group("jugador"):
		target = body
		if shoot_timer:
			shoot_timer.start()
		print("SISTEMA: Objetivo detectado -> ", body.name)

func _on_body_exited(body):
	if body == target:
		target = null
		if shoot_timer:
			shoot_timer.stop()
		print("SISTEMA: Objetivo fuera de alcance.")

func _on_shoot_timer_timeout():
	if is_instance_valid(target):
		shoot()

func shoot():
	if bullet_scene and muzzle:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = muzzle.global_position
		var dir = (target.global_position - muzzle.global_position).normalized()
		
		if "direction" in bullet: bullet.direction = dir
		if "speed" in bullet: bullet.speed = bullet_speed
		if "shooter_group" in bullet: bullet.shooter_group = "balas_enemigas"
		
		bullet.rotation = dir.angle() + PI/2
		bullet.add_to_group("balas_enemigas")
	else:
		print("AVISO: No se puede disparar (falta Muzzle o Bala)")

func recibir_daño():
	health -= 1
	var tween = create_tween()
	modulate = Color.RED
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
