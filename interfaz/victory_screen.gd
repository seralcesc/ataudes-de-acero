extends Control

@onready var btn_reintentar = $VBoxContainer/BtnReintentar
@onready var btn_menu = $VBoxContainer/BtnMenu

func _ready():
	# quita la pausa el juego
	get_tree().paused = false
	
	# conecta los botones
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
		
	if btn_menu:
		btn_menu.pressed.connect(_on_menu)
	
	# Animación de entrada
	modulate.a = 0
	scale = Vector2(0.5, 0.5) # Empieza pequeño
	
	var tween = create_tween()
	tween.set_parallel(true) # Anima varias cosas a la vez
	
	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
	
	# Zoom in (de pequeño a tamaño normal)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_reintentar():
	# ajusta esta ruta a la escena principal del nivel
	get_tree().change_scene_to_file("res://personaje/World.tscn")

func _on_menu():
	# se sale del juego
	get_tree().quit()
