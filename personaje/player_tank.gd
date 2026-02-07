extends CharacterBody2D

# --- CONFIGURACIÓN DEL TANQUE ---
# '@export' importa datos desde el inspector de Godot
# velocidad de avance y rotación del chasis
@export var speed: float = 150.0 
@export var rotation_speed: float = 1.5 
# suavidad del giro de la torreta
@export var turret_speed: float = 10.0

# --- LÍMITES DEL MAPA ---
# definen las coordenadas máximas donde se moverá la cámara y el tanque
@export var map_limit_left: int = -186
@export var map_limit_top: int = -950
@export var map_limit_right: int = 1000
@export var map_limit_bottom: int = 950

# --- CONFIGURACIÓN DE COMBATE ---
# escena de la bala que se instanciará al disparar
@export var bullet_scene: PackedScene
@export var max_ammo: int = 10
@export var overheat_threshold: float = 100.0
@export var overheat_cool_speed: float = 20.0 # velocidad de enfriamiento por segundo
@export var heat_per_shot: float = 25.0 # calor generado por cada disparo
@export var ammo_regen_time: float = 1.5 # segundos para recuperar una bala

# variables de estado interno
# almacenan los valores que cambian durante la partida
var current_ammo: int = 10
var current_heat: float = 0.0
var is_overheated: bool = false
var health: int = 3
var regen_timer: float = 0.0 # Cronómetro interno para la recarga

# referencia a la interfaz de usuario
# grupo para encontrar el HUD fácilmente en la escena
@onready var ui = get_tree().get_first_node_in_group("ui")

# referencias a los nodos
# no se ejecutarán hasta que estén cargados '@onready'
# '$' busca nodos hijo con esenombre exacto 
@onready var turret = $Turret
# se añade un nodo 'Marker2D' como hijo de la punta del cañón, donde nacerá la bala.
# esto evita que la bala explote antes de salir
@onready var muzzle = $Turret/Muzzle 
@onready var camera = $Camera2D

# carga configuraciones iniciales
func _ready():
	# registra al tanque en el grupo "jugador" para que los enemigos lo reconozcan
	add_to_group("jugador")
	# configura los bordes donde la cámara dejará de seguirnos
	setup_camera_limits()
	# iniciliza la variable cantidad munición al máximo
	current_ammo = max_ammo 
		
	# retraso en la busqueda del HUD, para que lo encuentre. de no estar, le asignaria null de valor
	await get_tree().process_frame
	ui = get_tree().get_first_node_in_group("ui")
	
	# inicializa la UI con los valores reales del tanque
	if ui:
		ui.actualizar_salud(health)
		ui.actualizar_municion(current_ammo)

func setup_camera_limits():
	# verifica que la cámara existe
	if camera:
		# aplica los límites del mapa a la cámara
		camera.limit_left = map_limit_left
		camera.limit_top = map_limit_top
		camera.limit_right = map_limit_right
		camera.limit_bottom = map_limit_bottom
		
		# Suavizado para que la cámara no pegue frenazos bruscos al llegar al borde
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
	else:
		# aviso de seguridad por si no encuentra el nodo cámara
		print("ADVERTENCIA: No se encontró el nodo Camera2D")
		
# este bloque se actualizará 60 veces por segundo (frames) para mandar información actualizada constantementee
func _physics_process(delta: float):	
	# --- GESTIÓN DE CALOR Y ENFRIAMIENTO ---	
	if current_heat > 0:
		# resta calor progresivamente usando 'delta' para que sea independiente de los FPS
		current_heat -= overheat_cool_speed * delta 
		# Si estaba bloqueado por calor y llega a 0, liberamos el sistema de armas
		if is_overheated and current_heat <= 0:
			is_overheated = false 
	
	# clamp funcion que evita que el calor sea inferior a 0 y superior al maximo permitido
	current_heat = clamp(current_heat, 0, overheat_threshold)
	
	# actualiza la barra de calor en la UI si existe
	if ui: ui.actualizar_calor(current_heat, is_overheated)

	# --- SISTEMA DE RECARGA AUTOMÁTICA ---
	# si falta munición, acumula tiempo hasta llegar al intervalo de regeneración
	if current_ammo < max_ammo:
		regen_timer += delta
		if regen_timer >= ammo_regen_time:
			current_ammo += 1
			regen_timer = 0.0 # reinicia el tiempo para la siguiente bala
			# Refrescamos el número de balas en pantalla
			if ui: ui.actualizar_municion(current_ammo)

	# 1. MOVIMIENTO DEL CHASIS
	# se usan los nombres de las acciones definidas en Project -> Project Settings -> Input Map
	var rotation_direction = Input.get_axis("izquierda", "derecha")
	var move_direction = Input.get_axis("retroceder", "avanzar")

	# rotación al chasis
	rotation += rotation_direction * rotation_speed * delta
	
	# cálculo de la velocidad basada en la rotación actual del tanque
	# Vector2.UP (0, -1) apunta hacia adelante en la mayoría de los sprites
	velocity = Vector2.UP.rotated(rotation) * move_direction * speed

	# 2. MOVIMIENTO DE LA TORRETA (Apuntar al ratón)
	var mouse_pos = get_global_mouse_position()
	# calcula el ángulo matemático desde el tanque hacia el ratón
	var angle_to_mouse = (mouse_pos - global_position).angle()
	
	# compensación de 90 grados (PI/2) para alinear el sprite frontal con el ratón
	var final_angle = angle_to_mouse + PI/2
	
	# rotación suavizada de la torreta
	turret.global_rotation = lerp_angle(turret.global_rotation, final_angle, turret_speed * delta)

	# 3. CONTROL DE DISPARO
	# "disparar" debe estar configurado en el Input Map
	if Input.is_action_just_pressed("disparar"):
		# solo dispara si se cumplen las dos condiciones de seguridad
		if current_ammo > 0 and not is_overheated:
			shoot()
		else:
			# feedback para el desarrollador en consola
			if is_overheated:
				print("ARMAS BLOQUEADAS: Sistema sobrecalentado")
			elif current_ammo <= 0:
				print("SIN MUNICIÓN: Cargador vacío")
	
	# --- TEST DE DAÑO ---
	# permite probar el sistema de vidas manualmente
	if Input.is_action_just_pressed("ui_accept"): # La tecla 'Enter' por defecto
		recibir_daño()

	# 4. EJECUTAR MOVIMIENTO Y COLISIONES
	# esta función utiliza la variable interna 'velocity' para desplazar el cuerpo
	move_and_slide()

