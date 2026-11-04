# 🚨 PanicAura v1.4.0 — Asistente de Supervivencia para TuWoW (Die & Rise + Hardcore)

> ### 📥 **DESCARGA DIRECTA (ÚLTIMA VERSIÓN v1.4.0)**
> 
> 🚀 **[Descargar PanicAura v1.4.0 (.ZIP)](https://github.com/zequielbogado-alt/PanicAura/releases/download/v1.4.0/PanicAura_v1.4.0.zip)**  
> 📦 **[Descargar PanicAura v1.4.0 (.RAR)](https://github.com/zequielbogado-alt/PanicAura/releases/download/v1.4.0/PanicAura_v1.4.0.rar)**  
> 🏷️ Ver todas las versiones en [Releases de GitHub](https://github.com/zequielbogado-alt/PanicAura/releases/tag/v1.4.0)
> 
> **Verificación de Seguridad (SHA-256):**  
> • `.zip`: `876E1F8FB2C43F41A57AAB0204D443E8CC8720BACF74FE481423578079D78AC7`  
> • `.rar`: `1FA8DECEFB1290CC31C849258E00DD70A88B79B07D49619A9A674C8A6F52B2A2`

---

**PanicAura** es un addon ligero, visual, modular y nada invasivo diseñado específicamente para ayudarte a sobrevivir en **TuWoW** (WoW 3.3.5a con interfaz ForeverUI y modos **Die & Rise / Hardcore**).

Mientras todo está tranquilo, **no ocupa lugar en tu pantalla**. Solo entra en acción cuando tu personaje corre peligro real, mostrándote tus habilidades y pociones salvavidas junto con la tecla exacta que debes presionar para reaccionar a tiempo y no morir.

---

## ✨ Características Principales

### 1. 🚦 Sistema de Alertas en 3 Niveles (Amarillo, Naranja y Rojo)
El addon evalúa la severidad del combate y adapta dinámicamente sus avisos visuales y sonoros:
* 🟡 **Alerta Amarilla (Precaución):** Se activa cuando tu vida desciende al umbral de advertencia (por defecto **70%**), cuando **muere tu mascota** en combate o cuando te agreden **3 o más enemigos** a la vez. Es un aviso temprano para reposicionarte o preparar defensas.
* 🟠 **Alerta Naranja (Rango de Peligro / Advertencia de Náuseas):**
  * **Para Cazadores:** Te avisa al instante si un enemigo atacante ingresa a tu **zona muerta / melé (< 8 metros)** donde no puedes disparar con arco/arma de fuego, sugiriéndote habilidades defensivas de escape (*Aspecto del guepardo/mono, Golpe de alas, Trampa de congelación, Disparo de conmoción*).
  * **En estado Putrefacto:** Detecta el rechazo estomacal al comer y te previene del riesgo inminente de vómito.
* 🔴 **Alerta Roja (Emergencia Crítica):** Se activa cuando tu vida cae al **40% o menos**, si recibes un **Golpe Brutal** repentino o cuando **comienzas a vomitar**. Los bordes de la pantalla laten con una viñeta roja pulsante, suena una alarma de emergencia y la barra salvavidas brilla para tu respuesta inmediata.

---

### 2. 💀 Integración con el Modo "Die & Rise" y Elixir de Purificación
PanicAura comprende todas las mecánicas nativas de **Die & Rise** de TuWoW:
* **Barra de Estado Siempre Visible:** Muestra un widget discreto con tu condición actual: **Vivo**, **Putrefacto (1 Muerte)** o **Esquelético**.
* **Detección y Auto-Recuperación con Elixir de Purificación:** Al consumir un *Elixir de Purificación* (dropeado por rares por franjas de nivel) o recibirlo en comercio, el addon detecta inmediatamente la purificación en tiempo real y **actualiza el estado a "Vivo" al instante** sin necesidad de reloguear ni reiniciar la interfaz. Además, te recuerda por chat si llevas un elixir en tus bolsas estando putrefacto.
* **Margen de Vida Automático:** Si estás **Putrefacto**, el addon eleva automáticamente los umbrales de alerta un **+10%** antes (y un **+15%** si estás **Esquelético**), otorgándote mayor tiempo de reacción.
* **Bloqueo Visual de Pociones en Esquelético:** Dado que los esqueletos no pueden beber pociones, PanicAura estampa una **`X` roja de bloqueo** sobre las ranuras de pociones de tu barra para evitar clics inútiles.
* **Progreso de Almas (0 / 300) y Corporeidad:** Monitorea en vivo tus almas cosechadas para recuperar el cuerpo (festejando al llegar a 300) y rastrea la cuenta regresiva de **36 segundos de Corporeidad** tras consumir un alma.

---

### 3. 🗺️ Alerta de Zona Peligrosa (Nivel Superior)
* **Aviso Preventivo al Cruzar Fronteras:** Si viajas o ingresas a una zona donde los enemigos superan tu nivel en más de lo configurado (por defecto **+1 nivel**, ajustable de +1 a +5), el addon te advierte antes de que sea tarde.
* **Diseño Limpio y No Invasivo:** **No despliega barras de pánico**. Muestra un cartel central elegante con el nombre y nivel de la zona (`¡ZONA PELIGROSA: BOSQUE DEL OCASO! Nivel: 18 - 30`), emite **3 pulsos suaves de destello** perimetral y reproduce un sonido de alerta que se desvanece tras 3.5 segundos.
* **Base de datos completa:** Cubre todas las zonas abiertas, mazmorras y bandas del juego con soporte bilingüe (`esES` y `enUS`). Puedes probarla con `/pa testzone`.

---

### 4. ⚔️ Contador de Agresores y Detector de "Golpe Brutal"
* **Contador de Atacantes en Vivo:** Al lado de la barra de emergencia se muestra en tiempo real cuántos enemigos te tienen como objetivo directo.
* **Detector de Golpe Brutal:** Si sufres un impacto que reduce más del **35% de tu vida máxima de una sola vez**, se dispara la alerta roja instantáneamente advirtiéndote del peligro letal.

---

### 5. 🛡️ Barra de Salvavidas Inteligente y Configurable
* **Auto-configuración por Clase:** Carga automáticamente los mejores recursos defensivos según juegues Cazador, Brujo, Mago, Paladín, Sacerdote, Pícaro, Druida, Guerrero, Chamán o Caballero de la Muerte.
* **Detección Automática de Atajos (Keybinds):** Analiza todas tus barras de acción (1 a 120, macros y libro) y proyecta en grande la tecla asignada (`1`, `F`, `Shift-R`, etc.), además de permitir clic directo sobre los iconos.
* **Asignación Drag & Drop:** Arrastra libremente cualquier hechizo, objeto, piedra de salud o macro desde tu libro o mochilas hacia la barra.

---

### 6. 📜 Historial de Muertes
En la pestaña **Die & Rise** del menú de configuración queda registrado el historial detallado de las muertes de tu personaje: **fecha, hora, nivel, zona, agresor, habilidad final** y cambio de estado correspondiente.

---

## 🏗️ Arquitectura Modular (v1.4.0)

Para garantizar máximo rendimiento, mantenibilidad y evitar código monolítico, PanicAura está estructurado en 11 módulos independientes:

```
Interface/AddOns/PanicAura/
├── PanicAura.toc             # Metadatos y secuencia ordenada de carga
├── PanicAura_Core.lua        # Variables guardadas, base de datos y perfiles por clase
├── PanicAura_Minimap.lua     # Botón arrastrable del minimapa (ForeverUI y clásico)
├── PanicAura_Flash.lua       # Marco de viñeta y destellos perimetrales de pantalla
├── PanicAura_HUD.lua         # Marco principal, banner de aviso y contador de atacantes
├── PanicAura_Slots.lua       # Mapeo de keybinds, cooldowns, ranuras y bloqueo esquelético (X)
├── PanicAura_DieAndRise.lua  # Widget Die & Rise, elixires de purificación, almas y corporeidad
├── PanicAura_Alerts.lua      # Lógica de cálculo de amenazas, rango de cazador y umbrales
├── PanicAura_Events.lua      # Control de eventos del juego, combat log y ticker amortiguado
├── PanicAura_ZoneData.lua    # Catálogo de niveles de zonas abiertas, mazmorras y raids
├── PanicAura_ZoneAlert.lua   # Módulo visual y sonoro de alerta de zonas peligrosas
└── PanicConfig.lua           # Interfaz gráfica de ajustes (4 pestañas) y comandos /pa
```

---

## 💻 Instalación Rápida

1. Descarga el paquete [**`PanicAura_v1.4.0.zip`**](https://github.com/zequielbogado-alt/PanicAura/releases/download/v1.4.0/PanicAura_v1.4.0.zip) o [**`PanicAura_v1.4.0.rar`**](https://github.com/zequielbogado-alt/PanicAura/releases/download/v1.4.0/PanicAura_v1.4.0.rar).
2. Extrae la carpeta **`PanicAura`** dentro del directorio de addons de tu juego:
   ```
   C:\TuWoW\TuWoW-Client\Interface\AddOns\PanicAura
   ```
3. Verifica que los archivos `.lua` y `.toc` queden directamente dentro de dicha carpeta.
4. Ingresa al juego o escribe `/reload` en el chat si ya estabas conectado.

---

## 🎮 Comandos y Atajos

* **Clic Izquierdo en el icono del Minimapa** (o `/pa` / `/panicaura`): Abre el **Panel de Configuración** con 4 pestañas (*General*, *Alertas*, *Die & Rise* y *Ranuras*).
* **Clic Derecho en el Minimapa:** Alterna el **Modo Prueba** para previsualizar alertas.
* **Shift + Clic Derecho en el Minimapa:** Muestra la barra en modo silencioso para arrastrar y organizar habilidades o pociones.
* **Botón "Mover barra":** Desbloquea la barra y el widget de *Die & Rise* para reubicarlos en cualquier punto de tu pantalla.

### Comandos de consola útiles:
| Comando | Descripción |
|---|---|
| `/pa` o `/panicaura` | Abre o cierra la ventana de configuración |
| `/pa testzone` o `/pa tz` | Simula la **Alerta de Zona Peligrosa** |
| `/pa test1` | Prueba la alerta **Amarilla** |
| `/pa test2` | Prueba la alerta **Naranja** |
| `/pa test` o `/pa test3` | Prueba la alerta **Roja** de emergencia |
| `/pa dr1` | Simula el estado **Putrefacto** en el widget |
| `/pa dr2` | Simula el estado **Esquelético** con bloqueo de pociones |
| `/pa corp` | Simula el temporizador de **Corporeidad (36s)** |
| `/pa dr0` | Restablece el widget a estado **Vivo** |
| `/pa reset` | Restaura la configuración a los valores por defecto |
