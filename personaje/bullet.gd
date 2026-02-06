extends Area2D

# --- BALÍSTICA DEL PROYECTIL ---
# @export para poder cambiar la velocidad desde el Inspector
@export var speed: float = 500.0
# dirección de vuelo
var direction: Vector2 = Vector2.ZERO
var shooter_group: String = "" # guarda quién dispara la bala

func _physics_process(delta: float):
	# movimiento lineal constante en la dirección asignada. Delta le da fluidez
	position += direction * speed * delta

# --- LÓGICA DE DETECCIÓN DE IMPACTOS ---
# se ejecuta automáticamente cuando la bala entra en contacto con otro cuerpo
func _on_body_entered(body: Node2D):
	# 1. FILTRO DE FUEGO AMIGO (Lógica de Grupos).
	# si la bala es del jugador y toca al jugador, la ignoramos.
	# evita que el tanque se suicide con su propia bala nada más nacer
	if body.is_in_group(shooter_group): 
		return

	# 2. APLICAR DAÑO
	if shooter_group == "balas_jugador":
		# si la bala es mía, solo daño a enemigos
		if body.is_in_group("enemigos") and body.has_method("recibir_daño"):
			body.recibir_daño() # llama a la función de daño del enemigo
			queue_free() # borra la bala tras el impacto
			
	elif shooter_group == "balas_enemigas":
		# si la bala es de la torreta, solo daño al jugador
		if body.is_in_group("jugador") and body.has_method("recibir_daño"):
			body.recibir_daño() # llama a la función de daño del jugador
			queue_free() # borra la bala tras el impacto
	
	# 3. IMPACTO CONTRA EL ENTORNO
	# Si toca un muro (StaticBody2D que no sea enemigo), también desaparece
	if body is StaticBody2D and not body.is_in_group("enemigos"):
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	# si la bala sale de la pantalla, se borra para no gastar memoria
	queue_free()