func shoot():
	# Verificamos que la escena de la bala esté cargada en el Inspector para evitar cierres inesperados
	if bullet_scene and muzzle:
		# instancia del proyectil
		var bullet = bullet_scene.instantiate()
		# establece la posición global de la punta del cañón
		# añade la bala a la escena raíz para que se mueva independiente del tanque
		get_parent().add_child(bullet)
		bullet.global_position = muzzle.global_position
		
		# CONFIGURACIÓN CLAVE:
		# datos para el script bullet.gd (saber a quién dañar)
		bullet.shooter_group = "balas_jugador" # <-- marca al nuestra
		bullet.add_to_group("balas_jugador")
		# calcula la dirección del disparo basándose en hacia dónde mira la torreta
		var fire_direction = Vector2.UP.rotated(turret.global_rotation)
		bullet.direction = fire_direction
		# orienta el sprite de la bala
		bullet.rotation = turret.global_rotation
		
		# gestión de recursos (gastar)
		current_ammo -= 1 
		current_heat += heat_per_shot
		regen_timer = 0.0 # Interrumpimos la recarga al disparar
		
		# bandera que activa el sobrecalentamiento
		if current_heat >= overheat_threshold:
			is_overheated = true 
		
		# actualiza la interfaz para mostrar el gasto
		if ui: ui.actualizar_municion(current_ammo)
	
	else:
		# Mensaje de depuración en caso de olvido en el Inspector
		print("ERROR: No has asignado la 'bullet_scene' en el Inspector del nodo player_tank")

func recibir_daño():
	health -= 1
	# evita que la salud baje de 0
	health = max(0, health)
	
	# si la UI está disponible, llamamos a sus métodos de actualización visual
	if ui:
		if ui.has_method("mostrar_efecto_daño"):
			ui.mostrar_efecto_daño()
		if ui.has_method("actualizar_salud"):
			ui.actualizar_salud(health)
			
	# lógica de fin de partida
	if health <= 0:
		# la UI lo gestiona el reinicio con Y/N
		set_physics_process(false) # bloquea el tanque
		print("JUGADOR: Derrotado. Espere...")

# se asegura de que el jugador ha cumplido la misión
func comprobar_victoria():
	await get_tree().process_frame
	
	var enemigos_restantes = get_tree().get_nodes_in_group("enemigos").size()
	if enemigos_restantes == 0:
		print("SISTEMA: ¡Todos los enemigos eliminados! Activando zona...")
		
		# MÉTODO 1: Buscar por grupo
		var zona = get_tree().get_first_node_in_group("zona_escape")
		
		# MÉTODO 2: Buscar por nombre directo (BACKUP)
		if not zona or zona.get_script() == null:
			print("ADVERTENCIA: Buscando zona por nombre alternativo...")
			zona = get_tree().current_scene.get_node_or_null("EscapeZone")
		
		# MÉTODO 3: Buscar en toda la escena (ÚLTIMA OPCIÓN)
		if not zona or zona.get_script() == null:
			print("ADVERTENCIA: Búsqueda exhaustiva...")
			var todos_nodos = get_tree().current_scene.find_children("EscapeZone", "Area2D", true, false)
			for nodo in todos_nodos:
				if nodo.get_script() != null:
					zona = nodo
					break
		
		if zona and zona.get_script() != null:
			if zona.has_method("activar_zona"):
				zona.activar_zona()
				print("SISTEMA: Zona activada correctamente")

# función para manejar cuando el jugador entra en la zona
func _on_zona_body_entered(body: Node2D):
	# si el que entró es el jugador
	if body == self:  

		# cambia a la escena de victoria
		var zona = get_tree().get_first_node_in_group("zona_escape")
		var next_scene = ""
		
		# intentar obtener la ruta de la siguiente escena
		if zona and "next_scene" in zona:
			next_scene = zona.next_scene
		
		if next_scene != "":
			get_tree().change_scene_to_file(next_scene)
		else:
			# Si no hay escena configurada, ir directamente a victoria
			get_tree().change_scene_to_file("res://scenes/victory.tscn")
