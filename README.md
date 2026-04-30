# TempCare
Es una app móvil de salud orientada al monitoreo y análisis inteligente de la temperatura corporal, donde a través de la conexión bluetooth con una ESP32 y con un sensor de temperatura infrarrojo MLX90614, la aplicación proporciona retroalimentación en tiempo real y calcula la variación térmica (Delta T) del usuario basándose en su edad, temperatura basal y nivel de actividad física.

---

## Descripción del proyecto

El objetivo de TempCare es ofrecer una lectura de temperatura que vaya más allá del simple número. Muchas veces, factores como la actividad física previa o la temperatura corporal "normal" (basal) de una persona alteran la interpretación de una lectura de termómetro. Esta app toma las lecturas de un dispositivo externo, las ajusta según el contexto del paciente y devuelve una evaluación mediante una interfaz intuitiva.

---

## Arquitectura y funcionamiento

El sistema se compone de dos partes principales: el hardware de adquisición de datos y la app móvil.

### 1. Hardware y microprocesador
* **Microprocesador:** Utilizamos un **ESP32**, elegido por su versatilidad y capacidad de comunicación inalámbrica integrada.
* **Sensor:** Sensor de temperatura infrarrojo **MLX90614** (conectado vía protocolo I2C / `0x5C`), el cual lee la temperatura del objeto (paciente).
* **Procesamiento de hardware:** El ESP32 lee la temperatura del sensor MLX90614, mapea los valores a un rango de 8 bits (0-255) para optimizar el envío de datos, y los transmite continuamente.

### 2. Medio de transmisión
* **Tecnología:** La transmisión de la variable fisiológica al teléfono se realiza mediante **Bluetooth Low Energy (BLE)**.
* **Detalles técnicos:** El ESP32 actúa como servidor BLE publicando bajo el Service UUID `4fafc201-1fb5-459e-8fcc-c5c9c331914b`. La aplicación en Flutter se conecta a este servicio, se suscribe a la característica correspondiente y recibe notificaciones en tiempo real con los valores de temperatura.

### 3. Variables que recibe y procesa la app
* **Vía Bluetooth (BLE):**
  * `measuredTemp`: Temperatura actual del paciente capturada por el sensor. Se recibe un valor de 8 bits que la app decodifica de vuelta a grados Celsius mediante la fórmula `(valor * 20 / 255) + 20`.
* **Ingresadas por el usuario:**
  * `Edad`: Rango de edad del paciente (Infante, Niño, Adulto, Adulto Mayor) para contextualizar la severidad.
  * `Temperatura Basal`: La temperatura normal del cuerpo en reposo del usuario (por defecto 36.6 °C).
  * `Nivel de Actividad`: Estado físico antes de la toma (Reposo, Ligera, Moderada, Intensa).

---

## Lógica de cálculo médico (Delta T)

La aplicación no solo muestra la temperatura bruta, sino que realiza un análisis para evitar falsos positivos (por ejemplo, tener una temperatura ligeramente elevada solo por haber hecho ejercicio).

1. **Corrección por Actividad:** Se resta un valor a la temperatura medida dependiendo del esfuerzo físico previo.
   * Reposo: `-0.0 °C`
   * Actividad Ligera: `-0.3 °C`
   * Actividad Moderada: `-0.5 °C`
   * Actividad Intensa: `-0.7 °C`
2. **Cálculo de ΔT (Delta T):** * `ΔT = (Temperatura Medida - Corrección por Actividad) - Temperatura Basal`
3. **Diagnóstico y Severidad:** Con base en el valor de ΔT, la aplicación clasifica el estado de salud y muestra un banner de color con una recomendación:
   * **< -0.5 °C:** Posible hipotermia.
   * **-0.5 °C a 0.5 °C:** Rango normal.
   * **> 0.5 °C:** Grados de fiebre (Leve, moderada, alta, severa) ajustados por la matriz de edad.

---

## Tecnologías utilizadas

* **Frontend Móvil:** Flutter SDK (Dart)
  * Paquetes clave: `flutter_blue_plus` (para BLE), `permission_handler` (para gestión de permisos de hardware).
* **Firmware:** Arduino IDE / C++ (Para ESP32)
  * Librerías: `BLEDevice`, `Adafruit_MLX90614`, `Wire`.

## Uso de la app

1. Enciende el dispositivo ESP32.
2. Abre la app **TempCare**.
3. Ingresa tus datos en la sección superior (Edad y Basal).
4. Selecciona tu nivel de actividad física actual.
5. Toca el ícono de Bluetooth en la esquina superior derecha para escanear y conectar el hardware ("RGB LED Controller" / Sensor de temperatura).
6. Observa tu temperatura real decodificada en pantalla.
7. Presiona **ANALIZAR AHORA** para obtener el cálculo de tu Delta T y tu estado de salud actual.
