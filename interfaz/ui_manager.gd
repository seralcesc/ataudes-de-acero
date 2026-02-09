extends CanvasLayer

# --- REFERENCIAS A LOS ELEMENTOS DE LA UI ---
# '@onready' asegura que el script busque los nodos solo cuando el HUD ya se ha cargado
@onready var ammo_bar = $Control/AmmoContainer/AmmoBar
@onready var heat_bar = $Control/AmmoContainer/HeatBar
@onready var health_label = $Control/StatusContainer/HealthLabel
@onready var damage_overlay = $Control/DamageOverlay
@onready var minimap_player_icon = $Control/Minimap/PlayerIcon
@onready var radio_sound = $RadioSound

# --- ELEMENTOS PARA LA CUENTA ATRÁS ---
@onready var start_overlay = $StartOverlay # pantalla de inicio
@onready var start_label = $StartOverlay/StartLabel # texto de 3, 2, 1...
@onready var game_over_overlay = $GameOverOverlay

# --- CONFIGURACIÓN DEL MINIMAPA ---
# dimensiones totales del mapa
@export var map_total_width: float = 1246.0 
@export var map_total_height: float = 1960.0
# carga el tamaño dado al cuadro del minimapa en el editor de Godot
@onready var minimap_visual_size = $Control/Minimap.size

# --- VARIABLES DE ESTADO ---
var salud_actual: int = 3
var tween_critico: Tween # guarda la animación para poder pararla si recuperamos vida
var cuenta_atras: int = 3
var esta_muerto: bool = false

func _ready():
	# accede al grupo 'ui' para que el tanque nos encuentren al empezar el juego
	add_to_group("ui")
	
	# 1. Configuración inicial de barras
	_setup_ui_initial_state()
	
	# 2. Prepara pantalla de Inicio (Overlay Negro)
	# efecto rojo de daño empieza siendo invisible (Transparencia Alfa a 0)
	if start_overlay:
		# fondo negro visible durante el conteo
		start_overlay.show()
		# color de fondo sea negro opaco al inicio
		start_overlay.modulate.a = 1.0 
		# inicia la secuencia
		iniciar_secuencia_entrada()
	
	# oculta la pantalla de Game Over al principio
	if game_over_overlay:
		game_over_overlay.hide()
		game_over_overlay.modulate.a = 0.0
	
	# sincroniza la etiqueta de salud al arrancar
	actualizar_salud(3)

func _input(event):
	# activa estas teclas si el jugador ha muerto
	if esta_muerto:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_Y:
				get_tree().reload_current_scene()
			elif event.keycode == KEY_N:
				get_tree().quit()
	
func _process(_delta):
	# actualiza la posición del icono en el minimapa en cada frame
	actualizar_minimapa()

func _setup_ui_initial_state():
	# configura la barra de munición
	if ammo_bar:
		ammo_bar.max_value = 10 
		ammo_bar.value = 10
		# oculta el número del porcentaje para que solo se vea la barra visual
		if ammo_bar is ProgressBar: ammo_bar.show_percentage = false
	# configura la barra de calor
	if heat_bar:
		heat_bar.max_value = 100
		heat_bar.value = 0
		if heat_bar is ProgressBar: heat_bar.show_percentage = false

# --- LÓGICA DE INICIO Y FIN---

func iniciar_secuencia_entrada():
	# bloquea el movimiento del tanque mientras carga la pantalla
	get_tree().call_group("jugador", "set_physics_process", false)
	
	# reproduce el sonido
	if radio_sound:
		radio_sound.play()
	
	if start_label:
		start_label.text = "READY?"
	await get_tree().create_timer(1.2).timeout
	gestionar_conteo()

