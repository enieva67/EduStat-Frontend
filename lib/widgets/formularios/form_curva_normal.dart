import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';

class FormCurvaNormal extends StatefulWidget {
  const FormCurvaNormal({super.key});

  @override
  State<FormCurvaNormal> createState() => _FormCurvaNormalState();
}

class _FormCurvaNormalState extends State<FormCurvaNormal> {
  final wsService = WebSocketService();

  // 1. ESTADOS Y CONTROLADORES (Aislados solo para este formulario)
  bool _tengoPuntajeX = true;
  String _tipoAreaZ = 'menor';
  
  final TextEditingController _zMediaCtrl = TextEditingController(text: "100");
  final TextEditingController _zDesviacionCtrl = TextEditingController(text: "15");
  final TextEditingController _zPacienteCtrl = TextEditingController(text: "118");
  final TextEditingController _zPaciente2Ctrl = TextEditingController(text: "130");
  final TextEditingController _zArea1Ctrl = TextEditingController(text: "95");
  final TextEditingController _zArea2Ctrl = TextEditingController(text: "99");

  @override
  void dispose() {
    // Se limpian automáticamente cuando el usuario cambia a otro módulo en el menú
    _zMediaCtrl.dispose();
    _zDesviacionCtrl.dispose();
    _zPacienteCtrl.dispose();
    _zPaciente2Ctrl.dispose();
    _zArea1Ctrl.dispose();
    _zArea2Ctrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, backgroundColor: Colors.teal.shade800)
    );
  }

  // 2. FUNCIÓN DE ENVÍO
  void _enviarPuntajeZ() {
    double? media = double.tryParse(_zMediaCtrl.text.replaceAll(',', '.'));
    double? desviacion = double.tryParse(_zDesviacionCtrl.text.replaceAll(',', '.'));
    if (media == null || desviacion == null) return;

    if (_tengoPuntajeX) {
      double? xVal = double.tryParse(_zPacienteCtrl.text.replaceAll(',', '.'));
      double? x2Val = _tipoAreaZ == 'entre_dos_valores' ? double.tryParse(_zPaciente2Ctrl.text.replaceAll(',', '.')) : null;

      if (xVal == null) { _mostrarMensaje("❌ Ingresa un Puntaje X válido."); return; }

      wsService.sendJson({
        "id": "calculo_01", "accion": "calcular_puntaje_z",
        "parametros": { "media": media, "desviacion": desviacion, "x": xVal, "tipo_area": _tipoAreaZ, "x2": x2Val }
      });
    } else {
      double? area1 = double.tryParse(_zArea1Ctrl.text.replaceAll(',', '.'));
      double? area2 = _tipoAreaZ == 'entre_dos_valores' ? double.tryParse(_zArea2Ctrl.text.replaceAll(',', '.')) : null;

      if (area1 == null) { _mostrarMensaje("❌ Ingresa un Área válida (Ej: 95)."); return; }

      wsService.sendJson({
        "id": "calculo_01", "accion": "calcular_x_desde_area",
        "parametros": { "media": media, "desviacion": desviacion, "area1": area1, "tipo_area": _tipoAreaZ, "area2": area2 }
      });
    }
  }

  // 3. INTERFAZ DE USUARIO AISLADA
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("Datos de la Población y el Paciente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        
        Row(
          children:[
            const Text("¿Qué dato tienes?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(width: 15),
            Switch(
              value: _tengoPuntajeX, activeThumbColor: Colors.teal, inactiveThumbColor: Colors.amber, inactiveTrackColor: Colors.amber.withValues(alpha: 0.3),
              onChanged: (val) => setState(() => _tengoPuntajeX = val),
            ),
            Text(_tengoPuntajeX ? "Tengo el Puntaje (X)" : "Tengo el Área (%)", style: TextStyle(color: _tengoPuntajeX ? Colors.teal : Colors.amber.shade800, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        
        TextField(controller: _zMediaCtrl, decoration: const InputDecoration(labelText: "Media Poblacional (μ)", prefixIcon: Icon(Icons.balance), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 10),
        TextField(controller: _zDesviacionCtrl, decoration: const InputDecoration(labelText: "Desviación Estándar (σ)", prefixIcon: Icon(Icons.compare_arrows), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true, value: _tipoAreaZ,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
              items: _tengoPuntajeX 
                ? const[
                    DropdownMenuItem(value: 'menor', child: Text("Calcular: Área a la Izquierda de X")),
                    DropdownMenuItem(value: 'mayor', child: Text("Calcular: Área a la Derecha de X")),
                    DropdownMenuItem(value: 'entre_media', child: Text("Calcular: Área entre la Media y X")),
                    DropdownMenuItem(value: 'dos_colas', child: Text("Calcular: Área en los Extremos (±X)")),
                    DropdownMenuItem(value: 'entre_dos_valores', child: Text("Calcular: Área entre X₁ y X₂")),
                  ]
                : const[
                    DropdownMenuItem(value: 'menor', child: Text("Buscar Puntaje (X): Que deja el Área a la Izquierda")),
                    DropdownMenuItem(value: 'mayor', child: Text("Buscar Puntaje (X): Que deja el Área a la Derecha")),
                    DropdownMenuItem(value: 'entre_media', child: Text("Buscar Puntaje (X): Con un Área desde el Centro")),
                    DropdownMenuItem(value: 'dos_colas', child: Text("Buscar Puntajes (±X): Que delimitan las Colas")),
                    DropdownMenuItem(value: 'entre_dos_valores', child: Text("Buscar Puntajes (X₁ y X₂): Dados dos percentiles")),
                  ],
              onChanged: (val) { if (val != null) setState(() => _tipoAreaZ = val); },
            ),
          ),
        ),
        const SizedBox(height: 15),

        if (_tengoPuntajeX) ...[
          TextField(controller: _zPacienteCtrl, decoration: const InputDecoration(labelText: "Puntaje (X1)", prefixIcon: Icon(Icons.person), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.tealAccent)),
          if (_tipoAreaZ == 'entre_dos_valores') ...[
            const SizedBox(height: 10),
            TextField(controller: _zPaciente2Ctrl, decoration: const InputDecoration(labelText: "Segundo Puntaje (X2)", prefixIcon: Icon(Icons.person_add), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.tealAccent)),
          ]
        ] else ...[
          TextField(controller: _zArea1Ctrl, decoration: const InputDecoration(labelText: "Área o Probabilidad (Ej: 95 o 0.95)", prefixIcon: Icon(Icons.pie_chart), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.amberAccent)),
          if (_tipoAreaZ == 'entre_dos_valores') ...[
            const SizedBox(height: 10),
            TextField(controller: _zArea2Ctrl, decoration: const InputDecoration(labelText: "Segunda Área (Ej: 99)", prefixIcon: Icon(Icons.pie_chart_outline), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.amberAccent)),
          ]
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_graph),
            label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Dibujar Campana de Gauss", style: TextStyle(fontSize: 16))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 3),
            onPressed: _enviarPuntajeZ,
          ),
        )
      ],
    );
  }
}
