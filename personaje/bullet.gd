extends Area2D

@export var speed: float = 500.0 # Velocidad del proyectil
var direction: Vector2 = Vector2.ZERO # Dirección de vuelo

func _physics_process(delta: float):
	# Movimiento rectilíneo uniforme en la dirección asignada
	position += direction * speed * delta

# Esta función se ejecutará cuando la bala salga de la pantalla para no consumir memoria
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# Para detectar impactos (esto lo usaremos para destruir tanques enemigos)
func _on_body_entered(body: Node2D):
	# Si lo que tocamos es del grupo "jugador", no hacemos nada (atravesamos)
	if body.is_in_group("jugador"):
		return
	
	# Si llegamos aquí, es que hemos chocado con un muro u otra cosa
	print("Impacto en: ", body.name)
	queue_free()
