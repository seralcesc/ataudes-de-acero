extends StaticBody2D

# --- CONFIGURACIÓN ---
# parámetros ajustables desde el editor para variar la dificultad de cada torreta
# facilita el balanceo
@export var health: int = 2
@export var bullet_scene: PackedScene 
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 250.0 

# --- REFERENCIAS ---
# usa nombres genéricos y comprueba el _ready
var muzzle = null
var shoot_timer = null
var detection_area = null
# referencia al jugador cuando entra en el rango
var target: Node2D = null 

func _ready():
	# registra a la torreta en el grupo "enemigos" para que el jugador sepa a quién dañar
	add_to_group("enemigos")
	
	# busca los nodos manualmente para evitar errores de "Node not found"
	muzzle = get_node_or_null("Muzzle")
	shoot_timer = get_node_or_null("ShootTimer")
	detection_area = get_node_or_null("DetectionArea")
	
	# verificación de seguridad para el temporizador de disparo
	if not shoot_timer:
		print_rich("[color=red][b]ERROR:[/b][/color] No encuentro el nodo 'ShootTimer'. Revisa el nombre en el árbol.")
	else:
		# configura el tiempo entre disparos según variable 'fire_rate'
		shoot_timer.wait_time = fire_rate
		# conecta la señal de tiempo agotado a la función de disparo si no está conectada
		if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
			shoot_timer.timeout.connect(_on_shoot_timer_timeout)
			
	# verificación de seguridad para el área de detección		
	if not detection_area:
		print_rich("[color=red][b]ERROR:[/b][/color] No encuentro el 'DetectionArea'.")
	else:
		# conecta las señales de entrada y salida de cuerpos al área por código
		if not detection_area.body_entered.is_connected(_on_body_entered):
			detection_area.body_entered.connect(_on_body_entered)
		if not detection_area.body_exited.is_connected(_on_body_exited):
			detection_area.body_exited.connect(_on_body_exited)

func _process(_delta):
	# si hay un objetivo válido (el jugador está dentro y no ha muerto)
	if is_instance_valid(target):
		# la torreta gira automáticamente hacia la posición del jugador
		look_at(target.global_position)
		# ajuste de 90 grados para que el cañón mire de frente al objetivo
		rotation += PI/2 

func _on_body_entered(body):
	# si lo que entra en el área pertenece al grupo "jugador"
	if body.is_in_group("jugador"):
		target = body
		# activa el temporizador para que empiece a disparar
		if shoot_timer:
			shoot_timer.start()
		print("SISTEMA: Objetivo detectado -> ", body.name)

func _on_body_exited(body):
	# si el jugador sale del área de visión
	if body == target:
		target = null
		# detiene el temporizador para que deje de disparar
		if shoot_timer:
			shoot_timer.stop()
		print("SISTEMA: Objetivo fuera de alcance.")

func _on_shoot_timer_timeout():
	# si el jugador sigue, vuelve a disparar
	if is_instance_valid(target):
		shoot()

func shoot():
	# comprueba que hay una bala configurada y un punto de salida (muzzle)
	if bullet_scene and muzzle:
		# instancia el proyectil
		var bullet = bullet_scene.instantiate()
		# lo añade a la escena principal para que sea independiente de la torreta
		get_tree().current_scene.add_child(bullet)
		
		# coloca la bala en la punta del cañón de la torreta
		bullet.global_position = muzzle.global_position
		# calcula el vector de dirección hacia el jugador
		var dir = (target.global_position - muzzle.global_position).normalized()
		
		# introduce datos a la munición (esto funciona si bullet.gd tiene estas variables)
		if "direction" in bullet: bullet.direction = dir
		if "speed" in bullet: bullet.speed = bullet_speed
		# evita fuego amigo
		if "shooter_group" in bullet: bullet.shooter_group = "balas_enemigas"
		
		# rota la bala para que visualmente apunte hacia donde vuela
		bullet.rotation = dir.angle() + PI/2
		# la añade al grupo de balas enemigas para el filtro de colisiones
		bullet.add_to_group("balas_enemigas")
	else:
		# aviso en consola si la torreta no está configurada
		print("AVISO: No se puede disparar (falta Muzzle o Bala)")

func recibir_daño():
	health -= 1
	
	# efecto visual: la torreta parpadea en rojo al recibir el impacto
	var tween = create_tween()
	modulate = Color.RED
	# vuelve a su color original (blanco/normal) en 0.1 segundos
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# si la vida llega a 0, eliminamos la torreta del juego
	if health <= 0:
		print("SISTEMA: Torreta destruida.")
		queue_free()
