extends CharacterBody2D

# --- CONFIGURACIÓN DEL TANQUE ---
# Velocidad de avance y rotación del chasis
@export var speed: float = 150.0 
@export var rotation_speed: float = 1.5 
# Suavidad del giro de la torreta
@export var turret_speed: float = 10.0

# --- CONFIGURACIÓN DE COMBATE ---
# Arrastra aquí el archivo bullet.tscn desde el Inspector
@export var bullet_scene: PackedScene 

# IMPORTANTE: el cañón debe llamarse "Turret" en la escena de Godot
@onready var turret = $Turret
# Se añade un nodo 'Marker2D' como hijo de la punta del cañón, donde nacerá la bala.
# esto evita que la bala explote antes de salir
@onready var muzzle = $Turret/Muzzle 

func _ready():
	add_to_group("jugador")

func _physics_process(delta: float):
	# 1. MOVIMIENTO DEL CHASIS
	# Usamos los nombres de las acciones definidas en Project -> Project Settings -> Input Map
	var rotation_direction = Input.get_axis("izquierda", "derecha")
	var move_direction = Input.get_axis("retroceder", "avanzar")

	# Aplicamos la rotación al chasis
	rotation += rotation_direction * rotation_speed * delta
	
	# Calculamos la velocidad basada en la rotación actual del tanque
	# Vector2.UP (0, -1) apunta hacia adelante en la mayoría de los sprites
	velocity = Vector2.UP.rotated(rotation) * move_direction * speed

	# 2. MOVIMIENTO DE LA TORRETA (Apuntar al ratón)
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = (mouse_pos - global_position).angle()
	
	# Compensación de 90 grados (PI/2) para alinear el sprite frontal con el ratón
	var final_angle = angle_to_mouse + PI/2
	
	# Rotación suavizada de la torreta
	turret.global_rotation = lerp_angle(turret.global_rotation, final_angle, turret_speed * delta)

	# 3. CONTROL DE DISPARO
	# "disparar" debe estar configurado en el Input Map (Ej: Barra espaciadora o Click Izquierdo)
	if Input.is_action_just_pressed("disparar"):
		shoot()

	# 4. EJECUTAR MOVIMIENTO Y COLISIONES
	# Esta función utiliza la variable interna 'velocity' para desplazar el cuerpo
	move_and_slide()

func shoot():
	# Verificamos que la escena de la bala esté cargada en el Inspector para evitar cierres inesperados
	if bullet_scene:
		# Creamos una instancia del proyectil
		var bullet = bullet_scene.instantiate()
		
		# La añadimos al nodo padre del tanque (el nivel) para que la bala no se mueva con el tanque
		get_parent().add_child(bullet)
		
		# Posicionamos la bala en el origen del tanque
		bullet.global_position = global_position
		
		# Calculamos la dirección de disparo basándonos en la orientación actual de la torreta
		var fire_direction = Vector2.UP.rotated(turret.global_rotation)
		
		# Pasamos los datos necesarios al script de la bala (bullet.gd)
		bullet.direction = fire_direction
		bullet.rotation = turret.global_rotation
	else:
		# Mensaje de depuración en caso de olvido en el Inspector
		print("ERROR: No has asignado la 'bullet_scene' en el Inspector del nodo player_tank")
