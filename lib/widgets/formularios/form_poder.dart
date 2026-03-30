import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';

class FormPoder extends StatefulWidget {
  const FormPoder({super.key});

  @override
  State<FormPoder> createState() => _FormPoderState();
}

class _FormPoderState extends State<FormPoder> {
  final wsService = WebSocketService();

  // CONTROLADORES AISLADOS
  bool _calcularN = true;
  bool _tengoDCohen = true; 
  
  final TextEditingController _poderCohenCtrl = TextEditingController(text: "0.5");
  final TextEditingController _poderMu0Ctrl = TextEditingController(text: "100");
  final TextEditingController _poderMu1Ctrl = TextEditingController(text: "130");
  final TextEditingController _poderSigmaCtrl = TextEditingController(text: "9"); 
  final TextEditingController _poderAlfaCtrl = TextEditingController(text: "0.05");
  final TextEditingController _poderNCtrl = TextEditingController(text: "64");
  final TextEditingController _poder1MinusBetaCtrl = TextEditingController(text: "0.80");

  @override
  void dispose() {
    _poderCohenCtrl.dispose();
    _poderMu0Ctrl.dispose();
    _poderMu1Ctrl.dispose();
    _poderSigmaCtrl.dispose();
    _poderAlfaCtrl.dispose();
    _poderNCtrl.dispose();
    _poder1MinusBetaCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green.shade800)
    );
  }

  void _enviarPoderMuestra() {
    double? alfa = double.tryParse(_poderAlfaCtrl.text.replaceAll(',', '.'));
    if (alfa == null) { _mostrarMensaje("❌ Error: Verifica el valor de Alfa."); return; }

    final parametros = {
      "tipo_calculo": _calcularN ? "calcular_n" : "calcular_poder",
      "tipo_ingreso": _tengoDCohen ? "d_cohen" : "medias_reales",
      "alfa": alfa,
    };

    if (_tengoDCohen) {
      double? dCohen = double.tryParse(_poderCohenCtrl.text.replaceAll(',', '.'));
      if (dCohen == null) { _mostrarMensaje("❌ Error: Verifica el Tamaño del Efecto (d)."); return; }
      parametros["d_cohen"] = dCohen;
    } else {
      double? mu0 = double.tryParse(_poderMu0Ctrl.text.replaceAll(',', '.'));
      double? mu1 = double.tryParse(_poderMu1Ctrl.text.replaceAll(',', '.'));
      double? sigma = double.tryParse(_poderSigmaCtrl.text.replaceAll(',', '.'));
      if (mu0 == null || mu1 == null || sigma == null) {
        _mostrarMensaje("❌ Error: Verifica los datos de las Medias Reales y la Desviación."); return;
      }
      parametros["mu0"] = mu0;
      parametros["mu1"] = mu1;
      parametros["sigma"] = sigma;
    }

    if (_calcularN) {
      double? poder = double.tryParse(_poder1MinusBetaCtrl.text.replaceAll(',', '.'));
      if (poder == null) { _mostrarMensaje("❌ Error: Ingresa el Poder deseado."); return; }
      parametros["poder"] = poder;
    } else {
      double? n = double.tryParse(_poderNCtrl.text.replaceAll(',', '.'));
      if (n == null) { _mostrarMensaje("❌ Error: Ingresa el Tamaño de Muestra."); return; }
      parametros["n"] = n;
    }

    wsService.sendJson({
      "id": "calculo_01", "accion": "calcular_poder_muestra", "parametros": parametros
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("Análisis de Poder (1 - β)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 15),
        
        Row(
          children:[
            const Text("¿Qué deseas calcular?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            Switch(
              value: _calcularN, activeThumbColor: Colors.teal, inactiveThumbColor: Colors.green,
              onChanged: (val) => setState(() => _calcularN = val),
            ),
            Text(_calcularN ? "Tamaño de Muestra (n)" : "Poder del Test (1-β)", style: TextStyle(color: _calcularN ? Colors.teal : Colors.green.shade800, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),

        Row(
          children:[
            const Text("Origen del Efecto:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            Switch(
              value: _tengoDCohen, activeThumbColor: Colors.teal, inactiveThumbColor: Colors.green,
              onChanged: (val) => setState(() => _tengoDCohen = val),
            ),
            Text(_tengoDCohen ? "Tamaño de Efecto (d)" : "Medias Reales (μ₀ y μ₁)", style: TextStyle(color: _tengoDCohen ? Colors.teal : Colors.green.shade800, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),

        if (_tengoDCohen) ...[
          TextField(controller: _poderCohenCtrl, decoration: const InputDecoration(labelText: "Tamaño del Efecto (d de Cohen, ej: 0.5)", prefixIcon: Icon(Icons.open_with), border: OutlineInputBorder(), isDense: true)),
        ] else ...[
          Row(
            children:[
              Expanded(child: TextField(controller: _poderMu0Ctrl, decoration: const InputDecoration(labelText: "Media Nula (μ₀)", prefixIcon: Icon(Icons.balance), border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _poderMu1Ctrl, decoration: const InputDecoration(labelText: "Media Alternativa (μ₁)", prefixIcon: Icon(Icons.flag), border: OutlineInputBorder(), isDense: true))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(controller: _poderSigmaCtrl, decoration: const InputDecoration(labelText: "Desviación Estándar (σ)", prefixIcon: Icon(Icons.compare_arrows), border: OutlineInputBorder(), isDense: true)),
        ],
        
        const SizedBox(height: 10),
        TextField(controller: _poderAlfaCtrl, decoration: const InputDecoration(labelText: "Riesgo de Falso Positivo (Alfa α)", prefixIcon: Icon(Icons.warning_amber), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 10),

        if (_calcularN)
          TextField(controller: _poder1MinusBetaCtrl, decoration: const InputDecoration(labelText: "Poder Deseado (1-β, ej: 0.80)", prefixIcon: Icon(Icons.battery_std), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.greenAccent))
        else
          TextField(controller: _poderNCtrl, decoration: const InputDecoration(labelText: "Tamaño de Muestra Actual (n)", prefixIcon: Icon(Icons.group), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.tealAccent)),
          
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.model_training),
            label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Simular Poder Estadístico", style: TextStyle(fontSize: 16))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, elevation: 3),
            onPressed: _enviarPoderMuestra,
          ),
        )
      ],
    );
  }
}