func gestionar_conteo():
	# si aún quedan números por mostrar (3, 2, 1)
	if cuenta_atras > 0:
		start_label.text = str(cuenta_atras)
		
		# efecto visual de "pulsolatido"
		var tween = create_tween()
		# ajuste del centro para que el escalado sea desde el medio del texto
		start_label.pivot_offset = start_label.size / 2 
		start_label.scale = Vector2(2.5, 2.5) 
		# el número encoge suavemente hasta su tamaño normal
		tween.tween_property(start_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		cuenta_atras -= 1
		# espera un segundo real antes de la siguiente cifra
		await get_tree().create_timer(1.0).timeout
		gestionar_conteo()
	else:
		# cuando llega a 0, pasamos al mensaje de salida
		finalizar_entrada()

func finalizar_entrada():
	if start_label:
		start_label.text = "GO!"
	# breve pausa con el mensaje de "GO!" en pantalla	
	await get_tree().create_timer(0.6).timeout
	var tween_fade = create_tween()
	# animación para desvanecer el fondo negro (fade out)
	tween_fade.tween_property(start_overlay, "modulate:a", 0.0, 0.5)
	# devuelve el control del movimiento al jugador
	get_tree().call_group("jugador", "set_physics_process", true)
	# limpia la pantalla
	await tween_fade.finished
	if start_overlay: start_overlay.hide()

func mostrar_game_over():
	# evita que la animación se dispare más de una vez si recibimos daño extra al morir
	if esta_muerto: return
	esta_muerto = true
	
	if game_over_overlay:
		# muestra el panel de "Game Over"
		game_over_overlay.show()
		var tween = create_tween()
		# animación de aparición gradual
		tween.tween_property(game_over_overlay, "modulate:a", 1.0, 1.0)
		# detiene el tiempo del juego/jugador
		get_tree().call_group("jugador", "set_physics_process", false)

# --- MÉTODOS DE INTERFAZ (Llamados desde player_tank.gd) ---

# cambia el texto de salud
func actualizar_salud(puntos: int):
	salud_actual = puntos
	if health_label:
		# Uso de icono de corazón en lugar de texto plano
		var corazones = ""
		for i in range(puntos):
			corazones += "♥ "
		health_label.text = "ESTADO: " + corazones
	
	# en caso de quedar con una vida, parpadeo rojo del borde
	if salud_actual <= 0:
		detener_parpadeo_critico()
		mostrar_game_over() # llama a la funcion gameover que activa el panel de reintentar
	elif salud_actual == 1:
		iniciar_parpadeo_critico() # llama a estado critcio (parpadeo constante)
	else:
		detener_parpadeo_critico()

# actualiza la barra de munición en el centro superior
func actualizar_municion(cantidad: int):
	if ammo_bar:
		# mediante Tween se anima la barra llena/vacía suavemente
		var tween = create_tween() # crea animaciones nuevas
		# anima la propiedad "value" de la barra hasta la cantidad actual en 0.1 segundos
		tween.tween_property(ammo_bar, "value", cantidad, 0.1)

# gestiona la barra de calor. Cambia a rojo si el arma se bloquea por 5 segundos
func actualizar_calor(valor: float, esta_bloqueado: bool):
	if heat_bar:
		heat_bar.value = valor
		# lógica de cambio de color para ProgressBar (StyleBoxFlat)
		var style = heat_bar.get_theme_stylebox("fill")
		# verifica que el estilo exista para evitar errores de ejecución
		if style:
			# duplica el estilo para que el cambio de color solo afecte a ESTA barra
			var style_box = style.duplicate()
			# establece coloress para la barra de sobrecalentamiento
			style_box.bg_color = Color.RED if esta_bloqueado else Color.SKY_BLUE.lerp(Color.ORANGE, valor / 100.0) 
			# aplica el estilo modificado a la barra
			heat_bar.add_theme_stylebox_override("fill", style_box)

# crea el efecto de parpadeo rojo cuando recibimos un impacto
func mostrar_efecto_daño():
	# asegura que de quedar una vida no se ejecute lo de abajo (estado_critico)
	if salud_actual <= 1: return 
	if damage_overlay:
		# 'Tween': animación por código fluida
		var tween = create_tween()
		# 1. aparece el rojo (opacidad 0.6) rápido en 0.1 seg
		tween.tween_property(damage_overlay, "modulate:a", 0.6, 0.1)
		# 2. desaparece el rojo (opacidad 0.0) en 0.3 seg
		tween.tween_property(damage_overlay, "modulate:a", 0.0, 0.3)

func iniciar_parpadeo_critico():
	# si ya hay una animación de crítico funcionando, no creamos otra nueva (evita solapamientos)
	if tween_critico and tween_critico.is_running(): return 
	
	if damage_overlay:
		# crea un bucle infinito (.set_loops) de parpadeo rojo
		tween_critico = create_tween().set_loops()
		# animación tipo "respiración": de casi invisible (0.1) a visible (0.4) de forma cíclica
		# cada transición dura 0.8 segundos para dar sensación de pulsación
		tween_critico.tween_property(damage_overlay, "modulate:a", 0.4, 0.8)
		tween_critico.tween_property(damage_overlay, "modulate:a", 0.1, 0.8)

func detener_parpadeo_critico():
	# si existe el Tween del crítico, lo elimina inmediatamente
	if tween_critico:
		tween_critico.kill() 
	# fuerza que el overlay vuelva a ser totalmente invisible
	if damage_overlay:
		damage_overlay.modulate.a = 0

# --- LÓGICA DEL MINIMAPA ---

func actualizar_minimapa():
	# busca al tanque por su grupo de 'jugador'
	var player = get_tree().get_first_node_in_group("jugador")
	if player:
		# regla de tres: (Posición real / Tamaño mapa) * Tamaño cuadro minimapa
		var rel_x = (player.global_position.x / map_total_width) * minimap_visual_size.x
		var rel_y = (player.global_position.y / map_total_height) * minimap_visual_size.y
		
		# ajusta el icono dentro del cuadro del minimapa
		# el "+ (minimap_visual_size / 2)" centra el dibujo en el cuadro
		minimap_player_icon.position = Vector2(rel_x, rel_y) + (minimap_visual_size / 2)
