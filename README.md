# 🚨 PanicAura — Asistente de Supervivencia para TuWoW (Die & Rise + Hardcore)

**PanicAura** es un addon ligero, visual y nada invasivo diseñado específicamente para ayudarte a sobrevivir en **TuWoW** (WotLK 3.3.5a con interfaz ForeverUI y modo **Die & Rise / Hardcore**).

Mientras todo está tranquilo, **no ocupa nada de lugar en tu pantalla**. Solo aparece cuando tu personaje corre peligro real, mostrándote tus habilidades y pociones salvavidas junto con la tecla exacta que debes apretar para no entrar en pánico.

---

## ✨ ¿Qué hace y cómo te ayuda a no morir?

### 1. 🚦 Sistema de Alertas en 3 Niveles (Amarillo, Naranja y Rojo)
En lugar de asustarte todo el tiempo con una alarma igual, el addon evalúa el peligro y cambia de color e intensidad:
* 🟡 **Alerta Amarilla (Precaución):** Se activa cuando tu vida empieza a bajar (por defecto al **70%**), cuando **muere tu mascota** en combate o cuando te están pegando **3 o más enemigos** a la vez. Es un aviso suave para que vayas preparando tus defensas.
* 🟠 **Alerta Naranja (Rango de Peligro / Náuseas):**
  * **Para Cazadores:** Te avisa al instante si un enemigo que te ataca se mete en tu **zona muerta** (donde no puedes disparar ni pegar) o **cuerpo a cuerpo**, y te sugiere en pantalla qué usar (*Aspecto del guepardo/mono, Golpe de alas, Trampa de congelación, Disparo de conmoción*).
  * **En estado Putrefacto:** Te avisa cuando tu estómago rechaza la comida y sientes náuseas.
* 🔴 **Alerta Roja (Emergencia Crítica):** Se activa cuando tu vida cae al **40% o menos**, cuando recibes un **Golpe Brutal** de repente o cuando **comienzas a vomitar**. Los bordes de la pantalla laten en rojo, suena una alarma de emergencia y tus botones salvavidas brillan para que reacciones al instante.

---

### 2. 💀 Integración Especial con el Modo "Die & Rise" de TuWoW
PanicAura entiende las reglas únicas de **Die & Rise** y se conecta con el sistema del servidor para cuidarte según el estado de tu personaje:
* **Indicador inteligente de Estado:** Muestra una pequeña barra (solo cuando estás **Putrefacto** o **Esquelético**) para recordarte en qué estado estás.
* **Más margen de vida automática:** Si estás **Putrefacto**, el addon sube tus alertas un **+10%** antes (y un **+15%** si estás **Esquelético**), porque sabe que un error te cuesta muchísimo más caro.
* **Aviso de Náuseas y Vómito (Putrefacto):** Si comes estando putrefacto y tu estómago lo rechaza, el addon detecta el mensaje y te advierte con una alerta naranja que **podrías vomitar en cualquier momento**, para que no inicies una pelea peligrosa. Cuando empiezas a vomitar, salta una alerta roja inmediata.
* **Progreso de Almas (0 / 300) en Esquelético:** Muestra una barra con la cantidad exacta de almas que llevas juntadas matando monstruos que dan experiencia, y te festeja con un aviso en pantalla apenas llegas a las **300 almas** para que vayas a recuperar tu cuerpo.
* **Bloqueo visual de Pociones en Esquelético:** Como los esqueletos no pueden tomar pociones, el addon les pone una **`X` roja** encima en tu barra de emergencia para que no pierdas tiempo apretando una poción que no va a funcionar.
* **Reloj de 36 segundos de Corporeidad:** Cuando sacrificas **1 alma** para poder comer y beber, aparece una barra turquesa en cuenta regresiva de **36 segundos** (y te avisa cuando quedan 6 segundos para que se termine).

---

### 3. ⚔️ Contador de Atacantes y Detector de "Golpe Brutal"
* **Contador de Enemigos ("Atacantes"):** Al lado de tu barra de emergencia verás un número rojo gigante que te dice exactamente **cuántos bichos te están pegando a ti** en ese momento.
* **Detector de Golpe Brutal:** Si un enemigo te saca más del **35% de tu vida máxima de un solo golpe**, la alerta roja se dispara de inmediato aunque todavía tengas bastante vida, advirtiéndote que el próximo golpe podría matarte.

---

### 4. 🛡️ Barra de Salvavidas Inteligente y Personalizable
* **Reconoce tu clase automáticamente:** Al instalarlo, ya viene configurado con los 5 mejores poderes defensivos de tu clase (Cazador, Brujo, Mago, Paladín, Sacerdote, Pícaro, Druida, Guerrero, Chamán o Caballero de la Muerte).
* **Muestra tus atajos de teclado (Keybinds):** Lee tus barras de acción y te muestra en grande qué tecla tienes asignada a cada poder o poción (`1`, `F`, `Shift-R`, botón del ratón, etc.). Además, también **puedes hacer clic directo** sobre los iconos de PanicAura para lanzarlos.
* **Cambiar poderes arrastrando:** Puedes arrastrar cualquier hechizo, poción, piedra de salud o macro directamente desde tu libro de hechizos o mochila hacia la barra o hacia la ventana de opciones.

---

### 5. 📜 Historial de Muertes
En la pestaña **Die & Rise** del menú de opciones queda guardado un registro de las muertes de tu personaje: **fecha, hora, nivel, zona, qué enemigo y habilidad te dio el golpe final**, y a qué estado pasaste (*Vivo → Putrefacto* o *Putrefacto → Esquelético*).

---

## 📦 Cómo instalarlo

1. Descarga la carpeta **`PanicAura`**.
2. Cópiala dentro de la carpeta de addons de tu juego:
   `C:\TuWoW\TuWoW-Client\Interface\AddOns\PanicAura`
3. Asegúrate de que adentro estén directamente los archivos `PanicAura.toc`, `PanicAura.lua` y `PanicConfig.lua`.
4. Entra al juego (o escribe `/reload` en el chat si ya estabas adentro).

---

## 🎮 Cómo usarlo y configurarlo

Tienes un **botón en el borde del Minimapa** (y también comandos en el chat):

* **Clic Izquierdo en el icono del minimapa** (o escribir **`/pa`** en el chat): Abre el **Panel de Opciones** dividido en 4 pestañas (*General*, *Alertas*, *Die & Rise* y *Ranuras*).
* **Clic Derecho en el icono del minimapa:** Activa o desactiva el **Modo Prueba** para ver cómo lucen las alertas en tu pantalla.
* **Shift + Clic Derecho en el icono del minimapa:** Abre solo los iconos de la barra (sin sonidos ni destellos) para que puedas arrastrar poderes o pociones tranquilamente.
* **Botón "Mover barra"** (abajo en el panel `/pa`): Desbloquea la barra de iconos y el indicador de *Die & Rise* para que los arrastres con el ratón a la parte de la pantalla que te quede más cómoda.

### Comandos útiles para probar todo sin peligro:
* `/pa` o `/panicaura` — Abre la ventana de configuración.
* `/pa test1` / `/pa test2` / `/pa test` — Prueba la alerta Amarilla, Naranja o Roja.
* `/pa dr1` — Simula cómo se ve el indicador cuando estás en estado **Putrefacto**.
* `/pa dr2` — Simula cómo se ve el indicador cuando estás en estado **Esquelético** (con contador de almas y pociones bloqueadas con `X`).
* `/pa corp` — Simula el reloj de **36 segundos de Corporeidad** tras sacrificar un alma.
* `/pa dr0` — Vuelve el indicador a estado **Normal (Vivo)**.

