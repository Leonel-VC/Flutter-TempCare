import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TempCareApp());
}

class TempCareApp extends StatelessWidget {
  const TempCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const TempCareScreen(),
    );
  }
}

class TempCareScreen extends StatefulWidget {
  const TempCareScreen({super.key});
  @override
  State<TempCareScreen> createState() => _TempCareScreenState();
}

  // Controladores para los nuevos inputs numéricos
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _baselineController = TextEditingController(text: '36.6');

  // Datos de sensores y lógica
  double measuredTemp = 0.0; 
  bool _isBluetoothConnected = false;
  String activity = 'Reposo';
  double deltaT = 0.0;
  String recommendation = "Esperando análisis...";
  Color resultColor = const Color(0xFF1A6B8A);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TempCare", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A6B8A))),
                      Text("Configuración y Análisis", style: TextStyle(color: Color(0xFF5A9BB5))),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                      color: _isBluetoothConnected ? const Color(0xFF00BFA5) : const Color(0xFF1A6B8A),
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // BOX SUPERIOR: INPUTS DE USUARIO (Edad y Basal)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A6B8A), Color(0xFF2A8BAA)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DATOS DEL USUARIO", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkInput(controller: _ageController, label: "Edad", hint: "Ej. 25"),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildDarkInput(controller: _baselineController, label: "Basal (°C)", hint: "36.6"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // BOX ACTIVIDAD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: activity,
                      items: ['Reposo', 'Actividad Ligera', 'Actividad Moderada', 'Actividad Intensa'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) => setState(() => activity = val!),
                      decoration: const InputDecoration(labelText: 'Nivel de Actividad', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: analyze,
                        child: const Text("ANALIZAR AHORA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SECCIÓN: TEMPERATURA EN TIEMPO REAL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFB8D8E8))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Lectura Bluetooth:", style: TextStyle(color: Color(0xFF1A6B8A), fontWeight: FontWeight.w500)),
                    Text(
                      _isBluetoothConnected ? "${measuredTemp.toStringAsFixed(1)} °C" : "Desconectado",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isBluetoothConnected ? Colors.black87 : Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // BOX DE RESULTADOS (DELTA T)
              if (deltaT != 0.0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: resultColor, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      Text("ΔT: ${deltaT.toStringAsFixed(2)}°C", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(recommendation, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para los inputs claros sobre fondo oscuro
  Widget _buildDarkInput({required TextEditingController controller, required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}