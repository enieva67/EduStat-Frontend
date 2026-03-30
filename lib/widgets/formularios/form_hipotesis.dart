import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';

class FormHipotesis extends StatefulWidget {
  const FormHipotesis({super.key});

  @override
  State<FormHipotesis> createState() => _FormHipotesisState();
}

class _FormHipotesisState extends State<FormHipotesis> {
  final wsService = WebSocketService();

  // CONTROLADORES AISLADOS
  final TextEditingController _phMuCtrl = TextEditingController(text: "100");
  final TextEditingController _phXBarraCtrl = TextEditingController(text: "108");
  final TextEditingController _phDesvCtrl = TextEditingController(text: "15");
  final TextEditingController _phNCtrl = TextEditingController(text: "30");
  final TextEditingController _phAlfaCtrl = TextEditingController(text: "0.05");
  String _phTipoPrueba = 'dos_colas';

  @override
  void dispose() {
    _phMuCtrl.dispose();
    _phXBarraCtrl.dispose();
    _phDesvCtrl.dispose();
    _phNCtrl.dispose();
    _phAlfaCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, backgroundColor: Colors.redAccent.shade700)
    );
  }

  void _enviarPruebaHipotesis() {
    double? mu = double.tryParse(_phMuCtrl.text.replaceAll(',', '.'));
    double? xBarra = double.tryParse(_phXBarraCtrl.text.replaceAll(',', '.'));
    double? desv = double.tryParse(_phDesvCtrl.text.replaceAll(',', '.'));
    int? n = int.tryParse(_phNCtrl.text);
    double? alfa = double.tryParse(_phAlfaCtrl.text.replaceAll(',', '.'));

    if (mu == null || xBarra == null || desv == null || n == null || alfa == null) {
      _mostrarMensaje("❌ Error: Ingresa números válidos en todos los campos.");
      return;
    }

    final payload = {
      "id": "calculo_01",
      "accion": "calcular_prueba_hipotesis",
      "parametros": {
        "mu_pob": mu, "x_barra": xBarra, "desviacion": desv,
        "n": n, "alfa": alfa, "tipo_prueba": _phTipoPrueba
      }
    };
    wsService.sendJson(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("Prueba de Hipótesis (Z o T)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 15),
        
        TextField(controller: _phMuCtrl, decoration: const InputDecoration(labelText: "Hipótesis Nula (μ esperado)", prefixIcon: Icon(Icons.balance), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 10),
        TextField(controller: _phXBarraCtrl, decoration: const InputDecoration(labelText: "Media de la Muestra (x̄)", prefixIcon: Icon(Icons.person), border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.tealAccent)),
        const SizedBox(height: 10),
        TextField(controller: _phDesvCtrl, decoration: const InputDecoration(labelText: "Desviación Estándar (s o σ)", prefixIcon: Icon(Icons.compare_arrows), border: OutlineInputBorder(), isDense: true)),
        const SizedBox(height: 10),
        Row(
          children:[
            Expanded(child: TextField(controller: _phNCtrl, decoration: const InputDecoration(labelText: "Muestra (n)", prefixIcon: Icon(Icons.group), border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _phAlfaCtrl, decoration: const InputDecoration(labelText: "Alfa (α)", prefixIcon: Icon(Icons.warning), border: OutlineInputBorder(), isDense: true))),
          ],
        ),
        const SizedBox(height: 15),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.redAccent.shade100), borderRadius: BorderRadius.circular(4)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true, value: _phTipoPrueba,
              icon: const Icon(Icons.alt_route, color: Colors.redAccent),
              items: const[
                DropdownMenuItem(value: 'dos_colas', child: Text("Test a Dos Colas (Diferente: ≠)")),
                DropdownMenuItem(value: 'cola_der', child: Text("Test Cola Derecha (Mayor: >)")),
                DropdownMenuItem(value: 'cola_izq', child: Text("Test Cola Izquierda (Menor: <)")),
              ],
              onChanged: (val) { if (val != null) setState(() => _phTipoPrueba = val); },
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.gavel),
            label: const Padding(padding: EdgeInsets.all(12.0), child: Text("Evaluar Hipótesis", style: TextStyle(fontSize: 16))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700, foregroundColor: Colors.white, elevation: 3),
            onPressed: _enviarPruebaHipotesis,
          ),
        )
      ],
    );
  }
}
