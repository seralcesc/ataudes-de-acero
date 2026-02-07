extends Area2D
class_name EscapeZone

@export var next_scene: String = ""
var is_active: bool = false

func _ready():
	
	# REGISTRAR EN GRUPO CON VERIFICACIÓN
	if not is_in_group("zona_escape"):
		add_to_group("zona_escape")

	
	# FORZAR configuración inicial
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Conectar señal FORZOSAMENTE
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func activar_zona():
	
	is_active = true
	set_deferred("visible", true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	show()


func _on_body_entered(body: Node2D):
	
	if is_active and body.is_in_group("jugador"):
		
		if next_scene != "":
			get_tree().change_scene_to_file(next_scene)
		else:
			get_tree().reload_current_scene()
