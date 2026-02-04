# Ataúdes de Acero (Steel Coffins) 🛡️🚜

![Versión](https://img.shields.io/badge/Versi%C3%B3n-1.2-blue)
![Plataforma](https://img.shields.io/badge/Plataforma-PC%20Windows%2FLinux-orange)
![Engine](https://img.shields.io/badge/Engine-Godot%204.x-blueviolet)

**Ataúdes de Acero** es un juego de acción táctica en vista cenital (top-down) inspirado en los intensos combates de blindados de la Segunda Guerra Mundial. Toma el mando de un tanque en territorio hostil, neutraliza las amenazas y asegura la zona de extracción.

---

## 📖 Documento de Diseño de Juego (GDD)

### 1. Concepto del Juego

- **Elevator Pitch:** Acción táctica top-down donde la precisión y el manejo del blindado son la clave para la supervivencia.
- **Género:** Top-Down Shooter / Acción Táctica.
- **Objetivo:** Eliminar las amenazas del sector y alcanzar el punto de extracción marcado con la bandera.

### 2. Mecánicas de Juego (Gameplay)

#### ⚙️ Física y Movimiento

El juego apuesta por un **movimiento realista**:

- El tanque no tiene desplazamiento lateral.
- La rotación del chasis y el avance son independientes, simulando un comportamiento real.
- **Atributos del Jugador:**
  - Velocidad de movimiento: $150 px/s$
  - Velocidad de rotación: $1.5 rad/s$

#### ⚔️ Combate y Salud

- **Sistema de Disparo:** Proyectiles gestionados mediante señales (`Area2D`) con un `Marker2D` en la punta del cañón para evitar colisiones internas.
- **Gestión de Daño:** Implementación por sistema de grupos (`add_to_group`). Las balas distinguen entre aliados y enemigos.
- **Sistema de Vida:** El jugador cuenta con **3 puntos de vida**. Cada impacto genera un retroceso visual (knockback).

### 3. Controles 🕹️

| Acción                   | Tecla / Input          |
| :----------------------- | :--------------------- |
| **Avanzar / Retroceder** | `W` / `S`              |
| **Rotar Chasis**         | `A` / `D`              |
| **Apuntar Torreta**      | `Movimiento del Ratón` |
| **Disparar**             | `Click Izquierdo`      |

---

### 4. Arquitectura Técnica (Godot 4)

El proyecto utiliza una estructura jerárquica limpia aprovechando las bondades de Godot:

- **Nodos Clave:** `CharacterBody2D` para el tanque, `Camera2D` con suavizado de movimiento y `Marker2D` para el spawn de proyectiles.
- **Señales:** Uso intensivo de `body_entered` para una gestión de colisiones eficiente.
- **Organización:** Clasificación de entidades mediante los grupos `"jugador"` y `"enemigos"`.

### 5. Interfaz de Usuario (UI/HUD)

- **HUD de Combate:** Indicador de salud (3 iconos de tanque) y contador de bajas en la parte superior.
- **Estados de Juego:** Pantallas dedicadas para **Victoria** (al alcanzar la bandera) y **Game Over** (con opción de reinicio).

---

## 🛠️ Próximas Implementaciones

- [ ] **Torreta Estática:** Enemigo básico que detecta por proximidad.
- [ ] IA de movimiento para tanques enemigos.
- [ ] Sistema de partículas para explosiones y rastro de orugas.

---

## 👤 Autor

**Sergio Alcántara Escudero** Estudiante de 1º de DAM - Rota (Cádiz).

🔗 **Enlaces:**

- [Itch.io](https://seralcesc.itch.io/)
- [GitHub](https://github.com/seralcesc)

---

_Documento actualizado a 03 de febrero de 2026 - Versión 1.2_

# ataudes-de-acero
