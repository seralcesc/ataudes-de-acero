extends CanvasLayer

# --- REFERENCIAS A LOS ELEMENTOS DE LA UI ---
# '@onready' asegura que el script busque los nodos solo cuando el HUD ya se ha cargado
@onready var ammo_bar = $Control/AmmoContainer/AmmoBar
@onready var heat_bar = $Control/AmmoContainer/HeatBar
@onready var health_label = $Control/StatusContainer/HealthLabel
@onready var damage_overlay = $Control/DamageOverlay
@onready var minimap_player_icon = $Control/Minimap/PlayerIcon

# --- CONFIGURACIÓN DEL MINIMAPA ---
# Dimensiones totales del mapa
@export var map_total_width: float = 1246.0 
@export var map_total_height: float = 1960.0
# Carga el tamaño dado al cuadro del minimapa en el editor de Godot
@onready var minimap_visual_size = $Control/Minimap.size

# --- VARIABLES PARA EL EFECTO CRÍTICO ---
var salud_actual: int = 3
var tween_critico: Tween # Guarda la animación para poder pararla si recuperamos vida

func _ready():
	# Accede al grupo 'ui' para que el tanque nos encuentre al empezar el juego
	add_to_group("ui")
	
	# El efecto rojo de daño empieza siendo invisible (Transparencia Alfa a 0)
	if damage_overlay:
		# fuerza que ocupe toda la pantalla
		damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Ajuste manual por si los anclajes fallan por el nodo padre
		var screen_size = get_viewport().get_visible_rect().size
		damage_overlay.size = screen_size
		damage_overlay.position = Vector2.ZERO
		
		# las acciones de disparo no se ven afectadas por el indicardor de daño recibido
		# evita el bloqueo de los clics del ratón
		damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# damos visibilidad (la opacidad es 0, pero el nodo debe estar 'show')
		damage_overlay.modulate.a = 0
		damage_overlay.show()
	else:
		print("ERROR: No se encuentra el nodo DamageOverlay. Revisa el HUD.")

	# Configuración inicial de las ProgressBars
	# barra de munición
	if ammo_bar:
		ammo_bar.max_value = 10 
		ammo_bar.value = 10
		if ammo_bar is ProgressBar:
			ammo_bar.show_percentage = false
	
	# barra de sobrecalentamiento
	if heat_bar:
		heat_bar.max_value = 100
		heat_bar.value = 0
		if heat_bar is ProgressBar:
			heat_bar.show_percentage = false

	# Establece el texto de salud inicial al arrancar el juego en las vidas establecidas (3)
	actualizar_salud(3)
	
func _process(_delta):
	# Actualiza la posición del icono en el minimapa en cada frame
	actualizar_minimapa()

# --- MÉTODOS DE ACTUALIZACIÓN (Llamados desde player_tank.gd) ---

# Cambia el texto de salud
func actualizar_salud(puntos: int):
	salud_actual = puntos
	if health_label:
		# Uso de icono de corazón en lugar de texto plano
		var corazones = ""
		for i in range(puntos):
			corazones += "♥ "
		health_label.text = "ESTADO: " + corazones
	
	# en caso de quedar con una vida, parpadeo rojo del borde
	if salud_actual == 1:
		iniciar_parpadeo_critico()
	else:
		detener_parpadeo_critico()

# Actualiza la barra de munición en el centro superior
func actualizar_municion(cantidad: int):
	if ammo_bar:
		# mediante Tween se anima la barra llena/vacía suavemente
		var tween = create_tween() # crea animaciones nuevas
		# Anima la propiedad "value" de la barra hasta la cantidad actual en 0.1 segundos
		tween.tween_property(ammo_bar, "value", cantidad, 0.1)

# Gestiona la barra de calor. Cambia a rojo si el arma se bloquea por 5 segundos
func actualizar_calor(valor: float, esta_bloqueado: bool):
	if heat_bar:
		heat_bar.value = valor
		# Lógica de cambio de color para ProgressBar (StyleBoxFlat)
		if heat_bar is ProgressBar:
			# Buscamos el estilo de la parte rellena de la barra
			var style = heat_bar.get_theme_stylebox("fill")
			
			# Verifica que el estilo exista para evitar errores de ejecución
			if style:
				# Duplica el estilo para que el cambio de color solo afecte a ESTA barra
				var style_box = style.duplicate()
				
				if esta_bloqueado:
					style_box.bg_color = Color.RED # Rojo brillante si el arma se bloquea
				else:
					# Cambia gradualmente de azul (frío) a naranja (caliente) según el valor
					style_box.bg_color = Color.SKY_BLUE.lerp(Color.ORANGE, valor / 100.0)
				
				# Aplica el estilo modificado a la barra
				heat_bar.add_theme_stylebox_override("fill", style_box)

# Crea el efecto de parpadeo rojo cuando recibimos un impacto
func mostrar_efecto_daño():
	if salud_actual <= 1: return #asegura que de quedar una vida no se ejecute lo de abajo (estado_critico)
	if damage_overlay:
		# 'Tween': animación por código fluida
		var tween = create_tween()
		# 1. Aparece el rojo (opacidad 0.6) rápido en 0.1 seg
		tween.tween_property(damage_overlay, "modulate:a", 0.6, 0.1)
		# 2. Desaparece el rojo (opacidad 0.0) en 0.3 seg
		tween.tween_property(damage_overlay, "modulate:a", 0.0, 0.3)

func iniciar_parpadeo_critico():
	# Si ya hay una animación de crítico funcionando, no creamos otra nueva (evita solapamientos)
	if tween_critico and tween_critico.is_running(): return 
	
	if damage_overlay:
		# Crea un bucle infinito (.set_loops) de parpadeo rojo
		tween_critico = create_tween().set_loops()
		# Animación tipo "respiración": de casi invisible (0.1) a visible (0.4) de forma cíclica
		# Cada transición dura 0.8 segundos para dar sensación de pulsación
		tween_critico.tween_property(damage_overlay, "modulate:a", 0.4, 0.8)
		tween_critico.tween_property(damage_overlay, "modulate:a", 0.1, 0.8)

func detener_parpadeo_critico():
	# Si existe el Tween del crítico, lo eliminamos inmediatamente
	if tween_critico:
		tween_critico.kill() 
	# Forzamos que el overlay vuelva a ser totalmente invisible
	if damage_overlay:
		damage_overlay.modulate.a = 0

# --- LÓGICA DEL MINIMAPA ---

func actualizar_minimapa():
	# Buscamos al tanque por su grupo de 'jugador'
	var player = get_tree().get_first_node_in_group("jugador")
	if player:
		# Regla de tres: (Posición real / Tamaño mapa) * Tamaño cuadro minimapa
		var rel_x = (player.global_position.x / map_total_width) * minimap_visual_size.x
		var rel_y = (player.global_position.y / map_total_height) * minimap_visual_size.y
		
		# Ajustamos el icono dentro del cuadro del minimapa
		# El "+ (minimap_visual_size / 2)" centra el dibujo en el cuadro
		minimap_player_icon.position = Vector2(rel_x, rel_y) + (minimap_visual_size / 2)
