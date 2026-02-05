extends CharacterBody2D

# --- CONFIGURACIÓN DEL TANQUE ---
# '@export' importa datos desde el inspector de Godot
# Velocidad de avance y rotación del chasis
@export var speed: float = 150.0 
@export var rotation_speed: float = 1.5 
# Suavidad del giro de la torreta
@export var turret_speed: float = 10.0

# --- LÍMITES DEL MAPA ---
@export var map_limit_left: int = -216
@export var map_limit_top: int = -980
@export var map_limit_right: int = 1030
@export var map_limit_bottom: int = 980

# --- CONFIGURACIÓN DE COMBATE ---
@export var bullet_scene: PackedScene
@export var max_ammo: int = 10
@export var overheat_threshold: float = 100.0
@export var overheat_cool_speed: float = 20.0 # Velocidad de enfriamiento por segundo
@export var heat_per_shot: float = 25.0 # Calor generado por cada disparo
@export var ammo_regen_time: float = 1.5 # Segundos para recuperar una bala

# Variables de estado interno
var current_ammo: int = 10
var current_heat: float = 0.0
var is_overheated: bool = false
var health: int = 3
var regen_timer: float = 0.0 # Cronómetro interno para la recarga

# Referencia a la interfaz de usuario
# grupo para encontrar el HUD fácilmente en la escena
@onready var ui = get_tree().get_first_node_in_group("ui")

# Referencias a los nodos
# no se ejecutarán hasta que estén cargados '@onready'
# '$' busca nodos hijo con esenombre exacto 
@onready var turret = $Turret
# Se añade un nodo 'Marker2D' como hijo de la punta del cañón, donde nacerá la bala.
# esto evita que la bala explote antes de salir
@onready var muzzle = $Turret/Muzzle 
@onready var camera = $Camera2D

# carga configuraciones iniciales
func _ready():
	add_to_group("jugador")
	setup_camera_limits()
	current_ammo = max_ammo # iniciliza la variable cantidad munición al máximo
	
	# retraso en la busqueda del HUD, para que lo encuentre. de no estar, le asignaria null de valor
	await get_tree().process_frame
	ui = get_tree().get_first_node_in_group("ui")
	
	# Inicializamos la UI con los valores reales del tanque
	if ui:
		ui.actualizar_salud(health)
		ui.actualizar_municion(current_ammo)

func setup_camera_limits():
	if camera:
		# Aplicamos los límites del mapa a la cámara
		camera.limit_left = map_limit_left
		camera.limit_top = map_limit_top
		camera.limit_right = map_limit_right
		camera.limit_bottom = map_limit_bottom
		
		# Suavizado para que la cámara no pegue frenazos bruscos al llegar al borde
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
	else:
		print("ADVERTENCIA: No se encontró el nodo Camera2D")

func _physics_process(delta: float):
	# este bloque se actualizará 60 veces por segundo (frames) para mandar información actualizada constantemente
	# --- GESTIÓN DE CALOR Y ENFRIAMIENTO ---
	if current_heat > 0:
		current_heat -= overheat_cool_speed * delta 
		if is_overheated and current_heat <= 0:
			is_overheated = false 
	
	# clamp funcion que evita que el calor sea inferior a 0 y superior al maximo permitido
	current_heat = clamp(current_heat, 0, overheat_threshold)
	
	# Actualizamos la barra de calor en la UI si existe
	if ui: ui.actualizar_calor(current_heat, is_overheated)

	# --- SISTEMA DE RECARGA AUTOMÁTICA ---
	if current_ammo < max_ammo:
		regen_timer += delta
		if regen_timer >= ammo_regen_time:
			current_ammo += 1
			regen_timer = 0.0 # Reiniciamos el tiempo para la siguiente bala
			if ui: ui.actualizar_municion(current_ammo)

	# 1. MOVIMIENTO DEL CHASIS
	# se usan los nombres de las acciones definidas en Project -> Project Settings -> Input Map
	var rotation_direction = Input.get_axis("izquierda", "derecha")
	var move_direction = Input.get_axis("retroceder", "avanzar")

	# rotación al chasis
	rotation += rotation_direction * rotation_speed * delta
	
	# Cálculo de la velocidad basada en la rotación actual del tanque
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
	# "disparar" debe estar configurado en el Input Map
	if Input.is_action_just_pressed("disparar"):
		# Solo dispara si se cumplen las dos condiciones de seguridad
		if current_ammo > 0 and not is_overheated:
			shoot()
		else:
			# Feedback para el desarrollador en consola
			if is_overheated:
				print("ARMAS BLOQUEADAS: Sistema sobrecalentado")
			elif current_ammo <= 0:
				print("SIN MUNICIÓN: Cargador vacío")
	
	# --- TEST DE DAÑO ---
	if Input.is_action_just_pressed("ui_accept"): # La tecla 'Enter' por defecto
		recibir_daño()

	# 4. EJECUTAR MOVIMIENTO Y COLISIONES
	# Esta función utiliza la variable interna 'velocity' para desplazar el cuerpo
	move_and_slide()

func shoot():
	# Verificamos que la escena de la bala esté cargada en el Inspector para evitar cierres inesperados
	if bullet_scene and muzzle:
		# instancia del proyectil
		var bullet = bullet_scene.instantiate()
		# Obtenemos la posición global de la punta del cañón
		
		get_parent().add_child(bullet)
		bullet.global_position = muzzle.global_position
		
		# CONFIGURACIÓN CLAVE:
		bullet.shooter_group = "balas_jugador" # <-- Marcamos que es nuestra
		bullet.add_to_group("balas_jugador")
		
		var fire_direction = Vector2.UP.rotated(turret.global_rotation)
		bullet.direction = fire_direction
		bullet.rotation = turret.global_rotation
		
		# Gestión de recursos (gastar)
		current_ammo -= 1 
		current_heat += heat_per_shot
		regen_timer = 0.0 # Interrumpimos la recarga al disparar
		
		# bandera que activa el sobrecalentamiento
		if current_heat >= overheat_threshold:
			is_overheated = true 
		
		# Actualizamos la interfaz
		if ui: ui.actualizar_municion(current_ammo)
	
	else:
		# Mensaje de depuración en caso de olvido en el Inspector
		print("ERROR: No has asignado la 'bullet_scene' en el Inspector del nodo player_tank")

func recibir_daño():
	health -= 1
	health = max(0, health)
	
	if ui:
		if ui.has_method("mostrar_efecto_daño"):
			ui.mostrar_efecto_daño()
		if ui.has_method("actualizar_salud"):
			ui.actualizar_salud(health)
	
	if health <= 0:
		# la UI lo gestiona el reinicio con Y/N
		set_physics_process(false) # bloquea el tanque
		print("JUGADOR: Derrotado. Espere...")
